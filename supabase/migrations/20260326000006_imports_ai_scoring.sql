-- =============================================================================
-- Import jobs & sources
-- =============================================================================

CREATE TABLE public.import_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source public.import_source NOT NULL UNIQUE,
  name TEXT NOT NULL,
  config JSONB NOT NULL DEFAULT '{}'::JSONB,
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.import_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source public.import_source NOT NULL,
  status public.import_job_status NOT NULL DEFAULT 'pending',
  polygon JSONB,
  trail_count INTEGER NOT NULL DEFAULT 0,
  asset_count INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  started_by UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX idx_import_jobs_source ON public.import_jobs (source);
CREATE INDEX idx_import_jobs_status ON public.import_jobs (status);

-- =============================================================================
-- AI / embeddings
-- =============================================================================

CREATE TABLE public.issue_embeddings (
  issue_id UUID PRIMARY KEY REFERENCES public.issues (id) ON DELETE CASCADE,
  embedding vector (1536) NOT NULL,
  model TEXT NOT NULL DEFAULT 'text-embedding-3-small',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_issue_embeddings_vector
ON public.issue_embeddings
USING hnsw (embedding vector_cosine_ops);

CREATE TABLE public.duplicate_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID NOT NULL REFERENCES public.issues (id) ON DELETE CASCADE,
  suggested_duplicate_id UUID NOT NULL REFERENCES public.issues (id) ON DELETE CASCADE,
  similarity_score NUMERIC(5, 4) NOT NULL CHECK (similarity_score >= 0 AND similarity_score <= 1),
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (issue_id, suggested_duplicate_id),
  CHECK (issue_id <> suggested_duplicate_id)
);

CREATE INDEX idx_duplicate_suggestions_issue_id ON public.duplicate_suggestions (issue_id);

-- =============================================================================
-- Trail maintenance scoring
-- =============================================================================

CREATE OR REPLACE FUNCTION public.compute_trail_maintenance_score(p_trail_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_score NUMERIC := 100;
  v_open_count INTEGER := 0;
  v_closed_count INTEGER := 0;
  rec RECORD;
  v_priority_weight NUMERIC;
  v_age_days NUMERIC;
  v_age_factor NUMERIC;
BEGIN
  FOR rec IN
    SELECT
      priority,
      status,
      created_at
    FROM public.issues
    WHERE trail_id = p_trail_id
  LOOP
    IF rec.status = 'closed' THEN
      v_closed_count := v_closed_count + 1;
      CONTINUE;
    END IF;

    v_open_count := v_open_count + 1;

    v_priority_weight := CASE rec.priority
      WHEN 'critical' THEN 18
      WHEN 'high' THEN 12
      WHEN 'medium' THEN 7
      WHEN 'low' THEN 3
      ELSE 5
    END;

    v_age_days := GREATEST(0, EXTRACT(EPOCH FROM (NOW() - rec.created_at)) / 86400.0);
    v_age_factor := LEAST(2.0, 1.0 + (v_age_days / 30.0));

    v_score := v_score - (v_priority_weight * v_age_factor);
  END LOOP;

  v_score := GREATEST(0, LEAST(100, ROUND(v_score, 2)));

  UPDATE public.trails
  SET
    maintenance_score = v_score,
    open_issue_count = v_open_count,
    closed_issue_count = v_closed_count,
    updated_at = NOW()
  WHERE id = p_trail_id;

  RETURN v_score;
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_trail_maintenance_on_issue_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trail_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_trail_id := OLD.trail_id;
  ELSE
    v_trail_id := NEW.trail_id;
  END IF;

  IF v_trail_id IS NOT NULL THEN
    PERFORM public.compute_trail_maintenance_score(v_trail_id);
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.trail_id IS DISTINCT FROM NEW.trail_id AND OLD.trail_id IS NOT NULL THEN
    PERFORM public.compute_trail_maintenance_score(OLD.trail_id);
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER issues_refresh_trail_maintenance
AFTER INSERT OR UPDATE OR DELETE ON public.issues
FOR EACH ROW
EXECUTE FUNCTION public.refresh_trail_maintenance_on_issue_change();

CREATE TRIGGER issue_embeddings_set_updated_at
BEFORE UPDATE ON public.issue_embeddings
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- Row Level Security
-- =============================================================================

ALTER TABLE public.import_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.import_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duplicate_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Import sources are readable"
ON public.import_sources
FOR SELECT
USING (TRUE);

CREATE POLICY "Admins manage import sources"
ON public.import_sources
FOR ALL
USING (public.is_admin_or_land_manager())
WITH CHECK (public.is_admin_or_land_manager());

CREATE POLICY "Import jobs readable by admins and starters"
ON public.import_jobs
FOR SELECT
USING (public.is_admin_or_land_manager() OR started_by = auth.uid());

CREATE POLICY "Managers can create import jobs"
ON public.import_jobs
FOR INSERT
TO authenticated
WITH CHECK (public.is_admin_or_land_manager() OR auth.uid() = started_by);

CREATE POLICY "Issue embeddings follow issue visibility"
ON public.issue_embeddings
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.issues i
    WHERE i.id = issue_id
      AND (i.status <> 'closed' OR auth.uid() IS NOT NULL)
  )
);

CREATE POLICY "Duplicate suggestions follow issue visibility"
ON public.duplicate_suggestions
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.issues i
    WHERE i.id = issue_id
      AND (i.status <> 'closed' OR auth.uid() IS NOT NULL)
  )
);

CREATE POLICY "Managers can manage duplicate suggestions"
ON public.duplicate_suggestions
FOR ALL
USING (public.is_admin_or_land_manager())
WITH CHECK (public.is_admin_or_land_manager());

-- =============================================================================
-- Helper RPCs for edge functions
-- =============================================================================

CREATE OR REPLACE FUNCTION public.insert_trail_from_wkt(
  p_name TEXT,
  p_agency TEXT DEFAULT NULL,
  p_length_miles NUMERIC DEFAULT NULL,
  p_surface TEXT DEFAULT NULL,
  p_trail_number TEXT DEFAULT NULL,
  p_source public.import_source DEFAULT NULL,
  p_geom_wkt TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.trails (
    name, agency, length_miles, surface, trail_number, source, geom
  )
  VALUES (
    p_name,
    p_agency,
    p_length_miles,
    p_surface,
    p_trail_number,
    p_source,
    CASE
      WHEN p_geom_wkt IS NULL THEN NULL
      ELSE ST_GeogFromText('SRID=4326;' || p_geom_wkt)
    END
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.find_nearby_issues(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 200,
  p_exclude_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  issue_number INTEGER,
  title TEXT,
  type public.issue_type,
  status public.issue_status,
  distance_m DOUBLE PRECISION
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    i.id,
    i.issue_number,
    i.title,
    i.type,
    i.status,
    ST_Distance(
      i.geom,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    ) AS distance_m
  FROM public.issues i
  WHERE i.geom IS NOT NULL
    AND i.status <> 'closed'
    AND (p_exclude_id IS NULL OR i.id <> p_exclude_id)
    AND ST_DWithin(
      i.geom,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_m
    )
  ORDER BY distance_m
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.insert_trail_from_wkt TO service_role;
GRANT EXECUTE ON FUNCTION public.find_nearby_issues TO service_role, anon, authenticated;

CREATE OR REPLACE FUNCTION public.issue_location(p_issue_id UUID)
RETURNS TABLE (lat DOUBLE PRECISION, lng DOUBLE PRECISION)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ST_Y(i.geom::geometry) AS lat,
    ST_X(i.geom::geometry) AS lng
  FROM public.issues i
  WHERE i.id = p_issue_id
    AND i.geom IS NOT NULL;
$$;

GRANT EXECUTE ON FUNCTION public.issue_location TO service_role, anon, authenticated;


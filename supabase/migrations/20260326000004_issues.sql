-- =============================================================================
-- Issues
-- =============================================================================

CREATE SEQUENCE public.issue_number_seq START WITH 1000;

CREATE TABLE public.issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_number INTEGER NOT NULL DEFAULT nextval('public.issue_number_seq'),
  type public.issue_type NOT NULL DEFAULT 'other',
  priority public.issue_priority NOT NULL DEFAULT 'medium',
  status public.issue_status NOT NULL DEFAULT 'open',
  title TEXT NOT NULL,
  description TEXT,
  trail_id UUID REFERENCES public.trails (id) ON DELETE SET NULL,
  asset_id UUID REFERENCES public.assets (id) ON DELETE SET NULL,
  geom geography (Point, 4326),
  estimated_hours NUMERIC(6, 2),
  estimated_crew_size INTEGER,
  estimated_duration_label TEXT,
  reported_by UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  crew_id UUID,
  agency TEXT,
  safety_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (issue_number)
);

CREATE TABLE public.issue_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID NOT NULL REFERENCES public.issues (id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  url TEXT,
  caption TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  uploaded_by UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.issue_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID NOT NULL REFERENCES public.issues (id) ON DELETE CASCADE,
  author_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.issue_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID NOT NULL REFERENCES public.issues (id) ON DELETE CASCADE,
  actor_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  summary TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.issue_tools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID NOT NULL REFERENCES public.issues (id) ON DELETE CASCADE,
  tool TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (issue_id, tool)
);

CREATE TABLE public.issue_certifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID NOT NULL REFERENCES public.issues (id) ON DELETE CASCADE,
  certification TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (issue_id, certification)
);

CREATE TABLE public.favorites (
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  issue_id UUID NOT NULL REFERENCES public.issues (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, issue_id)
);

CREATE INDEX idx_issues_geom ON public.issues USING GIST (geom);
CREATE INDEX idx_issues_trail_id ON public.issues (trail_id);
CREATE INDEX idx_issues_status ON public.issues (status);
CREATE INDEX idx_issues_priority ON public.issues (priority);
CREATE INDEX idx_issue_photos_issue_id ON public.issue_photos (issue_id);
CREATE INDEX idx_issue_comments_issue_id ON public.issue_comments (issue_id);
CREATE INDEX idx_issue_history_issue_id ON public.issue_history (issue_id);
CREATE INDEX idx_favorites_user_id ON public.favorites (user_id);

CREATE TRIGGER issues_set_updated_at
BEFORE UPDATE ON public.issues
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER issue_comments_set_updated_at
BEFORE UPDATE ON public.issue_comments
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- RLS helpers
-- =============================================================================

CREATE OR REPLACE FUNCTION public.can_update_issue(p_issue_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.issues i
    WHERE i.id = p_issue_id
      AND (
        public.is_admin_or_land_manager()
        OR i.reported_by = auth.uid()
        OR i.assigned_to = auth.uid()
        OR public.has_role('crew_leader')
        OR (i.trail_id IS NOT NULL AND public.can_manage_trail(i.trail_id))
      )
  );
$$;

-- =============================================================================
-- Row Level Security
-- =============================================================================

ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_tools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Open issues are publicly readable"
ON public.issues
FOR SELECT
USING (status <> 'closed' OR auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can create issues"
ON public.issues
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authorized users can update issues"
ON public.issues
FOR UPDATE
USING (public.can_update_issue(id))
WITH CHECK (public.can_update_issue(id));

CREATE POLICY "Issue photos follow issue visibility"
ON public.issue_photos
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.issues i
    WHERE i.id = issue_id
      AND (i.status <> 'closed' OR auth.uid() IS NOT NULL)
  )
);

CREATE POLICY "Authenticated users can add issue photos"
ON public.issue_photos
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Issue comments follow issue visibility"
ON public.issue_comments
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.issues i
    WHERE i.id = issue_id
      AND (i.status <> 'closed' OR auth.uid() IS NOT NULL)
  )
);

CREATE POLICY "Authenticated users can comment"
ON public.issue_comments
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = author_id OR author_id IS NULL);

CREATE POLICY "Issue history follows issue visibility"
ON public.issue_history
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.issues i
    WHERE i.id = issue_id
      AND (i.status <> 'closed' OR auth.uid() IS NOT NULL)
  )
);

CREATE POLICY "Authorized users can write issue history"
ON public.issue_history
FOR INSERT
TO authenticated
WITH CHECK (public.can_update_issue(issue_id));

CREATE POLICY "Issue tools follow issue visibility"
ON public.issue_tools
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.issues i
    WHERE i.id = issue_id
      AND (i.status <> 'closed' OR auth.uid() IS NOT NULL)
  )
);

CREATE POLICY "Authorized users can manage issue tools"
ON public.issue_tools
FOR ALL
TO authenticated
USING (public.can_update_issue(issue_id))
WITH CHECK (public.can_update_issue(issue_id));

CREATE POLICY "Issue certifications follow issue visibility"
ON public.issue_certifications
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.issues i
    WHERE i.id = issue_id
      AND (i.status <> 'closed' OR auth.uid() IS NOT NULL)
  )
);

CREATE POLICY "Authorized users can manage issue certifications"
ON public.issue_certifications
FOR ALL
TO authenticated
USING (public.can_update_issue(issue_id))
WITH CHECK (public.can_update_issue(issue_id));

CREATE POLICY "Users manage own favorites"
ON public.favorites
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

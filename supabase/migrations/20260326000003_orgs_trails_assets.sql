-- =============================================================================
-- Organizations
-- =============================================================================

CREATE TABLE public.organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  website TEXT,
  approved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.organization_members (
  organization_id UUID NOT NULL REFERENCES public.organizations (id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (organization_id, user_id)
);

CREATE TABLE public.organization_trails (
  organization_id UUID NOT NULL REFERENCES public.organizations (id) ON DELETE CASCADE,
  trail_id UUID NOT NULL,
  linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (organization_id, trail_id)
);

CREATE TRIGGER organizations_set_updated_at
BEFORE UPDATE ON public.organizations
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- Trails & assets
-- =============================================================================

CREATE TABLE public.trails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  agency TEXT,
  length_miles NUMERIC(8, 2),
  elevation_gain_ft NUMERIC(8, 0),
  difficulty public.trail_difficulty NOT NULL DEFAULT 'moderate',
  surface TEXT,
  trail_number TEXT,
  maintenance_level TEXT,
  motorized BOOLEAN NOT NULL DEFAULT FALSE,
  maintenance_score NUMERIC(5, 2),
  geom geography (LineString, 4326),
  source public.import_source,
  open_issue_count INTEGER NOT NULL DEFAULT 0,
  closed_issue_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type public.asset_type NOT NULL,
  name TEXT,
  trail_id UUID REFERENCES public.trails (id) ON DELETE SET NULL,
  notes TEXT,
  geom geography (Point, 4326),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Deferred FK: organization_trails.trail_id -> trails.id
ALTER TABLE public.organization_trails
  ADD CONSTRAINT organization_trails_trail_id_fkey
  FOREIGN KEY (trail_id) REFERENCES public.trails (id) ON DELETE CASCADE;

CREATE INDEX idx_trails_geom ON public.trails USING GIST (geom);
CREATE INDEX idx_trails_name ON public.trails (name);
CREATE INDEX idx_assets_geom ON public.assets USING GIST (geom);
CREATE INDEX idx_assets_trail_id ON public.assets (trail_id);
CREATE INDEX idx_organization_members_user_id ON public.organization_members (user_id);

CREATE TRIGGER trails_set_updated_at
BEFORE UPDATE ON public.trails
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER assets_set_updated_at
BEFORE UPDATE ON public.assets
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- RLS helpers
-- =============================================================================

CREATE OR REPLACE FUNCTION public.is_org_member(p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = p_org_id
      AND user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_trail(p_trail_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    public.is_admin_or_land_manager()
    OR EXISTS (
      SELECT 1
      FROM public.organization_trails ot
      JOIN public.organization_members om
        ON om.organization_id = ot.organization_id
      WHERE ot.trail_id = p_trail_id
        AND om.user_id = auth.uid()
    );
$$;

-- =============================================================================
-- Row Level Security
-- =============================================================================

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_trails ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trails ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organizations are publicly readable"
ON public.organizations
FOR SELECT
USING (TRUE);

CREATE POLICY "Authenticated users can create organizations"
ON public.organizations
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Org members and admins can update organizations"
ON public.organizations
FOR UPDATE
USING (
  public.is_admin_or_land_manager()
  OR public.is_org_member(id)
)
WITH CHECK (
  public.is_admin_or_land_manager()
  OR public.is_org_member(id)
);

CREATE POLICY "Organization members are readable"
ON public.organization_members
FOR SELECT
USING (TRUE);

CREATE POLICY "Users can join organizations"
ON public.organization_members
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Organization trails are publicly readable"
ON public.organization_trails
FOR SELECT
USING (TRUE);

CREATE POLICY "Org members can link trails"
ON public.organization_trails
FOR INSERT
TO authenticated
WITH CHECK (public.is_org_member(organization_id) OR public.is_admin_or_land_manager());

CREATE POLICY "Trails are publicly readable"
ON public.trails
FOR SELECT
USING (TRUE);

CREATE POLICY "Managers can insert trails"
ON public.trails
FOR INSERT
TO authenticated
WITH CHECK (public.is_admin_or_land_manager() OR auth.uid() IS NOT NULL);

CREATE POLICY "Managers can update trails"
ON public.trails
FOR UPDATE
USING (public.can_manage_trail(id) OR public.is_admin_or_land_manager())
WITH CHECK (public.can_manage_trail(id) OR public.is_admin_or_land_manager());

CREATE POLICY "Assets are publicly readable"
ON public.assets
FOR SELECT
USING (TRUE);

CREATE POLICY "Managers can insert assets"
ON public.assets
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin_or_land_manager()
  OR (trail_id IS NOT NULL AND public.can_manage_trail(trail_id))
);

CREATE POLICY "Managers can update assets"
ON public.assets
FOR UPDATE
USING (
  public.is_admin_or_land_manager()
  OR (trail_id IS NOT NULL AND public.can_manage_trail(trail_id))
)
WITH CHECK (
  public.is_admin_or_land_manager()
  OR (trail_id IS NOT NULL AND public.can_manage_trail(trail_id))
);

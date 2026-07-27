-- =============================================================================
-- Enums
-- =============================================================================

CREATE TYPE public.user_role AS ENUM (
  'volunteer',
  'crew_leader',
  'organization',
  'land_manager',
  'administrator'
);

CREATE TYPE public.issue_type AS ENUM (
  'blowdown',
  'erosion',
  'washout',
  'missing_bridge_plank',
  'bridge_damage',
  'missing_sign',
  'broken_sign',
  'brush_overgrowth',
  'drainage_blocked',
  'rock_slide',
  'trail_collapse',
  'hazard_tree',
  'vandalism',
  'campsite_damage',
  'illegal_trail',
  'other'
);

CREATE TYPE public.issue_priority AS ENUM (
  'low',
  'medium',
  'high',
  'critical'
);

CREATE TYPE public.issue_status AS ENUM (
  'open',
  'assigned',
  'scheduled',
  'in_progress',
  'needs_verification',
  'closed'
);

CREATE TYPE public.asset_type AS ENUM (
  'bridge',
  'trailhead',
  'gate',
  'kiosk',
  'sign',
  'campsite',
  'picnic_area',
  'water_crossing',
  'boardwalk',
  'parking_lot',
  'toilet',
  'bench'
);

CREATE TYPE public.trail_difficulty AS ENUM (
  'easy',
  'moderate',
  'difficult',
  'expert'
);

CREATE TYPE public.import_source AS ENUM (
  'osm',
  'usfs',
  'nps',
  'blm',
  'oregon',
  'washington',
  'california',
  'idaho',
  'colorado'
);

CREATE TYPE public.import_job_status AS ENUM (
  'pending',
  'running',
  'completed',
  'failed'
);

-- =============================================================================
-- Profiles & user metadata
-- =============================================================================

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT 'Volunteer',
  email TEXT,
  avatar_url TEXT,
  bio TEXT,
  volunteer_hours NUMERIC(10, 2) NOT NULL DEFAULT 0,
  is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.user_roles (
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  role public.user_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role)
);

CREATE TABLE public.user_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  skill TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, skill)
);

CREATE TABLE public.user_certifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  certification TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, certification)
);

CREATE TABLE public.user_equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  equipment TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, equipment)
);

CREATE INDEX idx_user_roles_user_id ON public.user_roles (user_id);
CREATE INDEX idx_user_skills_user_id ON public.user_skills (user_id);
CREATE INDEX idx_user_certifications_user_id ON public.user_certifications (user_id);
CREATE INDEX idx_user_equipment_user_id ON public.user_equipment (user_id);

-- =============================================================================
-- Shared helpers
-- =============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_set_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data ->> 'display_name',
      NEW.raw_user_meta_data ->> 'full_name',
      split_part(COALESCE(NEW.email, 'volunteer'), '@', 1)
    )
  );

  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'volunteer');

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.has_role(p_role public.user_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = p_role
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_land_manager()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role IN ('administrator', 'land_manager')
  );
$$;

-- =============================================================================
-- Row Level Security
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_equipment ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are readable by everyone"
ON public.profiles
FOR SELECT
USING (TRUE);

CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can read own roles"
ON public.user_roles
FOR SELECT
USING (auth.uid() = user_id OR public.is_admin_or_land_manager());

CREATE POLICY "Users manage own skills"
ON public.user_skills
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own certifications"
ON public.user_certifications
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own equipment"
ON public.user_equipment
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

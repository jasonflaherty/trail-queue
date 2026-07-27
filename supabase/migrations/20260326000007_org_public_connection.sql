-- Strengthen public ↔ organization connection metadata
DO $$ BEGIN
  CREATE TYPE public.organization_kind AS ENUM (
    'nonprofit',
    'association',
    'trailBuilders',
    'landAgency',
    'volunteerNetwork'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS kind public.organization_kind NOT NULL DEFAULT 'nonprofit',
  ADD COLUMN IF NOT EXISTS region TEXT,
  ADD COLUMN IF NOT EXISTS open_work_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS accepting_volunteers BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN NOT NULL DEFAULT false;

COMMENT ON TABLE public.organizations IS
  'Trail builders, nonprofits, associations, agencies, and volunteer networks that mobilize the public to fix trails.';

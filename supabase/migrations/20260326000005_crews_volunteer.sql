-- =============================================================================
-- Crews
-- =============================================================================

CREATE TABLE public.crews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  leader_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  organization_id UUID REFERENCES public.organizations (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.crew_members (
  crew_id UUID NOT NULL REFERENCES public.crews (id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (crew_id, user_id)
);

CREATE TABLE public.crew_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id UUID NOT NULL REFERENCES public.crews (id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  invited_by UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ
);

CREATE TABLE public.crew_calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id UUID NOT NULL REFERENCES public.crews (id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  location_label TEXT,
  issue_id UUID REFERENCES public.issues (id) ON DELETE SET NULL,
  created_by UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.crew_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id UUID NOT NULL REFERENCES public.crews (id) ON DELETE CASCADE,
  author_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Deferred FK: issues.crew_id -> crews.id
ALTER TABLE public.issues
  ADD CONSTRAINT issues_crew_id_fkey
  FOREIGN KEY (crew_id) REFERENCES public.crews (id) ON DELETE SET NULL;

-- =============================================================================
-- Volunteer hours & badges
-- =============================================================================

CREATE TABLE public.volunteer_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  issue_id UUID REFERENCES public.issues (id) ON DELETE SET NULL,
  crew_id UUID REFERENCES public.crews (id) ON DELETE SET NULL,
  hours NUMERIC(6, 2) NOT NULL CHECK (hours > 0),
  notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  criteria JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.user_badges (
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES public.badges (id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, badge_id)
);

-- =============================================================================
-- Notifications
-- =============================================================================

CREATE TYPE public.notification_kind AS ENUM (
  'nearby_issue',
  'crew_invitation',
  'issue_assigned',
  'verification_requested',
  'workday_reminder'
);

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  kind public.notification_kind NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  related_id UUID,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_crew_members_user_id ON public.crew_members (user_id);
CREATE INDEX idx_crew_invitations_crew_id ON public.crew_invitations (crew_id);
CREATE INDEX idx_crew_calendar_events_crew_id ON public.crew_calendar_events (crew_id);
CREATE INDEX idx_crew_messages_crew_id ON public.crew_messages (crew_id);
CREATE INDEX idx_volunteer_hours_user_id ON public.volunteer_hours (user_id);
CREATE INDEX idx_notifications_user_id ON public.notifications (user_id);
CREATE INDEX idx_notifications_unread ON public.notifications (user_id, read) WHERE read = FALSE;

CREATE TRIGGER crews_set_updated_at
BEFORE UPDATE ON public.crews
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- RLS helpers
-- =============================================================================

CREATE OR REPLACE FUNCTION public.is_crew_member(p_crew_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.crew_members
    WHERE crew_id = p_crew_id
      AND user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_crew_leader(p_crew_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.crews
    WHERE id = p_crew_id
      AND leader_id = auth.uid()
  );
$$;

-- =============================================================================
-- Row Level Security
-- =============================================================================

ALTER TABLE public.crews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Crews are readable by members and admins"
ON public.crews
FOR SELECT
USING (
  public.is_admin_or_land_manager()
  OR public.is_crew_member(id)
  OR leader_id = auth.uid()
);

CREATE POLICY "Authenticated users can create crews"
ON public.crews
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Crew leaders can update crews"
ON public.crews
FOR UPDATE
USING (public.is_crew_leader(id) OR public.is_admin_or_land_manager())
WITH CHECK (public.is_crew_leader(id) OR public.is_admin_or_land_manager());

CREATE POLICY "Crew members are visible to crew"
ON public.crew_members
FOR SELECT
USING (public.is_crew_member(crew_id) OR public.is_admin_or_land_manager());

CREATE POLICY "Users can join crews"
ON public.crew_members
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Crew invitations visible to invitee and leaders"
ON public.crew_invitations
FOR SELECT
USING (
  public.is_crew_leader(crew_id)
  OR public.is_crew_member(crew_id)
  OR public.is_admin_or_land_manager()
);

CREATE POLICY "Crew leaders can invite members"
ON public.crew_invitations
FOR INSERT
TO authenticated
WITH CHECK (public.is_crew_leader(crew_id) OR public.is_admin_or_land_manager());

CREATE POLICY "Crew calendar visible to members"
ON public.crew_calendar_events
FOR SELECT
USING (public.is_crew_member(crew_id) OR public.is_admin_or_land_manager());

CREATE POLICY "Crew leaders can manage calendar"
ON public.crew_calendar_events
FOR ALL
TO authenticated
USING (public.is_crew_leader(crew_id) OR public.is_admin_or_land_manager())
WITH CHECK (public.is_crew_leader(crew_id) OR public.is_admin_or_land_manager());

CREATE POLICY "Crew messages visible to members"
ON public.crew_messages
FOR SELECT
USING (public.is_crew_member(crew_id) OR public.is_admin_or_land_manager());

CREATE POLICY "Crew members can post messages"
ON public.crew_messages
FOR INSERT
TO authenticated
WITH CHECK (public.is_crew_member(crew_id) AND auth.uid() = author_id);

CREATE POLICY "Users manage own volunteer hours"
ON public.volunteer_hours
FOR ALL
USING (auth.uid() = user_id OR public.is_admin_or_land_manager())
WITH CHECK (auth.uid() = user_id OR public.is_admin_or_land_manager());

CREATE POLICY "Badges are publicly readable"
ON public.badges
FOR SELECT
USING (TRUE);

CREATE POLICY "User badges are readable"
ON public.user_badges
FOR SELECT
USING (auth.uid() = user_id OR public.is_admin_or_land_manager());

CREATE POLICY "Users manage own notifications"
ON public.notifications
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

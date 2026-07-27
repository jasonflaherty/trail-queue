-- Trail Queue demo seed data
-- NOTE: Auth users must be created separately via Supabase Auth.
-- This seed avoids auth.users FKs where possible (reported_by, leader_id, etc. are NULL).

-- Fixed UUIDs for stable references across environments
-- Organizations
INSERT INTO public.organizations (id, name, description, website, approved, kind, region, open_work_count, accepting_volunteers)
VALUES
  (
    '11111111-1111-4111-8111-111111111101',
    'Pacific Crest Trail Association',
    'Connects volunteers with trail crews to maintain the PCT corridor. Public reports help prioritize work.',
    'https://www.pcta.org',
    TRUE,
    'association',
    'Pacific Crest Trail',
    12,
    TRUE
  ),
  (
    '11111111-1111-4111-8111-111111111102',
    'Trailkeepers of Oregon',
    'Volunteer trail maintenance across Oregon. Partners with agencies and the public to keep trails open.',
    NULL,
    TRUE,
    'nonprofit',
    'Oregon',
    8,
    TRUE
  ),
  (
    '11111111-1111-4111-8111-111111111103',
    'Pending Trail Alliance',
    'Awaiting admin approval.',
    NULL,
    FALSE,
    'trailBuilders',
    NULL,
    0,
    TRUE
  ),
  (
    '11111111-1111-4111-8111-111111111104',
    'Northwest Trail Alliance',
    'Trail builders who design, build, and repair sustainable tread with community volunteers.',
    NULL,
    TRUE,
    'trailBuilders',
    'Portland Metro',
    5,
    TRUE
  ),
  (
    '11111111-1111-4111-8111-111111111105',
    'Mt. Hood National Forest',
    'Land manager for Mt. Hood trails. Reviews public reports and coordinates partner organizations.',
    NULL,
    TRUE,
    'landAgency',
    'Mt. Hood, OR',
    18,
    FALSE
  )
ON CONFLICT (id) DO NOTHING;

-- Badges
INSERT INTO public.badges (id, slug, name, description, criteria)
VALUES
  (
    '22222222-2222-4222-8222-222222222201',
    'first-issue',
    'First Report',
    'Reported your first trail issue.',
    '{"event":"issue_created","count":1}'::JSONB
  ),
  (
    '22222222-2222-4222-8222-222222222202',
    '10-hours',
    '10 Hour Club',
    'Logged 10 volunteer hours.',
    '{"volunteer_hours":10}'::JSONB
  ),
  (
    '22222222-2222-4222-8222-222222222203',
    'crew-leader',
    'Crew Leader',
    'Led a volunteer crew workday.',
    '{"role":"crew_leader"}'::JSONB
  )
ON CONFLICT (id) DO NOTHING;

-- Import sources
INSERT INTO public.import_sources (source, name, config)
VALUES
  ('osm', 'OpenStreetMap', '{"endpoint":"https://overpass-api.de/api/interpreter"}'::JSONB),
  ('usfs', 'US Forest Service', '{"stub":true}'::JSONB),
  ('nps', 'National Park Service', '{"stub":true}'::JSONB),
  ('blm', 'Bureau of Land Management', '{"stub":true}'::JSONB),
  ('oregon', 'Oregon GIS', '{"stub":true}'::JSONB),
  ('washington', 'Washington GIS', '{"stub":true}'::JSONB),
  ('california', 'California GIS', '{"stub":true}'::JSONB),
  ('idaho', 'Idaho GIS', '{"stub":true}'::JSONB),
  ('colorado', 'Colorado GIS', '{"stub":true}'::JSONB)
ON CONFLICT (source) DO NOTHING;

-- Trails (Mt. Hood area demo)
INSERT INTO public.trails (
  id, name, agency, length_miles, elevation_gain_ft, difficulty, surface,
  trail_number, maintenance_level, motorized, maintenance_score, geom, source,
  open_issue_count, closed_issue_count
)
VALUES
  (
    '33333333-3333-4333-8333-333333333301',
    'Bear Creek Trail',
    'US Forest Service',
    6.2, 1240, 'moderate', 'dirt', '512', '3', FALSE, 58,
    ST_GeogFromText('LINESTRING(-121.698 45.372, -121.705 45.378, -121.712 45.385)'),
    'usfs', 3, 12
  ),
  (
    '33333333-3333-4333-8333-333333333302',
    'Mirror Lake Trail',
    'US Forest Service',
    2.1, 180, 'easy', 'gravel', NULL, '2', FALSE, 82,
    ST_GeogFromText('LINESTRING(-121.712 45.361, -121.718 45.365)'),
    'osm', 1, 8
  ),
  (
    '33333333-3333-4333-8333-333333333303',
    'Timberline Trail',
    'US Forest Service',
    40.7, 9000, 'difficult', 'dirt', NULL, '4', FALSE, 42,
    ST_GeogFromText('LINESTRING(-121.711 45.331, -121.700 45.340, -121.690 45.350)'),
    'usfs', 7, 44
  ),
  (
    '33333333-3333-4333-8333-333333333304',
    'Lost Lake Loop',
    'Oregon Parks',
    3.4, 220, 'easy', 'dirt', NULL, '1', FALSE, 91,
    ST_GeogFromText('LINESTRING(-121.820 45.490, -121.825 45.495)'),
    'oregon', 0, 5
  ),
  (
    '33333333-3333-4333-8333-333333333305',
    'Tamanawas Falls',
    'US Forest Service',
    3.6, 500, 'moderate', 'dirt', NULL, '3', FALSE, 65,
    ST_GeogFromText('LINESTRING(-121.575 45.395, -121.580 45.400)'),
    'usfs', 2, 9
  )
ON CONFLICT (id) DO NOTHING;

-- Organization trail links
INSERT INTO public.organization_trails (organization_id, trail_id)
VALUES
  ('11111111-1111-4111-8111-111111111101', '33333333-3333-4333-8333-333333333301'),
  ('11111111-1111-4111-8111-111111111101', '33333333-3333-4333-8333-333333333303'),
  ('11111111-1111-4111-8111-111111111102', '33333333-3333-4333-8333-333333333304'),
  ('11111111-1111-4111-8111-111111111102', '33333333-3333-4333-8333-333333333305')
ON CONFLICT DO NOTHING;

-- Assets
INSERT INTO public.assets (id, type, name, trail_id, notes, geom)
VALUES
  (
    '44444444-4444-4444-8444-444444444401',
    'trailhead',
    'Bear Creek Trailhead',
    '33333333-3333-4333-8333-333333333301',
    NULL,
    ST_GeogFromText('POINT(-121.698 45.372)')
  ),
  (
    '44444444-4444-4444-8444-444444444402',
    'bridge',
    'Cold Spring Bridge',
    '33333333-3333-4333-8333-333333333305',
    'Footbridge near falls',
    ST_GeogFromText('POINT(-121.578 45.398)')
  ),
  (
    '44444444-4444-4444-8444-444444444403',
    'kiosk',
    'Mirror Lake Kiosk',
    '33333333-3333-4333-8333-333333333302',
    NULL,
    ST_GeogFromText('POINT(-121.712 45.361)')
  )
ON CONFLICT (id) DO NOTHING;

-- Issues (reported_by intentionally NULL for demo without auth users)
INSERT INTO public.issues (
  id, issue_number, type, priority, status, title, description,
  trail_id, asset_id, geom, estimated_hours, estimated_crew_size,
  estimated_duration_label, agency, safety_notes, created_at
)
VALUES
  (
    '55555555-5555-4555-8555-555555555501',
    4821, 'blowdown', 'high', 'open',
    'Fallen Tree Across Trail',
    'Large Douglas fir blocking the tread near mile 2.4. Needs crosscut saw and loppers.',
    '33333333-3333-4333-8333-333333333301', NULL,
    ST_GeogFromText('POINT(-121.702 45.376)'),
    3, 2, '2–4 hrs', 'US Forest Service', NULL,
    NOW() - INTERVAL '2 days'
  ),
  (
    '55555555-5555-4555-8555-555555555502',
    4822, 'erosion', 'medium', 'open',
    'Erosion on Switchback',
    'Outslope failed on upper switchback. Needs drainage rebuild and tread rebuild.',
    '33333333-3333-4333-8333-333333333301', NULL,
    ST_GeogFromText('POINT(-121.708 45.380)'),
    6, 4, '4–6 hrs', 'US Forest Service', NULL,
    NOW() - INTERVAL '5 days'
  ),
  (
    '55555555-5555-4555-8555-555555555503',
    4823, 'missing_sign', 'low', 'open',
    'Missing Directional Sign',
    'Junction sign post is empty. Post intact.',
    '33333333-3333-4333-8333-333333333302', NULL,
    ST_GeogFromText('POINT(-121.715 45.363)'),
    1, 1, '1–2 hrs', 'US Forest Service', NULL,
    NOW() - INTERVAL '1 day'
  ),
  (
    '55555555-5555-4555-8555-555555555504',
    4824, 'missing_bridge_plank', 'critical', 'assigned',
    'Bridge Plank Missing',
    'Center plank missing on footbridge. Unsafe for stock and bikes.',
    '33333333-3333-4333-8333-333333333305',
    '44444444-4444-4444-8444-444444444402',
    ST_GeogFromText('POINT(-121.578 45.398)'),
    4, 3, '3–5 hrs', 'US Forest Service',
    'Do not cross center span until repaired.',
    NOW() - INTERVAL '3 days'
  )
ON CONFLICT (id) DO NOTHING;

-- Issue tools
INSERT INTO public.issue_tools (issue_id, tool)
VALUES
  ('55555555-5555-4555-8555-555555555501', 'Crosscut saw'),
  ('55555555-5555-4555-8555-555555555501', 'Loppers'),
  ('55555555-5555-4555-8555-555555555501', 'Wedges'),
  ('55555555-5555-4555-8555-555555555502', 'McLeod'),
  ('55555555-5555-4555-8555-555555555502', 'Pulaski'),
  ('55555555-5555-4555-8555-555555555504', 'Drill'),
  ('55555555-5555-4555-8555-555555555504', 'Replacement plank')
ON CONFLICT DO NOTHING;

-- Recompute maintenance scores from seeded issues
SELECT public.compute_trail_maintenance_score(id)
FROM public.trails
WHERE id IN (
  '33333333-3333-4333-8333-333333333301',
  '33333333-3333-4333-8333-333333333302',
  '33333333-3333-4333-8333-333333333305'
);

-- Advance issue_number sequence past seeded values
SELECT setval(
  'public.issue_number_seq',
  GREATEST(5000, COALESCE((SELECT MAX(issue_number) FROM public.issues), 1000))
);

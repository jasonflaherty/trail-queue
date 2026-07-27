# Trail Queue API

Supabase provides auto-generated REST for PostGIS tables. Edge Functions extend GIS import and AI.

## REST resources

| Resource | Table |
|----------|-------|
| Trails | `trails` |
| Assets | `assets` |
| Issues | `issues` |
| Organizations | `organizations` |
| Crews | `crews` |
| Profiles | `profiles` |
| Photos | Storage bucket `issue-photos` |

## Edge Function endpoints

| Method | Function | Body |
|--------|----------|------|
| POST | `/functions/v1/import-trails` | `{ "source": "osm\|usfs\|nps\|blm\|oregon\|…", "polygon": [{"lat":0,"lng":0}] }` |
| POST | `/functions/v1/import-state-gis` | `{ "state": "oregon", "polygon": [...] }` |
| POST | `/functions/v1/ai-classify-issue` | `{ "description": "…", "labels": [] }` |
| POST | `/functions/v1/ai-find-duplicates` | `{ "lat", "lng", "title", "radius_m" }` |
| POST | `/functions/v1/ai-plan-workday` | `{ "issue_ids": [], "crew_id" }` |
| POST | `/functions/v1/admin-approve-org` | `{ "organization_id": "uuid" }` |

## Spatial helpers

- `find_nearby_issues(lat, lng, radius_m)`
- `compute_trail_maintenance_score(trail_id)`
- `insert_trail_from_wkt(...)`

Auth: pass `Authorization: Bearer <anon-or-user-jwt>`.

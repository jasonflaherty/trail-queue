# Getting started

## Prerequisites

- Flutter 3.24+ (Dart 3.5+)
- Optional: [Supabase CLI](https://supabase.com/docs/guides/cli) + Docker for local backend
- Optional: Melos (`dart pub global activate melos`)

## Run the app (demo mode)

Trail Queue runs without Supabase using seeded Mt. Hood demo data.

```bash
cd apps/client
flutter pub get
flutter run
```

You will land on Home signed in as **Alex** (demo). Use Profile → Settings → Sign out to reach Login and try email / Google / Apple / Facebook / Microsoft / anonymous flows (stubbed in demo mode).

## Design

Approved mockups:

- [design/mockup-core-screens.png](design/mockup-core-screens.png)
- [design/mockup-light-dark.png](design/mockup-light-dark.png)

Theme tokens live in `packages/ui` (`TrailQueueTheme`, `TqColors`).

## Local Supabase

```bash
cp .env.example .env
supabase start
supabase db reset
```

Pass keys into the Flutter app:

```bash
cd apps/client
flutter run --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Monorepo layout

See the root [README](../README.md).

## Edge Functions

| Function | Path |
|----------|------|
| Import trails | `supabase/functions/import-trails` |
| State GIS | `supabase/functions/import-state-gis` |
| AI classify | `supabase/functions/ai-classify-issue` |
| AI duplicates | `supabase/functions/ai-find-duplicates` |
| AI plan | `supabase/functions/ai-plan-workday` |
| Approve org | `supabase/functions/admin-approve-org` |

Deploy with `supabase functions deploy <name>`.

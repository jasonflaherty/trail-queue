# Contributing to Trail Queue

Thanks for helping build trail stewardship tooling.

## Development setup

1. Fork and clone the repo
2. Run `dart pub get && melos bootstrap`
3. Copy `.env.example` → `apps/client/.env`
4. Prefer feature branches: `feature/…`, `fix/…`

## Guidelines

- Keep the product focused on **stewardship**, not recreation
- Match UI to mockups in `docs/design/`
- Prefer small, reviewable PRs
- Run `melos run analyze` and `melos run test` before opening a PR
- Do not commit secrets (`.env`, API keys, keystores)

## Code style

- Dart: `dart format` + `flutter analyze`
- SQL migrations: numbered, idempotent where practical
- Edge Functions: TypeScript under `supabase/functions/`

## Reporting issues

Use GitHub Issues. Include platform, steps to reproduce, and expected vs actual behavior.

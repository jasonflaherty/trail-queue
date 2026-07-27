# Trail Queue

Open-source trail stewardship platform — **GitHub Issues + Google Maps** for maintaining trails.

Trail Queue connects **the public** with **trail builders, nonprofits, associations, volunteer crews, and land managers** so maintenance issues get reported, claimed, and fixed.

| Who | What they do |
|-----|----------------|
| Public / hikers | Report problems with photos + GPS |
| Volunteers | Find nearby work, join crews, log hours |
| Nonprofits & associations | Publish work, approve helpers, verify completion |
| Trail builders | Coordinate builds and repairs with partners |
| Land managers | Import official trails, moderate, partner with orgs |

> This is not another trail recreation app. It is an operational platform for stewardship.

When a member of the public submits a report, Trail Queue automatically routes it: the land agency that manages the trail, plus stewardship orgs and local crews in the area, each get a notification so the work lands with whoever can fix it.

## Stack

- **Flutter** (iOS, Android, Web)
- **Firebase Auth + Cloud Firestore + Storage** (offline persistence enabled)
- **Hive** for work-area downloads and sync UI queue

## Quick start (demo mode)

```bash
cd apps/client
flutter pub get
flutter run
```

Runs without Firebase using seeded Mt. Hood data. Offline queue still works.

## Firebase

See [docs/firebase.md](docs/firebase.md).

```bash
# After flutterfire configure:
cd apps/client
flutter run --dart-define=USE_FIREBASE=true
```

## Monorepo

| Path | Description |
|------|-------------|
| `apps/client` | Flutter app |
| `packages/models` | Shared Dart models |
| `packages/api` | Firebase + offline sync repositories |
| `packages/map` | flutter_map layers |
| `packages/ui` | Design system |
| `firestore.rules` | Security rules |
| `docs/` | Setup + design mockups |

## License

Apache License 2.0 — see [LICENSE](LICENSE).

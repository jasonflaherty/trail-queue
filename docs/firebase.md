# Firebase / Firestore setup for Trail Queue

## Demo mode (default)

```bash
cd apps/client
flutter run
```

No Firebase project required. Data lives in Hive + in-memory demo seed and still queues offline mutations.

## Enable Firebase

1. Create a Firebase project and enable **Authentication** providers:
   - Email/Password
   - Google
   - Apple (required on iOS App Store builds)
   - Facebook (create an app at [developers.facebook.com](https://developers.facebook.com), then paste App ID + App Secret into Firebase)
   - Microsoft (register an app in [Azure Entra ID](https://portal.azure.com), then paste Application/Client ID + secret into Firebase)
   - Anonymous
2. From `apps/client`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

3. Deploy rules:

```bash
firebase deploy --only firestore:rules
```

Rules file: [`firestore.rules`](../firestore.rules)

4. Run with Firebase:

```bash
cd apps/client
flutter run --dart-define=USE_FIREBASE=true
```

## Offline + sync

- **Firestore persistence** is enabled (`persistenceEnabled: true`) so reads/writes work offline and sync when connectivity returns.
- **Hive** still caches work areas, pending mutation UI state, and photo upload queue.
- Profile → **Offline & Sync** downloads a 15‑mile work area and shows pending sync status.
- A banner appears when offline or when changes are queued.

## Collections

| Collection | Purpose |
|------------|---------|
| `profiles` | User profiles + roles |
| `issues` | Maintenance issues (`location` as GeoPoint) |
| `trails` | Trail geometry + metadata |
| `assets` | Bridges, trailheads, etc. |
| `organizations` | Nonprofits, associations, builders, agencies |
| `crews` / `crew_invitations` | Crew management |
| `issue_queue` | My Queue membership |
| `notifications` | In-app notifications |
| `import_jobs` | GIS import job status |

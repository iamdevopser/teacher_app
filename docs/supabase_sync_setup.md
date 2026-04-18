# Supabase Sync Setup

This app keeps local `Hive` storage as the source of truth and syncs changes to Supabase when the user signs in.

## 1. Create the backend

1. Create a Supabase project.
2. Open the SQL editor.
3. Run `docs/supabase_sync_schema.sql`.
4. In `Authentication > Providers`, enable Email authentication.
5. Decide whether email confirmation is required.

## 2. Provide runtime keys

Build or run the app with:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

For release builds, pass the same `--dart-define` values in your CI or build command.

## 3. How syncing works

- All existing screens still write to local `Hive`.
- Each local write is marked as dirty.
- When the user signs in, local data is uploaded and merged with cloud data.
- When another device signs in with the same account, cloud data is pulled back locally.
- Deletions for list items are tracked with tombstones to avoid recreating removed records on another device.

## 4. Notes

- The app intentionally does not sync device-specific UI state such as the last opened item or the Wi-Fi-only toggle.
- The current conflict strategy is:
  - map payloads: recursive merge by key
  - list payloads with `id`: merge by item id
  - same record edited on two devices: newest timestamp wins
- Local file paths are still device-specific. Structured records sync across devices, but files referenced by absolute local path must be replaced with cloud storage in a later phase if you want the files themselves to travel between devices.

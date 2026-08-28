// ── Cloudinary image-upload configuration ───────────────────────────────────
// Uploads go straight from the browser to Cloudinary using an UNSIGNED upload
// preset, so no secret API keys live in the app.
//
// Setup (one time, ~3 minutes):
//   1. Create a free account at https://cloudinary.com
//   2. On the Dashboard, copy your "Cloud name" into kCloudinaryCloudName below.
//   3. Settings (gear) → Upload → Upload presets → "Add upload preset":
//        - Signing Mode: Unsigned
//        - Save, then copy the preset NAME into kCloudinaryUploadPreset below.
//
// Until both are filled in, the "Upload Image" buttons show a friendly notice.

const String kCloudinaryCloudName = 'YOUR_CLOUD_NAME';
const String kCloudinaryUploadPreset = 'YOUR_UNSIGNED_PRESET';

bool get kCloudinaryConfigured =>
    kCloudinaryCloudName.isNotEmpty &&
    kCloudinaryUploadPreset.isNotEmpty &&
    kCloudinaryCloudName != 'YOUR_CLOUD_NAME' &&
    kCloudinaryUploadPreset != 'YOUR_UNSIGNED_PRESET';

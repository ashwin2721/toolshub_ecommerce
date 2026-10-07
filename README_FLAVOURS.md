# Brands (Flutter flavours)

One codebase, two storefronts. Adding a third brand means adding one `const Brand`,
one entry point, one Gradle product flavour and one `tool/brands/<id>.json` — no
hunting for string literals.

| | Apex Deals | ToolsHub |
|---|---|---|
| Entry point | `lib/main.dart` (**default**) | `lib/main_toolshub.dart` |
| Gradle flavour | `apexdeals` | `toolshub` |
| Android app id | `com.apexdeals.app` | `com.toolshub.app` |
| Brand definition | `lib/core/brand/brands.dart` → `kApexDeals` | `kToolsHub` |
| Web values | `tool/brands/apexdeals.json` | `tool/brands/toolshub.json` |
| Dev web port | 8080 | 8081 |

## Running and building

`tool/brand.py` is the single source of truth for the build flags — it holds the ten
web-define values once so they cannot drift between a launch config, a script and CI.

```
python tool/brand.py apexdeals chrome          # run on :8080
python tool/brand.py toolshub  chrome          # run on :8081  (both can run at once)
python tool/brand.py toolshub  web   prod      # -> build/web/toolshub
python tool/brand.py apexdeals apk   prod
python tool/brand.py apexdeals apk   dev -- --debug
```

VS Code users get the same four combinations in `.vscode/launch.json`.

## The two axes

**Brand** and **environment** are independent and must stay that way:

- **Brand** = the entry point (+ the Gradle flavour on Android, which is what sets the
  app name and bundle id). A wrong `-t` path is a build error; a mistyped string define
  would silently ship the wrong storefront.
- **Environment** = `--dart-define=ENV=dev|prod`, choosing which backend to talk to.

They cannot be merged, because **`flutter build web` has no `--flavor` flag at all** — an
environment expressed as a Gradle flavour would be unreachable on the web target.

## Web branding

`web/index.html` is a single tokenised template. Flutter's own `--web-define=KEY=VALUE`
substitutes `{{KEY}}` at both run and build time, so there is no pre-build script and no
duplicated `web/` directory.

Two things to know:

- `--web-define` **does not** template `manifest.json` — only `index.html` and
  `flutter_bootstrap.js`. That is why each brand has its own
  `web/brand/<id>/manifest.json`, favicon, logo and icons.
- A **missing** `--web-define` is only a build *warning*, and the literal `{{TOKEN}}`
  ships to users. Always build through `tool/brand.py`, and keep this in CI:

  ```
  grep -c '{{' build/web/<brand>/index.html     # must be 0
  ```

## Deploying

Each brand needs its own Netlify/Vercel project, because `publish`/`outputDirectory`
cannot expand an environment variable. Set `BRAND` per project and point the build
command at `tool/brand.py`.

## What differs per brand, and what does not

Per brand: name, wordmark, logo mark, tagline, legal entity, support/privacy email,
phone, address, about copy, API base URL, accent colours, and the feature flags.

Shared on purpose: the whole monochrome palette in `AppColors` (64 `static const`
tokens, ~829 call sites — only a handful of genuinely brand-coloured surfaces read
`BrandColors`), the Poppins typeface, shipping thresholds, and the Cloudinary upload
bucket.

Admin-editable rather than per brand: the announcement bar and hero copy come from
`storeSettingsProvider`; brand config only supplies their fallbacks.

## Feature flags

`BrandFlags` in `lib/core/brand/brand.dart`. ToolsHub enables all three; Apex Deals none.

- `toolServiceBooking` — the tool calibration booking screen, its route and its profile
  menu entry. When off, `/support/tool-service` redirects to `/support` rather than 404ing,
  since that URL may already be indexed.
- `toolBrandTypoDictionary` — swaps the 46-entry tool-brand spellchecker for a generic
  commerce one.
- `projectAssistant` — the AI assistant's contractor persona and its tool keyword mapping.

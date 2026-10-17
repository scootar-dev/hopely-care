# App revision verification - 17 October 2026

## Scope

- Community bottom navigation and the floating AI dialog.
- Feed support toggling, comment composer, and private photo previews.
- Forgot-password placement below the password field.
- Structured doctor-summary sections on a narrow display.
- Sharing statistics returned by the backend instead of dummy counts.
- Device treatment reminders, cancellation, logout races, and fallback when exact alarms are unavailable.

## Checks repeated locally

- Flutter analysis: no issues after resolving eight brace-style diagnostics.
- Focused Flutter tests: 9 passed in `app_revisions_test.dart` and `treatment_reminders_test.dart`.
- Laravel community tests: 13 passed, 130 assertions, using an isolated in-memory SQLite database and PHP GD.
- Android debug APK: built successfully for `https://hopely.senindrai.my.id/api`, at `mobile/build/app/outputs/flutter-apk/app-debug.apk` (181455544 bytes).

The Windows build encountered Kotlin incremental-cache errors because the package cache and checkout are on different drives. The successful Gradle invocation used `-Pkotlin.incremental=false` and `-Pkotlin.compiler.execution.strategy=in-process`, with the API define base64-encoded into `-Pdart-defines`. These were command-line overrides, not permanent project settings. Dependency deprecation warnings remain; the APK is a debug build for testing, not a production release.

The first backend attempt loaded the local cached MySQL configuration and could not connect. The successful run bypassed that configuration for the test process only; it did not change the deployed configuration or require a running MySQL server.

PowerShell backend reproduction, from `backend`:

```powershell
$env:APP_ENV='testing'
$env:APP_CONFIG_CACHE='bootstrap/cache/phpunit-config-unused.php'
$env:DB_CONNECTION='sqlite'
$env:DB_DATABASE=':memory:'
php -d extension=gd vendor/bin/phpunit --filter CommunityTest --do-not-cache-result
```

## Limits

These are targeted component tests, not confirmation that the entire older test suite passes. The previous session reported older UI-test mismatches; the full suite was not rerun here.

Physical-device notification delivery and permissions, live AI responses, and end-to-end behavior against the deployed backend still require device/server verification. Backend changes must be deployed as well as installing the updated APK. No GitHub upload, push, or production deployment was performed in this continuation.

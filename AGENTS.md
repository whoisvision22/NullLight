# NullLight working instructions

- This is the active NullLight source repository: https://github.com/whoisvision22/NullLight.
- The user explicitly requests every completed new version to be synchronized to GitHub and published for download. This authorization persists; do not ask again for routine version commits and pushes.
- Keep app/NullLight.html and demo/NullLight.html behavior in sync. The demo has sample fixtures; the installed app starts with an empty patch. Do not include user shows, media, credentials or generated app bundles in Git commits.
- Before a new version, increment the integer in version.json, update package.json and the UI version labels, and update RELEASE-NOTES.md. Keep the version consistent across the native bundle, update payload, manifest and demo package.
- Run npm test, npm run test:demo and ruby tests/updater-check.rb. On macOS build the app with ruby scripts/build-mac.rb and verify its signature.
- Commit and push main after the checks pass. The GitHub workflow builds the Mac app and Windows browser demo and publishes one release per version, including checksummed update files. Follow the workflow through to completion and report a failure honestly; do not claim a release exists before verifying it.
- Never overwrite a published version. Make a new version for any further release.
- The Mac updater is opt-in: check, download/stage, then restart. Preserve show storage, verify checksums and retain prior versions. Launcher/runtime changes need a newer minimumBootstrap and a fresh Mac download.
- The Git SSH authentication is configured locally for this repository only. Never print or commit private keys, tokens or local .git configuration.

from pathlib import Path
import base64
import re
import shutil

root = Path(__file__).resolve().parents[1]
build = root / 'android/app/build.gradle.kts'
manifest = root / 'android/app/src/main/AndroidManifest.xml'

if build.exists():
    text = build.read_text()
    text = re.sub(r'namespace\s*=\s*"[^"]+"', 'namespace = "com.tripbanban.app"', text)
    text = re.sub(r'applicationId\s*=\s*"[^"]+"', 'applicationId = "com.tripbanban.app"', text)
    # Google Play requires Android 16 / API 36 for new apps and updates
    # submitted after 2026-08-31. Pin both values explicitly so the release
    # does not depend on a Flutter template default.
    text = re.sub(r'compileSdk\s*=\s*[^\n]+', 'compileSdk = 36', text)
    text = re.sub(r'targetSdk\s*=\s*[^\n]+', 'targetSdk = 36', text)
    build.write_text(text)

if manifest.exists():
    text = manifest.read_text()
    if 'android.permission.INTERNET' not in text:
        close = text.find('>')
        if close >= 0:
            text = text[:close + 1] + '\n    <uses-permission android:name="android.permission.INTERNET" />' + text[close + 1:]
    text = text.replace('android:label="tripbanban_app"', 'android:label="旅行伴伴"')
    manifest.write_text(text)

# Flutter creates MainActivity using the generated project package
# (com.tripbanban.tripbanban_app). The applicationId/namespace above are
# intentionally com.tripbanban.app, so keep the Activity class package aligned
# with the manifest's relative android:name=".MainActivity".
activity_roots = [
    root / 'android/app/src/main/kotlin',
    root / 'android/app/src/main/java',
]
main_activities = []
for activity_root in activity_roots:
    if activity_root.exists():
        main_activities.extend(activity_root.rglob('MainActivity.kt'))
        main_activities.extend(activity_root.rglob('MainActivity.java'))

if not main_activities:
    raise SystemExit('ERROR: MainActivity source was not generated.')

for activity in main_activities:
    text = activity.read_text()
    if activity.suffix == '.kt':
        text, count = re.subn(
            r'^\s*package\s+[A-Za-z0-9_.]+\s*$',
            'package com.tripbanban.app',
            text,
            count=1,
            flags=re.MULTILINE,
        )
    else:
        text, count = re.subn(
            r'^\s*package\s+[A-Za-z0-9_.]+\s*;\s*$',
            'package com.tripbanban.app;',
            text,
            count=1,
            flags=re.MULTILINE,
        )
    if count != 1:
        raise SystemExit(f'ERROR: Unable to patch package declaration in {activity}.')
    activity.write_text(text)

# v0.8.4 stores the approved refined logo as small text chunks so the source
# remains safely writable through repository tooling. Rebuild the PNG before
# Flutter packages assets and Android compiles launcher resources.
icon = root / 'assets/branding/tripbanban_icon.png'
logo_parts_dir = root / 'assets/branding/logo_v084'
logo_parts = sorted(logo_parts_dir.glob('part_*.b64')) if logo_parts_dir.exists() else []
if logo_parts:
    encoded = ''.join(part.read_text().strip() for part in logo_parts)
    try:
        decoded = base64.b64decode(encoded, validate=True)
    except Exception as exc:
        raise SystemExit(f'ERROR: Invalid v0.8.4 launcher logo payload: {exc}')
    if not decoded.startswith(b'\x89PNG\r\n\x1a\n'):
        raise SystemExit('ERROR: Reconstructed launcher icon is not a PNG.')
    if len(decoded) < 4096:
        raise SystemExit('ERROR: Reconstructed launcher icon is unexpectedly small.')
    icon.write_bytes(decoded)

if not icon.exists():
    raise SystemExit('ERROR: assets/branding/tripbanban_icon.png is missing.')

res_root = root / 'android/app/src/main/res'
launchers = sorted(res_root.glob('mipmap-*/ic_launcher.png')) if res_root.exists() else []
if not launchers:
    raise SystemExit('ERROR: Android launcher icon targets were not generated.')
for launcher in launchers:
    shutil.copyfile(icon, launcher)

# Fail CI early if the generated Android identity is inconsistent.
if build.exists():
    build_text = build.read_text()
    if 'namespace = "com.tripbanban.app"' not in build_text:
        raise SystemExit('ERROR: Android namespace is not com.tripbanban.app.')
    if 'applicationId = "com.tripbanban.app"' not in build_text:
        raise SystemExit('ERROR: Android applicationId is not com.tripbanban.app.')
    if 'compileSdk = 36' not in build_text:
        raise SystemExit('ERROR: Android compileSdk is not 36.')
    if 'targetSdk = 36' not in build_text:
        raise SystemExit('ERROR: Android targetSdk is not 36.')

for activity in main_activities:
    expected = 'package com.tripbanban.app' + (';' if activity.suffix == '.java' else '')
    if expected not in activity.read_text():
        raise SystemExit(f'ERROR: MainActivity package mismatch in {activity}.')

for launcher in launchers:
    if launcher.read_bytes() != icon.read_bytes():
        raise SystemExit(f'ERROR: Launcher icon mismatch in {launcher}.')

print(f'Android patch OK: com.tripbanban.app/MainActivity; API=36; launcher icons={len(launchers)}; logo bytes={icon.stat().st_size}')

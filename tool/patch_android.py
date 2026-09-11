from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
build = root / 'android/app/build.gradle.kts'
manifest = root / 'android/app/src/main/AndroidManifest.xml'

if build.exists():
    text = build.read_text()
    text = re.sub(r'namespace\s*=\s*"[^"]+"', 'namespace = "com.tripbanban.app"', text)
    text = re.sub(r'applicationId\s*=\s*"[^"]+"', 'applicationId = "com.tripbanban.app"', text)
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

# Fail CI early if the generated Android identity is inconsistent.
if build.exists():
    build_text = build.read_text()
    if 'namespace = "com.tripbanban.app"' not in build_text:
        raise SystemExit('ERROR: Android namespace is not com.tripbanban.app.')
    if 'applicationId = "com.tripbanban.app"' not in build_text:
        raise SystemExit('ERROR: Android applicationId is not com.tripbanban.app.')

for activity in main_activities:
    expected = 'package com.tripbanban.app' + (';' if activity.suffix == '.java' else '')
    if expected not in activity.read_text():
        raise SystemExit(f'ERROR: MainActivity package mismatch in {activity}.')

print('Android patch OK: com.tripbanban.app/MainActivity')

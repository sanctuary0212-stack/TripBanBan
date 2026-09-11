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
        marker = '<manifest'
        close = text.find('>')
        if close >= 0:
            text = text[:close+1] + '\n    <uses-permission android:name="android.permission.INTERNET" />' + text[close+1:]
    text = text.replace('android:label="tripbanban_app"', 'android:label="旅行伴伴"')
    manifest.write_text(text)

from pathlib import Path

p = Path('android/app/build.gradle.kts')
if not p.exists():
    raise SystemExit('android/app/build.gradle.kts not found; generate Android first')

s = p.read_text(encoding='utf-8')

# Use environment variables supplied by GitHub Actions secrets. No signing
# credentials are persisted in the repository or generated source tree.
old = '''    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
'''
new = '''    signingConfigs {
        create("release") {
            val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
                ?: error("ANDROID_KEYSTORE_PATH is required for production signing")
            storeFile = file(keystorePath)
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                ?: error("ANDROID_KEYSTORE_PASSWORD is required")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                ?: error("ANDROID_KEY_ALIAS is required")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
                ?: error("ANDROID_KEY_PASSWORD is required")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
'''
if old not in s:
    # Be strict: never silently produce a production bundle with debug signing.
    raise SystemExit('Expected Flutter debug release signing block not found')
s = s.replace(old, new, 1)
p.write_text(s, encoding='utf-8')
print('Production release signing configured from environment secrets')

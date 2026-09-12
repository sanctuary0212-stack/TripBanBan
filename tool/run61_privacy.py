from pathlib import Path

p = Path('lib/screens/settings_screen.dart')
s = p.read_text(encoding='utf-8')

needle = """            _ReleaseNote(text: 'Removed Google Drive backup and restore'),
          ]),
        ],
"""
replacement = """            _ReleaseNote(text: 'Removed Google Drive backup and restore'),
          ]),
          const SizedBox(height: 12),
          _section('Privacy Policy', const [
            Padding(
              padding: EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                'Effective date: September 12, 2026\\n\\n'
                'TripBanBan (旅行伴伴) is a local-first travel expense and settlement app. '
                'Trip projects, traveler names, expenses, shared-fund transactions, settlement information, settings, exchange-rate records, and photo attachments are stored on your device. '
                'TripBanBan does not operate an account server for this ledger data and does not automatically upload trip data to TripBanBan servers.\\n\\n'
                'If you choose a photo or import/export a .tripbanban file, the app accesses only the media or file you select for that user-requested feature. Exported backups are controlled by you and may contain ledger data and local photo attachments. Google Drive backup and restore are not part of the production app.\\n\\n'
                'TripBanBan Plus is a one-time purchase processed by Google Play. TripBanBan receives purchase and entitlement status needed to unlock Plus features, but does not process or store payment-card details.\\n\\n'
                'The app contains no advertising SDK and is not designed for cross-app advertising tracking. Local data remains on your device until you delete it, clear app storage, uninstall the app, or replace it through an import. Exported backup files must be deleted separately from the storage location you selected.\\n\\n'
                'Privacy inquiries: https://github.com/sanctuary0212-stack/TripBanBan/issues/new\\n\\n'
                'Public policy URL: https://sanctuary0212-stack.github.io/TripBanBan/privacy/',
              ),
            ),
          ]),
        ],
"""
if needle not in s:
    raise SystemExit('Privacy insertion target not found in settings_screen.dart')
s = s.replace(needle, replacement, 1)
p.write_text(s, encoding='utf-8')
print('Run61 applied: in-app Privacy Policy disclosure')

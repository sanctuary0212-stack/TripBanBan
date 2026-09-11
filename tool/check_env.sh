#!/usr/bin/env bash
set -u
printf 'TripBanBan Android toolchain check\n'
printf '%-18s %s\n' 'Java:' "$(java -version 2>&1 | head -1 || echo MISSING)"
printf '%-18s %s\n' 'Git:' "$(git --version 2>/dev/null || echo MISSING)"
printf '%-18s %s\n' 'Flutter:' "$(flutter --version 2>/dev/null | head -1 || echo MISSING)"
printf '%-18s %s\n' 'Dart:' "$(dart --version 2>&1 | head -1 || echo MISSING)"
printf '%-18s %s\n' 'sdkmanager:' "$(command -v sdkmanager || echo MISSING)"
printf '%-18s %s\n' 'adb:' "$(command -v adb || echo MISSING)"
printf '%-18s %s\n' 'ANDROID_HOME:' "${ANDROID_HOME:-UNSET}"
if command -v curl >/dev/null 2>&1; then
  if curl -fsSI --max-time 5 https://storage.googleapis.com >/dev/null 2>&1; then
    echo 'Network egress: OK'
  else
    echo 'Network egress: BLOCKED'
  fi
fi

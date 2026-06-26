#!/bin/bash
# 빌드에 사용된 코드 서명 인증서 SHA-256을 Info.plist에 주입합니다.
set -euo pipefail

IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY_NAME:-}"
if [[ -z "$IDENTITY" || "$IDENTITY" == "-" ]]; then
  echo "warning: [Elegaiter] No code signing identity; skip ElegaiterSDKCodeSignature injection"
  exit 0
fi

FINGERPRINT=$(security find-certificate -c "$IDENTITY" -p 2>/dev/null \
  | openssl x509 -noout -fingerprint -sha256 2>/dev/null \
  | sed 's/^.*Fingerprint=//' | tr -d '\n' || true)

if [[ -z "$FINGERPRINT" ]]; then
  echo "warning: [Elegaiter] Could not compute SHA-256 for: $IDENTITY"
  exit 0
fi

HASH=$(echo "$FINGERPRINT" | tr '[:lower:]' '[:upper:]')

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [[ ! -f "$PLIST" ]]; then
  PLIST="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Info.plist"
fi

if [[ ! -f "$PLIST" ]]; then
  echo "warning: [Elegaiter] Info.plist not found for signature injection"
  exit 0
fi

/usr/libexec/PlistBuddy -c "Delete :ElegaiterSDKCodeSignature" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ElegaiterSDKCodeSignature string ${HASH}" "$PLIST"
echo "Elegaiter SDK Signature (for server registration): ${HASH}"

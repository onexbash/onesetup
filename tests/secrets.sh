#!/usr/bin/env bash
# Tests for resolve_secret & load_secrets (bin/onesetup-util) with stub password manager CLIs.
# Run: bash tests/secrets.sh  (needs mikefarah/yq)

repo="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fails=0

# -- Stubs: print what they were asked for -- #
mkdir -p "$tmp/bin"
cat >"$tmp/bin/pass-cli" <<'EOF'
#!/usr/bin/env bash
echo "pass:$*"
EOF
cat >"$tmp/bin/keepassxc-cli" <<'EOF'
#!/usr/bin/env bash
echo "kp:$*"
EOF
cat >"$tmp/bin/bw" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == "get item GitHub" ]] || exit 1
echo '{"login": {"username": "me", "password": "bw-pass"}, "notes": "a note", "fields": [{"name": "Token", "value": "bw-token"}]}'
EOF
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH"
touch "$tmp/db.kdbx"
export ONESETUP_KEEPASSXC_DB="$tmp/db.kdbx"
export ONESETUP_CONFIG="$tmp/config.yml"

# shellcheck source=/dev/null
source "$repo/bin/onesetup-util"
set +e # count failures instead of stopping

check() { # check <description> <expected> <actual>
  if [[ "$2" == "$3" ]]; then
    echo "ok   - $1"
  else
    echo "FAIL - $1: expected '$2', got '$3'"
    fails=$((fails + 1))
  fi
}

# -- resolve_secret -- #
check "plain value stays" "plain secret" "$(resolve_secret "plain secret")"
check "Proton Pass" "pass:item view --vault-name Development --item-title GitHub PAT - Public_Read --field Secret" \
  "$(resolve_secret "pass://Development/GitHub PAT - Public_Read/Secret")"
check "KeePassXC (group path)" "kp:show --quiet --show-protected --attributes Password $tmp/db.kdbx Dev/Git/GitHub" \
  "$(resolve_secret "keepassxc://Dev/Git/GitHub/Password" 2>/dev/null)"
check "Bitwarden login field" "bw-pass" "$(resolve_secret "bitwarden://GitHub/password")"
check "Bitwarden notes" "a note" "$(resolve_secret "bitwarden://GitHub/notes")"
check "Bitwarden custom field" "bw-token" "$(resolve_secret "bitwarden://GitHub/Token")"
resolve_secret "pass://OnlyItem/Field" &>/dev/null
check "Proton Pass without vault fails" "1" "$?"
resolve_secret "bitwarden://GitHub" &>/dev/null
check "reference without field fails" "1" "$?"

# -- load_secrets: config 'secrets:' & precedence -- #
cat >"$ONESETUP_CONFIG" <<'EOF'
secrets:
  ONESETUP_SSH_PASS: "pass://Development/SSH Key/Passphrase"
  GITHUB_PAT_PUBLIC_READ: "bitwarden://GitHub/Token"
EOF
(
  unset ONESETUP_SSH_PASS ONESETUP_VAULT_PASS GITHUB_PAT_PUBLIC_READ
  export ONESETUP_VAULT_PASS="plain-vault-pass"
  load_secrets
  check "config reference resolved" "pass:item view --vault-name Development --item-title SSH Key --field Passphrase" "$ONESETUP_SSH_PASS"
  check "custom config secret exported" "bw-token" "$GITHUB_PAT_PUBLIC_READ"
  check "plain env value kept" "plain-vault-pass" "$ONESETUP_VAULT_PASS"
  [[ "$fails" -eq 0 ]]
) || fails=$((fails + 1))
(
  export ONESETUP_SSH_PASS="from-env"
  load_secrets ONESETUP_SSH_PASS
  check "environment wins over config" "from-env" "$ONESETUP_SSH_PASS"
  [[ "$fails" -eq 0 ]]
) || fails=$((fails + 1))

cat >"$ONESETUP_CONFIG" <<'EOF'
secrets:
  ONESETUP_SSH_PASS: "plain-secret-in-config"
EOF
(unset ONESETUP_SSH_PASS && load_secrets ONESETUP_SSH_PASS) &>/dev/null
check "plain secret in config is rejected" "1" "$?"

echo "${fails} failure(s)"
[[ "$fails" -eq 0 ]]

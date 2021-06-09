#!/bin/bash
set -e

VERSION="$1"
SUBSTRATE_REPO="s3krit/substrate"
BEEFY_REPO="s3krit/grandpa-bridge-gadget"
POLKADOT_REPO="s3krit/polkadot"

# Pre-flight checks
if [ -z "$VERSION" ]; then
  echo "[!] Version not specified, exiting..."
  exit 1
fi

if [ ! "$(which diener 2> /dev/null)" ]; then
  # shellcheck disable=SC2016
  echo '[!] diener not found in $PATH. Please install Diener with `cargo install diener`'
  exit 1
fi

echo "This script will begin the release process, performing the following actions:"
echo "  - Create a new branch in polkadot called release-$VERSION at the current master commit"
echo "  - Create a new branch in substrate called polkadot-$VERSION at the current commit used by this commit of polkadot"
echo "  - Create a new branch in grandpa-bridge-gadget called polkadot-$VERSION at the current commit used by this commit of polkadot, and patch it to use the newly-created *substrate* polkadot-$VERSION branch"
echo "  - Patch polkadot to use the newly-created substrate & grandpa-bridge-gadget polkadot-$VERSION branches"
echo "  - Trigger a Github Actions workflow to create a new tracking issue for this release"
echo
echo "Hit enter to proceed"
read -r

echo "[+] Cloning Polkadot into a temporary directory"

POLKADOT_DIR="$(mktemp -d /tmp/polkadot-XXXX)"
git clone "git@github.com:$POLKADOT_REPO.git" "$POLKADOT_DIR"

pushd "$POLKADOT_DIR"
  SUBSTRATE_COMMIT="$(grep 'paritytech/substrate' Cargo.lock | uniq | head -n1  | grep -oE '[a-f0-9]{40}')"
  BEEFY_COMMIT="$(grep 'paritytech/grandpa-bridge-gadget' Cargo.lock | uniq | head -n1  | grep -oE '[a-f0-9]{40}')"
popd

sleep 2
echo
echo "[+] Cloning Substrate into a temporary directory"

SUBSTRATE_DIR=$(mktemp -d /tmp/substrate-XXXX)
git clone "git@github.com:$SUBSTRATE_REPO.git" "$SUBSTRATE_DIR"

echo
echo "[+] Creating and pushing substrate polkadot-$VERSION branch"

pushd "$SUBSTRATE_DIR"
  git checkout "$SUBSTRATE_COMMIT"
  git checkout -b "polkadot-$VERSION"
  git push origin "polkadot-$VERSION"
popd

sleep 2
echo
echo "[+] Cloning grandpa-bridge-gadget into a temporary directory"

BEEFY_DIR=$(mktemp -d /tmp/beefy-XXXX)
git clone "git@github.com:$BEEFY_REPO.git" "$BEEFY_DIR"

echo
echo "[+] Creating beefy polkadot-$VERSION branch and patching substrate"

pushd "$BEEFY_DIR"
  git checkout "$BEEFY_COMMIT"
  git checkout -b "polkadot-$VERSION"
  diener update --branch "polkadot-$VERSION" --git "https://github.com/$SUBSTRATE_REPO" --substrate
  cargo check
  git add .
  git commit -S -m "bump substrate to polkadot-$VERSION"
  git push origin "polkadot-$VERSION"
popd

echo
echo "[+] Patching Polkadot to use substrate + beefy polkadot-$VERSION branches and creating release branch"

pushd "$POLKADOT_DIR"
  git checkout -b "release-$VERSION"
  diener update --branch "polkadot-$VERSION" --git "https://github.com/$SUBSTRATE_REPO" --substrate
  diener update --branch "polkadot-$VERSION" --git "https://github.com/$BEEFY_REPO" --beefy
  cargo check
  git add .
  git commit -S -m "bump substrate + beefy to polkadot-$VERSION"
  git push origin "release-$VERSION"
popd

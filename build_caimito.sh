#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

parameters=
if [ "${BUILD_AOSP_KERNEL}" = "1" ]; then
  echo "WARNING: BUILD_AOSP_KERNEL is deprecated." \
    "Use --kernel_package=@//aosp instead." >&2
  parameters="--kernel_package=@//aosp"
fi

if [ "${BUILD_STAGING_KERNEL}" = "1" ]; then
  echo "WARNING: BUILD_STAGING_KERNEL is deprecated." \
    "Use --kernel_package=@//aosp-staging instead." >&2
  parameters="--kernel_package=@//aosp-staging"
fi

# clean out/ to avoid confusion with signing keys
test -d out/ && rm -rf out/

tools/bazel run \
    ${parameters} \
    --config=stamp \
    --config=caimito \
    //private/devices/google/caimito:zumapro_caimito_dist "$@"

# dont proceed if build failed
test -d out/caimito/dist || exit 1

sign_file=$(mktemp)
trap '{ rm -f -- "$sign_file"; }' EXIT
prebuilts/clang/host/linux-x86/clang-r487747c/bin/clang aosp/scripts/sign-file.c -lssl -lcrypto -o ${sign_file}
find out/caimito/dist -type f -name "*.ko" \
  -exec ${sign_file} sha256 \
  $(find out/ -type f -name "signing_key.pem") \
  $(find out/ -type f -name "signing_key.x509") {} \;

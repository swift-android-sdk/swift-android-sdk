#!/bin/bash -ex

patches_dir=$(dirname $(realpath -- "${BASH_SOURCE[0]}"))
# the source checkout is expected to be the peer of this repo
cd ${1:-${patches_dir}/..}

# patch the patch, which seems to only be needed for an API less than 28
# https://github.com/finagolfin/swift-android-sdk/blob/main/swift-android.patch#L110
perl -pi -e 's/#if os\(Windows\)/#if os\(Android\)/g' ${patches_dir}/swift-android.patch

# remove the need to link in android-execinfo
perl -pi -e 's;dispatch android-execinfo;dispatch;g' ${patches_dir}/swift-android.patch

case "${BUILD_SCHEME}" in
    release)
        git apply -v -C1 ${patches_dir}/swift-android.patch
        git apply -v -C1 ${patches_dir}/swift-android-testing-release.patch
        git apply -v -C1 ${patches_dir}/swift-android-build-script.patch
        ;;
    swift-*-branch)
        git apply -v -C1 ${patches_dir}/swift-android.patch
        git apply -v -C1 ${patches_dir}/swift-android-devel.patch
        git apply -v -C1 ${patches_dir}/swift-android-testing-except-release.patch
        git apply -v -C1 ${patches_dir}/swift-android-build-script.patch
        ;;
    development)
        git apply -v -C1 ${patches_dir}/swift-android.patch
        git apply -v -C1 ${patches_dir}/swift-android-trunk-libdispatch.patch
        git apply -v -C1 ${patches_dir}/swift-android-testing-except-release.patch
        git apply -v -C1 ${patches_dir}/swift-android-build-script.patch
        ;;
    *)
        echo "$0: invalid BUILD_SCHEME=${BUILD_SCHEME}"
        exit 1
        ;;
esac

perl -pi -e 's%String\(cString: getpass%\"fake\" //%' swiftpm/Sources/PackageRegistryCommand/PackageRegistryCommand+Auth.swift
# disable backtrace() for Android (needs either API33+ or libandroid-execinfo, or to manually add in backtrace backport)
perl -pi -e 's;os\(Android\);os\(AndroidDISABLED\);g' swift-testing/Sources/Testing/SourceAttribution/Backtrace.swift

# need to un-apply libandroid-spawn since we don't need it for API28+
perl -pi -e 's;MATCHES "Android";MATCHES "AndroidDISABLED";g' llbuild/lib/llvm/Support/CMakeLists.txt
perl -pi -e 's; STREQUAL Android\); STREQUAL AndroidDISABLED\);g' swift-corelibs-foundation/Sources/Foundation/CMakeLists.txt



#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$MY_DIR"/../../..

HELPER="$LINEAGE_ROOT"/vendor/lineage/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper for common device
setup_vendor "$DEVICE_COMMON" "$VENDOR" "$LINEAGE_ROOT" true "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files-qc.txt "$SRC" "$SECTION"
extract "$MY_DIR"/proprietary-files-qc-perf.txt "$SRC" "$SECTION"

if [ -s "$MY_DIR"/../$DEVICE/proprietary-files.txt ]; then
    # Reinitialize the helper for device
    setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" false "$CLEAN_VENDOR"

    extract "$MY_DIR"/../$DEVICE/proprietary-files.txt "$SRC" "$SECTION"
fi

function fix_camera_etc_path () {
    sed -i \
        's/\/system\/etc\//\/vendor\/etc\//g' \
        "$LINEAGE_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary/"$1"
}

fix_camera_etc_path vendor/lib/libmmcamera_imglib.so
fix_camera_etc_path vendor/lib/libmmcamera_interface.so

function fix_radio_framework_path () {
    sed -i \
        's/\/system\/framework\//\/vendor\/framework\//g' \
        "$LINEAGE_ROOT"/vendor/"$VENDOR"/"$DEVICE_COMMON"/proprietary/"$1"
}

fix_radio_framework_path vendor/etc/permissions/embms.xml
fix_radio_framework_path vendor/etc/permissions/qcnvitems.xml
fix_radio_framework_path vendor/etc/permissions/qcrilhook.xml
fix_radio_framework_path vendor/etc/permissions/telephonyservice.xml

"$MY_DIR"/setup-makefiles.sh

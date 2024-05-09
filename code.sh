#!/bin/sh -x

# It will be run with two args: buildroot spec
BUILDROOT="$1"
SPEC="$2"

PRODUCT=code
PRODUCTCUR=vscode
PRODUCTDIR=/opt/$PRODUCT

. $(dirname $0)/common.sh

move_to_opt

# add_electron_deps

fix_desktop_file /usr/share/code/code

rm $BUILDROOT/usr/bin/code
add_bin_link_command $PRODUCT $PRODUCTDIR/bin/code
add_bin_link_command $PRODUCTCUR $PRODUCTDIR/bin/code

subst "s|^Group:.*|Group: Development/Tools|" $SPEC

########################

electron_version=$(strings "$BUILDROOT/$PRODUCTDIR/code" | grep "Electron v" | awk '{print $2}' | cut -d'v' -f2 | cut -d'.' -f1)
add_unirequires "electron$electron_version"

remove="""
chrome_100_percent.pak
chrome_200_percent.pak
chrome_crashpad_handler
chrome-sandbox
icudtl.dat
libEGL.so
libffmpeg.so
libGLESv2.so
libvk_swiftshader.so
libvulkan.so.1
LICENSES.chromium.html
locales
resources.pak
snapshot_blob.bin
v8_context_snapshot.bin
vk_swiftshader_icd.json
"""

for item in "$BUILDROOT/$PRODUCTDIR"/*; do
    base_item=$(basename "$item")
    if echo "$remove" | grep -qxE "$base_item"; then
        relative_item="${PRODUCTDIR}/${base_item}"
        if [ -d "$item" ]; then
            remove_dir "$relative_item"
        elif [ -f "$item" ]; then
            remove_file "$relative_item"
        fi
    fi
done

remove_file "${PRODUCTDIR}/code"

subst '1s|#!/usr/bin/env sh|#!/usr/bin/env bash|' "$BUILDROOT/$PRODUCTDIR/bin/code"
subst "s|ELECTRON=\\\".*\\\"|ELECTRON=\\\"/usr/bin/electron$electron_version\\\"|" "$BUILDROOT/$PRODUCTDIR/bin/code"
subst 's|\(ELECTRON_RUN_AS_NODE=1 "\$ELECTRON" "\$CLI" \)\("\$@"\)|\1--app="\$VSCODE_PATH/resources/app" \2 2> >(grep -v "is not in the list of known options, but still passed" >2)|' "$BUILDROOT/$PRODUCTDIR/bin/code"

#!/bin/bash
set -xe

version=${6-7}
girdir=$(pkg-config libmutter-$version --variable=girdir)

cd $(dirname $0)

for lib in cogl clutter meta; do
    libversion=$lib-$version
    girname=${libversion^}
    vapiname=mutter-$libversion
    vapiname=${vapiname/mutter-meta/libmutter}
    custom_vapi=""

    if [ -f "$vapiname-custom.vala" ]; then
        custom_vapi="$vapiname-custom.vala"
    fi

    vapigen --library $vapiname $girdir/$girname.gir \
            --girdir . -d . --metadatadir . --vapidir . \
            --girdir $girdir/ $custom_vapi
done

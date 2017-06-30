#!/bin/sh

VERSIONS="3.18 3.20"

for v in $VERSIONS; do

    printf "Building theme for %s, Normal\n" $v
    sassc -t compressed "$v/sass/theme.scss" "$v/theme.css"
    if [[ $? -eq 0 ]]; then
        printf "Succeeded.\n"
    else
        printf "Failed.\n"
        exit 1
    fi

    printf "Building theme for %s, High Contrast\n" $v
    sassc -t compressed "$v/sass/theme_hc.scss" "$v/theme_hc.css"
    if [[ $? -eq 0 ]]; then
        printf "Succeeded.\n"
    else
        printf "Failed.\n"
        exit 1
    fi

done

exit 0

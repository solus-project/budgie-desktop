#!/bin/bash

function do_gettext()
{
    xgettext --package-name=budgie-desktop --package-version=10.3.1 $* --default-domain=budgie-desktop --join-existing --from-code=UTF-8
}

function do_intltool()
{
    intltool-extract --type=$1 $2
}

rm budgie-desktop.po -f
touch budgie-desktop.po

for file in `find src -name "*.c" -or -name "*.vala" -not -path '*/gvc/*'`; do
    if [[ `grep -F "_(\"" $file` ]]; then
        do_gettext $file --add-comments
    fi
done

for file in `find src -name "*.ui"`; do
    if [[ `grep -F "translatable=\"yes\"" $file` ]]; then
        do_intltool gettext/glade $file
        do_gettext ${file}.h --add-comments --keyword=N_:1
        rm $file.h
    fi
done

for file in `find src -name "*.in"`; do
    if [[ `grep -E "^_*" $file` ]]; then
        do_intltool gettext/keys $file
        do_gettext ${file}.h --add-comments --keyword=N_:1
        rm $file.h
    fi
done

mv budgie-desktop.po po/budgie-desktop.pot

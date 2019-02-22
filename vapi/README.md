Refreshing vapis
--------------

To refresh the Polkit vapi files:

    vapigen --library polkit-gobject-1 /usr/share/gir-1.0/Polkit-1.0.gir --pkg gio-unix-2.0
    vapigen --library polkit-agent-1 /usr/share/gir-1.0/PolkitAgent-1.0.gir --pkg gio-unix-2.0 --pkg polkit-gobject-1 --girdir=. --vapidir=.

Then have fun un-mangling it to support vala async syntax

For mutter (and shipped cogl and clutter), something like:

vapigen --library mutter-clutter-4 mutter-clutter-4-custom.vala /usr/lib/x86_64-linux-gnu/mutter-4/Clutter-4.gir --girdir /usr/lib/x86_64-linux-gnu/mutter-4/ -d . --girdir . --vapidir . --metadatadir . --girdir /usr/lib/x86_64-linux-gnu/mutter-4/

vapigen --library mutter-cogl-4 mutter-cogl-4-custom.vala /usr/lib/x86_64-linux-gnu/mutter-4/Cogl-4.gir --girdir /usr/lib/x86_64-linux-gnu/mutter-4/ -d . --girdir . --vapidir . --metadatadir . --girdir /usr/lib/x86_64-linux-gnu/mutter-4/

vapigen --library libmutter-cogl-4 /usr/lib/x86_64-linux-gnu/mutter-4/Cogl-4.gir --girdir /usr/lib/x86_64-linux-gnu/mutter-4/ -d . --girdir . --vapidir . --metadatadir . --girdir /usr/lib/x86_64-linux-gnu/mutter-4/

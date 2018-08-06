Refreshing vapis
--------------

To refresh the Polkit vapi files:

    vapigen --library polkit-gobject-1 /usr/share/gir-1.0/Polkit-1.0.gir --pkg gio-unix-2.0
    vapigen --library polkit-agent-1 /usr/share/gir-1.0/PolkitAgent-1.0.gir --pkg gio-unix-2.0 --pkg polkit-gobject-1 --girdir=. --vapidir=.

Then have fun un-mangling it to support vala async syntax

For mutter, something like:

vapigen --library libmutter-3 /usr/lib/x86_64-linux-gnu/mutter/Meta-3.gir --girdir /usr/lib/x86_64-linux-gnu/mutter/ -d . --pkg cairo --pkg gdk-3.0 --pkg gdk-pixbuf-2.0 --pkg gtk+-3.0 --pkg x11 --pkg json-glib-1.0 --girdir . --vapidir . --metadatadir . --girdir /usr/lib/x86_64-linux-gnu/mutter/

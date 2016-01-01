Refreshing vapis
--------------

To refresh the Polkit vapi files:

    vapigen --library polkit-gobject-1 /usr/share/gir-1.0/Polkit-1.0.gir --pkg gio-unix-2.0
    vapigen --library polkit-agent-1 /usr/share/gir-1.0/PolkitAgent-1.0.gir --pkg gio-unix-2.0 --pkg polkit-gobject-1 --girdir=. --vapidir=.

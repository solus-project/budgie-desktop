arc-desktop
-----------

The Arc Desktop is the successor to the Budgie Desktop, with a focus
on modern style and function.

Note that this work will be merged *back* into the Budgie Desktop
repo on GitHub upon completion - the name-change is SOLELY to make
it parallel installable and help me with debugging.

License
=======

arc-desktop is available under the terms of the GPL-2.0 license

Building
========

arc-desktop has a number of build dependencies that must be present
before attempting configuration. The names are different depending on
distribution, so the pkg-config names, and the names within the Solus
Operating System, are given:

    - gobject-2.0 >= 2.44.0
    - gio-2.0 >= 2.44.0
    - gtk+-3.0 >= 3.16.0
    - gio-unix-2.0 >= 2.44.0
    - uuid
    - libpeas-gtk-1.0 >= 1.8.0
    - libgnome-menu-3.0 >= 3.10.1
    - gobject-introspection-1.0 >= 1.44.0

And:

    - vala >= 0.28

To install these on Solus::

    sudo eopkg it glib2-devel libgtk-3-devel libpeas-devel gobject-introspection-devel vala libgnome-menus-devel
    sudo eopkg it -c system.devel

Clone the repository::

    git clone https://github.com/solus-project/arc-desktop.git

Now build it (replace -j5 with your core count +1) ::

    cd arc-desktop
    ./autogen.sh --prefix=/usr
    make -j5
    sudo make install

Theming
=======

Please look at `./data/default.css` to override aspects of the default
theming.

Alternatively, you may invoke the panel with the GTK Inspector to
analyse the structure::

    arc-panel --gtk-debug=interactive --replace

If you are validating changes from a git clone, then::

    ./panel/arc-panel --gtk-debug=interactive --replace

Note that for local changes, GSettings schemas and applets are expected
to be installed first with `make install`.

Note that it is intentional for the toplevel `ArcPanel` object to
be transparent, as it contains the `ArcMainPanel` and `ArcShadowBlock`
within a singular window.

Testing
=======

As and when new features are implemented - it can be helpful to reset
the configuration to the defaults to ensure everything is still working
ok. To reset the entire configuration tree, issue::

    dconf reset -f /com/solus-project/arc-panel/  

Known Issues
============

Currently the GtkPopover can *randomly* glitch when the panel is at the
bottom of the screen. It is expected to be fixed in a later commit, however
let's be fair, it does kinda look better up top.

Authors
=======

Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>

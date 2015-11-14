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

Theming
=======

Please look at ./data/default.css to override aspects of the default
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

Authors
=======

Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>

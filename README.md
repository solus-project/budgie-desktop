budgie-desktop
==============

The Budgie Desktop a modern desktop designed to keep out the way of the user. It features heavy integration with the GNOME stack in order for an enhanced experience.

Budgie is **not currently accepting** any contributions that **add** significant Vala code to the Budgie codebase. Please see [this bug](https://github.com/solus-project/budgie-desktop/issues/501) for further details. Our next steps involve cleaning up the code and porting to C for more control, flexibility, and ultimately a more stable and established desktop.

Budgie Desktop is a [Solus project](https://solus-project.com/).

![logo](https://build.solus-project.com/logo.png)

Building
--------

budgie-desktop has a number of build dependencies that must be present
before attempting configuration. The names are different depending on
distribution, so the pkg-config names, and the names within Solus, are
given:

- accountsservice >= 0.6
- gio-2.0 >= 2.44.0
- gio-unix-2.0 >= 2.44.0
- gnome-bluetooth-1.0 >= 3.16.0
- gnome-desktop-3.0 >= 3.18.0
- gobject-2.0 >= 2.44.0
- gobject-introspection-1.0 >= 1.44.0
- gtk+-3.0 >= 3.16.0
- ibus-1.0 >= 1.5.11
- libgnome-menu-3.0 >= 3.10.1
- libpeas-gtk-1.0 >= 1.8.0
- libpulse >= 2
- libwnck >= 3.14.0
- mutter >= 3.18.0
- polkit-agent-1 >= 0.110
- polkit-gobject-1 >= 0.110
- upower-glib >= 0.9.20
- uuid

And:

- vala >= 0.28
- gtk-doc (For documentation building from git only)

To install these on Solus:

```bash
sudo eopkg it glib2-devel libgtk-3-devel gtk-doc libpeas-devel gobject-introspection-devel util-linux-devel pulseaudio-devel libgnome-menus-devel libgnome-desktop-devel gnome-bluetooth-devel mutter-devel polkit-devel libwnck-devel upower-devel accountsservice-devel ibus-devel vala
sudo eopkg it -c system.devel
```

Clone the repository:

```bash
git clone https://github.com/solus-project/budgie-desktop.git
```

Now build it:
```bash
cd budgie-desktop
./autogen.sh --prefix=/usr
make -j$(($(getconf _NPROCESSORS_ONLN)+1))
sudo make install
```

Theming
------

Please look at `./theme/3.20/sass` and `./theme/3.18/sass` to override aspects of the default theming. Budgie theming is created using SASS, and the CSS files shipped are minified. Check out `./theme/README.md` for more information on regenerating the theme from SASS.

Alternatively, you may invoke the panel with the GTK Inspector to analyse the structure:

```bash
budgie-panel --gtk-debug=interactive --replace
```

If you are validating changes from a git clone, then:

```bash
./src/panel/budgie-panel --gtk-debug=interactive --replace
```

Note that for local changes, GSettings schemas and applets are expected to be installed first with `make install`.

Note that it is intentional for the toplevel `BudgiePanel` object to be transparent, as it contains the `BudgieMainPanel` and `BudgieShadowBlock` within a singular window.

Also note that by default Budgie overrides all theming with the stylesheet, and in future we'll also make it possible for you to set a custom theme. To do this, test your changes in tree first. When you have a reasonable theme put together, please open an issue and we'll enable setting of a custom theme (no point until they exist.)

Testing
------

As and when new features are implemented - it can be helpful to reset the configuration to the defaults to ensure everything is still working ok. To reset the entire configuration tree, issue:

```bash
budgie-panel --reset --replace &
```

Distro Integration
------------------

In order to override the default panel layout, you should provide your own  `panel.ini` in the system-wide vendor directory:

```bash
$(datadir)/budgie-desktop/panel.ini`
```

Note that the system configuration directory is the domain of the system administrator, and you should not ship a `panel.ini` in this location. This location is:

```bash
$(sysconfdir)/budgie-desktop/panel.ini
```

This is to allow users to make global layout changes for all users on the system. Please see `./data/panel.ini` for a reference.

To override the specific GSettings, you should implement gschema overrides. For an example
of this, please see [our branding package](https://github.com/solus-project/budgie-desktop-branding).

License
-------

budgie-desktop is available under a split license model. This enables
developers to link against the libraries of budgie-desktop without
affecting their choice of license and distribution.

The shared libraries are available under the terms of the LGPL-2.1,
allowing developers to link against the API without any issue, and
to use all exposed APIs without affecting their project license.

The remainder of the project (i.e. installed binaries) is available
under the terms of the GPL 2.0 license. This is clarified in the headers
of each source file.

Authors
=======

Copyright © 2014-2016 Ikey Doherty, Solus Project & Others

Also see our [contributors graph](https://github.com/solus-project/budgie-desktop/graphs/contributors)!

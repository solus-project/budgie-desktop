budgie-desktop
==============

The Budgie Desktop a modern desktop designed to keep out the way of the user. It features heavy integration with the GNOME stack in order for an enhanced experience.

![main_desktop](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/MainDesktop.png)

![logo](https://solus-project.com/imgs/budgie-small.png)

IRC: #budgie-desktop-dev on irc.freenode.net

Components
==========

Budgie Desktop consists of a number of components to provide a more complete desktop experience.

Main Menu
---------

The main Budgie menu provides a quick and easy to use menu, suitable for both mouse and keyboard driven users. Features type-as-you-search and category based filtering.

![main_menu](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/MainMenu.png)

End Session Dialog
------------------

The session dialog provides the usual shutdown, logout, options which can be activated using the User Indicator applet.

![end_session_dialog](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/EndSession.png)

Run Dialog
----------

The run dialog provides the means to quickly find an application in a popup window. This window by default is activated with the `ALT+F2` keyboard shortcut, providing keyboard driven launcher facilities.

![run_dialog](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/RunDialog.png)

Raven
------

Raven provides an all-in-one center for the Budgie Desktop. With built in applets, a notification center to archive missed notifications, and a settings view to control all elements of the Budgie Desktop, it's truly the one stop shop.

![raven](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/Raven.png) ![raven_settings](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/Raven_Settings.png)

Notifications
-------------

Budgie Desktop supports the freedesktop notifications specification, enabling applications to send visual alerts to the user. These notifications support actions, icons as well as passive modes.

![notification](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/Notification.png)

To ensure the user doesn't miss the notification, it's automatically archived into the Raven Notification view for quick and easy access.

![raven_mpris](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/ArchivedNotification.png)

Media Integration
------------------

As well as supporting the usual level of media integration you'd expect, such as media player controls on notifications, support for cover artwork, and global media key support for keyboards, Raven supports all MPRIS compliant media players.

When one of these players are running, such as VLC, Rhythmbox or even Spotify, an MPRIS controller is made available in Raven for quick and simple control of the player, as well as data on the current media selection.

![raven_mpris](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/Raven_Mpris.png)

PolicyKit integration
---------------------

The `budgie-polkit-dialog` provides a PolicyKit agent for the session, ensuring a cohesive and integrated experience whilst authenticating for actions on modern Linux desktop systems.

![budgie_polkit](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/Polkit.png)

Building
--------

budgie-desktop has a number of build dependencies that must be present
before attempting configuration. The names are different depending on
distribution, so the pkg-config names, and the names within Solus, are
given:

- accountsservice >= 0.6
- gio-2.0 >= 2.46.0
- gio-unix-2.0 >= 2.46.0
- gnome-bluetooth-1.0 >= 3.18.0
- gnome-desktop-3.0 >= 3.18.0
- gobject-2.0 >= 2.44.0
- gobject-introspection-1.0 >= 1.44.0
- gtk+-3.0 >= 3.16.0
- ibus-1.0 >= 1.5.11
- libgnome-menu-3.0 >= 3.10.1
- libpeas-gtk-1.0 >= 1.8.0
- libpulse >= 2
- libwnck >= 3.14.0
- meson
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
sudo eopkg it glib2-devel libgtk-3-devel gtk-doc libpeas-devel gobject-introspection-devel util-linux-devel pulseaudio-devel libgnome-menus-devel libgnome-desktop-devel gnome-bluetooth-devel mutter-devel polkit-devel libwnck-devel upower-devel accountsservice-devel ibus-devel vala meson
sudo eopkg it -c system.devel
```

Clone the repository:

```bash
git clone https://github.com/budgie-desktop/budgie-desktop.git
cd budgie-desktop
git submodule init
git submodule update
```

Now build it:
```bash
cd budgie-desktop
meson build --prefix=/usr --sysconfdir=/etc
cd build
ninja -j$(($(getconf _NPROCESSORS_ONLN)+1))
sudo ninja install
```

**Note**: When building a distro package, please ensure you use:

```
meson build --prefix=/usr --sysconfdir=/etc --buildtype plain
```

This ensures your distro flags are respected.

Theming
------

Please look at `./src//3.20/sass` and `./src/theme/3.18/sass` to override aspects of the default theming. Budgie theming is created using SASS, and the CSS files shipped are minified. Check out `./src/theme/README.md` for more information on regenerating the theme from SASS.

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

Copyright © 2014-2017 Budgie Desktop Developers

Budgie Desktop is primarily authored by the [Solus](https://solus-project.com) project which oversees
the development and leadership of the Budgie Desktop to ensure the delivery of a distribution agnostic
and open source Desktop Environment for everyone to enjoy and contribute to.

See our [contributors graph](https://github.com/solus-project/budgie-desktop/graphs/contributors)!

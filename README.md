budgie-desktop
==============

The Budgie Desktop a modern desktop designed to keep out the way of the user. It features heavy integration with the GNOME stack in order for an enhanced experience.

![main_desktop](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/MainDesktop.png)

![logo](https://solus-project.com/imgs/budgie-small.png)

IRC: `#budgie-desktop-dev` / `#Solus-Dev` on irc.freenode.net

`budgie-desktop` is a [Solus project](https://solus-project.com/)

![logo](https://build.solus-project.com/logo.png)

Re-merge into the Solus Project
===============================

As of May 20th, 2018, the Budgie Desktop project has been merged back into the Solus Project umbrella, making it a distinct Solus project once more.
Contributions from all distributions, projects and individuals are welcome provided they add value and are of sufficient quality. We're happy to discuss
test pull requests, which should be appropriately labeled as being `Request For Comment` `[RFC]`.

Please note that we will NOT accept pull requests to add Pythonic applets. Any applets should be written in either C or Vala.
Pull requests modifying any C source code should ensure to stick with code compliance. Run `./update_format.sh` to ensure coding
standards are respected. (Requires `clang-format` and `misspell`)

This decision has been made after a long time having Budgie Desktop being a separate project, which to this date has only repeatedly harmed the Budgie Desktop
project due to other projects specifically looking to add **vendor specific value-add** and ensuring it is never upstream within this project. As such the
project is now officially back under the stewardship of Solus (original authors) and will be developed with our goals in mind, as it once was. It should also
be observed that Budgie has been an incredibly quiet project for almost the entire duration of the project being split out from Solus. This will now be remedied
as we merge back into Solus, and all previous decisions will now be re-evaluated (Qt? Wayland? gtk4? etc).

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

Testing
------

As and when new features are implemented - it can be helpful to reset the configuration to the defaults to ensure everything is still working ok. To reset the entire configuration tree, issue:

```bash
budgie-panel --reset --replace &
```


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

Copyright © 2014-2018 Budgie Desktop Developers

See our [contributors graph](https://github.com/solus-project/budgie-desktop/graphs/contributors)!

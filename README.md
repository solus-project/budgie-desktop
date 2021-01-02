![main_desktop](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/MainDesktop.png)

# Budgie Desktop

![GitHub release (latest by date)](https://img.shields.io/github/v/release/solus-project/budgie-desktop)
[![Translate into your language!](https://img.shields.io/badge/help%20translate-Weblate-4AB)](https://translate.getsol.us/engage/budgie-desktop/)
[![Translation status](https://translate.getsol.us/widgets/budgie-desktop/-/svg-badge.svg)](https://translate.getsol.us/engage/budgie-desktop/)
![#budgie-desktop-dev on Freenode](https://img.shields.io/badge/freenode-%23budgie--desktop--dev-4AF)
![#solus-dev on Freenode](https://img.shields.io/badge/freenode-%23solus--dev-28C)

The Budgie Desktop is a feature-rich, modern desktop designed to keep out the way of the user.

![Budgie logo](https://getsol.us/imgs/budgie-small.png)

`budgie-desktop` is a [Solus project.](https://getsol.us/)

![Solus logo](https://build.getsol.us/logo.png)

## Project Updates

### Announcement for Budgie 11

In our [2019: To Venture Ahead](https://getsol.us/2019/01/14/2019-to-venture-ahead/) blog post, we formally announced the return of Budgie development in April, with planned alpha and beta builds later in the year.

### Move to GTK4

In our [In Full Sail](https://getsol.us/2018/10/27/in-full-sail/) blog post, we announced that Budgie 11 will be written in C and GTK4. The plan is to further support Vala for Budgie plugins.

In addition to this, this repository will **not** be used for Budgie beyond 10.5 series, as various changes in leadership (departure of project founder) without a complete transition has resulted in this repository (and its org) not being under the complete ownership of the Solus Core Team. Future development will happen across both the Solus [Development Tracker](https://dev.getsol.us) as well as our [GetSolus](https://github.com/getsolus) organization.

### Re-merge into the Solus Project

On May 20th 2018, the Budgie Desktop project merged back into the Solus Project umbrella, making it a distinct Solus project once more.
Contributions from all distributions, projects and individuals are welcome provided they add value and are of sufficient quality. We're happy to discuss
test pull requests, which should be appropriately labeled as being `Request For Comment` `[RFC]`.

Please note that we will **not** accept pull requests to add Pythonic applets. Any applets should be written in either C or Vala. Pull requests modifying any C source code should ensure to stick with code compliance. Run `./update_format.sh` to ensure coding standards are respected. (Requires `clang-format` and `misspell`)

This decision has been made after a long time having Budgie Desktop being a separate project, which to this date has only repeatedly harmed the Budgie Desktop project due to other projects specifically looking to add **vendor specific value-add** and ensuring it is never upstream within this project. As such the project is now officially back under the stewardship of Solus (original authors) and will be developed with our goals in mind, as it once was. It should also be observed that Budgie had been an incredibly quiet project for almost the entire duration of the project being split out from Solus, something which we wished to remedy.

## Components

Budgie Desktop consists of a number of components to provide a more complete desktop experience.

### Budgie Menu

The main Budgie menu provides a quick and easy to use menu, suitable for both mouse and keyboard driven users. Features search-as-you-type and category based filtering.

![main_menu](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/MainMenu.png)

### Raven

Raven provides an all-in-one center for accessing your calendar, controlling sound output and input (including per-app volume control), media playback and more. As well as supporting the usual level of media integration you'd expect, such as media player controls on notifications, support for cover artwork, and global media key support for keyboards, Raven supports all MPRIS compliant media players.

When one of these players are running, such as VLC, Rhythmbox or even Spotify, an MPRIS controller is made available in Raven for quick and simple control of the player, as well as data on the current media selection.

Raven also enables you to access missed notifications, with the ability to swipe away individual notifications, app notifications, and all notifications.

![raven](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/Raven.png)

#### Notifications

Budgie Desktop supports the freedesktop notifications specification, enabling applications to send visual alerts to the user. These notifications support actions, icons as well as passive modes.

![notification](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/Notification.png)

### Run Dialog

The Budgie Run Dialog provides the means to quickly find an application in a popup window. This window by default is activated with the `ALT+F2` keyboard shortcut, providing keyboard driven launcher facilities.

![run_dialog](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/RunDialog.png)

### Other

#### End Session Dialog

The session dialog provides the usual shutdown, logout, options which can be activated using the User Indicator applet.

![end_session_dialog](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/EndSession.png)

#### PolicyKit integration

The `budgie-polkit-dialog` provides a PolicyKit agent for the session, ensuring a cohesive and integrated experience whilst authenticating for actions on modern Linux desktop systems.

![budgie_polkit](https://github.com/solus-project/budgie-desktop/raw/master/.github/screenshots/Polkit.png)

## Testing

As and when new features are implemented - it can be helpful to reset the configuration to the defaults to ensure everything is still working ok. To reset the entire configuration tree, issue:

```bash
budgie-panel --reset --replace &!
```

## License

budgie-desktop is available under a split license model. This enables developers to link against the libraries of budgie-desktop without affecting their choice of license and distribution.

The shared libraries are available under the terms of the LGPL-2.1, allowing developers to link against the API without any issue, and to use all exposed APIs without affecting their project license.

The remainder of the project (i.e. installed binaries) is available under the terms of the GPL 2.0 license. This is clarified in the headers of each source file.

## Authors

Copyright © 2014-2021 Budgie Desktop Developers

See our [contributors graph](https://github.com/solus-project/budgie-desktop/graphs/contributors)!

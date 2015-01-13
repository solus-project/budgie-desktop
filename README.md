Budgie Desktop
---

Simple, yet elegant desktop

![budgie_screenshot](https://raw.githubusercontent.com/evolve-os/budgie-desktop/master/Screenshot.png)


                     _              __           _    
                    | |            / _|         | |   
         _ __   ___ | |_    __ _  | |_ ___  _ __| | __
        | '_ \ / _ \| __|  / _` | |  _/ _ \| '__| |/ /
        | | | | (_) | |_  | (_| | | || (_) | |  |   < 
        |_| |_|\___/ \__|  \__,_| |_| \___/|_|  |_|\_\


What's that? Not a fork.  Exactly.

*Note:*
Budgie Desktop integrates with the GNOME stack, and as such requires
certain components to operate correctly. 

*TODO:*
 * Start adding support for translations
 * Add some form of notification system ✓
 * Add appindicator to eventually replace new tray
 * Add sound control (PulseAudio) and support media keys  ✓
 * Allow adding launchers directly to panel ✓
 * Rewrite in Vala! (mostly done, panel is complete)
 * Enable customisation of panel layout, etc. ✓
 * Add dynamic editor for panel layout ✓
 * Add support for GNOME Panel theming ✓
 * Dynamically resize applets according to panel size ✓

*Implementation note:*

All elements are written entirely from scratch, using GTK and either Vala
or C. A rewrite took place to lower the barrier of entry for new contributors
and to ease maintainence.
A sole exception is the wm/plugin.c file, which is a slight modification of the
default Mutter plugin.


*budgie-wm:*

libmutter based window manager. Uses a modified default plugin to use
better default animations, support wallpaper, etc.

*budgie-panel:*

Plugin based panel. Users/developers can provide their own custom applets,
which are fully integrated. They can be moved, added, removed again, and
even broken!

*budgie-session:*

Session management binary, keeps stuff running. Supports some really uninteresting
things like GSettings start conditions and desktop environment based OnlyStartIn
entries.

    budgie-session --logout

*budgie-run-dialog:*

A utility that enables you to quickly launch applications by their executable
path without having to use the terminal or menu. Normally a program starts
because of this.

*Dependencies:*

 * libpulse
 * libpulse-mainloop-glib
 * GTK3 (>= 3.10.1)
 * upower-glib (>= 0.9.20)
 * libgnome-menu (>= 3.10.1)
 * libwnck (>= 3.4.7)
 * libmutter (>= 3.10.1)
 * GLib (>= 2.38.0)
 * gee-0.8 (not gee-1.0!)
 * libpeas-1.0
 * valac

Ubuntu users:
It is highly likely your theme or Ubuntu setup can affect the usability
of budgie-panel.

Please also note that currently, 14.04 is unsupported after commit ce3cae9b5c04f7ed14ede1fea0f992c9c83536f0
Love nor money could not make the Ubuntu-specific issues go away.

Ambiance is *NOT SUPPORTED*

Do not use the Ubuntu GTK3 modifications or plugins, because they break
Budgie. I will not support them. (overlay scrollbars and such)

Lastly, always set --prefix=/usr when using autogen.sh, or configure, otherwise you
won't be able to start the desktop on most distros

Author
===
 * Ikey Doherty <ikey.doherty@gmail.com>

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
 * Optimize menu (migrate from GtkListBox)
 * Add some form of notification system
 * Add network control (ConnMan & Network Manager)
 * Add sound control (PulseAudio) and support media keys (partly done) ✓
 * Allow adding launchers directly to panel
 * Allow pinning menu launchers to panel (see above point)
 * Rewrite in Vala! (mostly done, panel is complete)
 * Enable customisation of panel layout, etc. ✓
 * Add dynamic editor for panel layout
 * Add support for GNOME Panel theming
 * Dynamically resize applets according to panel size

*Implementation note:*

All elements are written entirely from scratch, using GTK and either Vala
or C. A rewrite took place to lower the barrier of entry for new contributors
and to ease maintainence.
A sole exception is the wm/plugin.c file, which is a slight modification of the
default Mutter plugin.

The entire project will be rewritten in Vala at some point, with over 58%
of it already complete at the time of writing this document.

*budgie-wm:*

libmutter based window manager. Uses a modified default plugin to use
better default animations, support wallpaper, etc.

*budgie-panel:*

GTK3 "panel" application. Supports task switching, has a menu, a simple
"clock", and a battery indicator. Customisable applet support coming soon.

*budgie-session:*

Tiny C "session" program, simply starts the aforementioned programs and
tries not to die. Has simple facility to stop the session via the command:

    budgie-session --logout

*budgie-run-dialog:*

A utility that enables you to quickly launch applications by their executable
path without having to use the terminal or menu

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

Do not use the Ubuntu GTK3 modifications or plugins, because they break
Budgie. I will not support them. (overlay scrollbars and such)

Author
===
 * Ikey Doherty <ikey.doherty@gmail.com>

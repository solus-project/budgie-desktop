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
 * Start adding support for translations (v9)
 * Redo notifications (v9)
 * Add appindicator to eventually replace new tray (v9)
 * Finish WM migration to 3.14
 * Redo menu and panel using GtkFlowBox and such wonders. (poss v10)
 * Introduce menu pagination (v9)
 * Panel colours (v9)
 * Wayland support, complete it, and validate on Intel NUC (v9)
 * Drop many deps. (v9)
 


*Implementation note:*

All elements are written entirely from scratch, using GTK and either Vala
or C. A rewrite took place to lower the barrier of entry for new contributors
and to ease maintainence.
(Exception: Parts of the default mutter plugin currently reside in wm/legacy.*)

*budgie-wm:*

libmutter based window manager.

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
 * GTK3 (>= 3.12.0)
 * upower-glib (>= 0.9.20)
 * libgnome-menu (>= 3.10.1)
 * libwnck (>= 3.4.7)
 * libmutter (>= 3.14.0)
 * GLib (>= 2.40.0)
 * gee-0.8 (not gee-1.0!)
 * libpeas-1.0
 * valac

Ubuntu users:
-----
It is highly likely your theme or Ubuntu setup can affect the usability
of budgie-panel.

As of commit ce3cae9b5c04f7ed14ede1fea0f992c9c83536f0 Budgie is unusable on
Ubuntu 14.04. This is because Ubuntu 14.04 is using Vala 0.22.1, which does
not correctly export dbus proxies in dynamic type modules.

 * Related bug:  https://bugzilla.gnome.org/show_bug.cgi?id=711423
 * Patch: https://mail.gnome.org/archives/commits-list/2013-November/msg00814.html

Currently this means we cannot provide updates, as a minimum Vala version of 0.23.1
is required to correctly build Budgie. It currently means we'll have to rewrite
parts of Budgie using dbus interfaces into C.

Ambiance is *NOT SUPPORTED*

Do not use the Ubuntu GTK3 modifications or plugins, because they break
Budgie. I will not support them. (overlay scrollbars and such)

Please ensure you use *gnome-settings-daemon*, not an Ubuntu fork, or Budgie
will not function correctly.
Please also ensure you use *gnome-control-center*, not an Ubuntu fork, for the
same reason.

Love nor money cannot make these Ubuntu-specific issues go away. Consequently,
given how large the README section is for Ubuntu, support is limited, to say
the least.


Lastly, always set --prefix=/usr when using autogen.sh, or configure, otherwise you
won't be able to start the desktop on most distros

Author
===
 * Ikey Doherty <ikey.doherty@gmail.com>

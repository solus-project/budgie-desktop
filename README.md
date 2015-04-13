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
 * Add appindicator to eventually replace new tray (v9) (see below)
 * Finish WM migration to 3.14
 * Redo menu and panel using GtkFlowBox and such wonders. (poss v10)
 * Introduce menu pagination (v9)
 * Panel colours (v9)
 * Wayland support, complete it, and validate on Intel NUC (v9)
 * Drop many deps. (v9)
 

The tray will still remain an option, but it won't be the *default*
implementation in many cases. This is mainly due to the extremely
buggy nature of xembed. Remember our policy (unless we really don't
have a choice, like moving to a non-buggy Mutter, or dropping Ubuntu
due to very very old components) - is to retain choice, not remove it.

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
 * GTK3 (>= 3.14.0)
 * upower-glib (>= 0.9.20)
 * libgnome-menu (>= 3.10.1)
 * libwnck (>= 3.4.7)
 * libmutter (>= 3.14.0)
 * GLib (>= 2.40.0)
 * gee-0.8 (not gee-1.0!)
 * libpeas-1.0
 * valac

Author
===
 * Ikey Doherty <ikey.doherty@gmail.com>

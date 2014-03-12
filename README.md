Budgie Desktop
---

Simple desktop using libmutter and a panel

                     _              __           _    
                    | |            / _|         | |   
         _ __   ___ | |_    __ _  | |_ ___  _ __| | __
        | '_ \ / _ \| __|  / _` | |  _/ _ \| '__| |/ /
        | | | | (_) | |_  | (_| | | || (_) | |  |   < 
        |_| |_|\___/ \__|  \__,_| |_| \___/|_|  |_|\_\


*Note:*
Budgie Desktop integrates with the GNOME stack, and as such requires
certain components to operate correctly. Your distribution should provide
an autostart file for gnome-settings-daemon in its package.

budgie-session will attempt to parse the file and launch it if it is
found, which is guessed to be living in:
    /etc/xdg/autostart/gnome-settings-daemon.desktop

If budgie-session cannot locate the file, gnome-settings-daemon will not
be launched, and dynamic settings for themes, etc, will not work until
it is launched.

*TODO:*
 * Ensure static size and position of panel
 * Fix weird glitches with widget/message area border rendering ✓
 * Start adding support for translations
 * Optimize menu (hack GdkPixbuf and GtkImage loading)
 * When GTK 3.12 is stable, use GtkPopover in place of BudgiePopover (for 3.12 systems only)
 * Add logout confirmation dialog ✓
 * Add some form of notification system
 * Add network control (ConnMan & Network Manager)
 * Add sound control (PulseAudio) and support media keys (partly done) ✓
 * Integrate with systemd to provide shutdown and reboot options ✓
 * Allow adding launchers directly to panel
 * Allow pinning menu launchers to panel (see above point)
 * Add some kind of polkit agent
 * Support Wayland (lack of wnck-style wayland interation = major issue)
 * Fix popover grab (clicking desktop doesn't make popover hide, etc.) ✓

*Implementation note:*

All elements are written entirely from scratch, using GTK and C. A sole
exception is the wm/plugin.c file, which is a slight modification of the
default Mutter plugin.

*budgie-wm:*

libmutter based window manager. Uses a modified default plugin to use
better default animations, support wallpaper, etc.

*budgie-panel:*

GTK3 C "panel" application. Supports task switching, has a menu, a simple
"clock", and a battery indicator.

*budgie-session:*

Tiny C "session" program, simply starts the aforementioned programs and
tries not to die. Has simple facility to stop the session via the command:

    budgie-session --logout


*Issues preventing Wayland compatibility:*

budgie-wm is currently based on libmutter, so naturally with 3.12 will
gain support to be a Wayland compositor. Right now, the reference wayland
compositor, Weston, has a few problems that will cause major headaches for
budgie:

 * Cannot determine own X and Y position (panel)
 * Cannot actually set X and Y (panel), so will hack Mutter to use gravity, private protocol
 * Wayland doesn't agree with things like wnck. So asking for the list of windows and events isn't
   possible, meaning you can't actually have a tasklist. Unless its in-process (Mutter/Weston/etc).
   Which I'm not going to support. So it'll have to be an XDG protocol or some such.

*Menu Notes:*

When started, the panel will use trivial amounts of RAM (in the region of
7MB). However, when you first open the menu, GTK actually loads the images.
This needs to be hacked a bit, as it delays the first open, and should be
done in an asynchronous manner. On my machine, 190 .desktop files in the
menu yields a total budgie-panel RAM use of ~44MB (including all elements
of the panel). This is largely due to the use of GdkPixbuf's

Author
===
 * Ikey Doherty <ikey.doherty@gmail.com>

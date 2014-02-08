Budgie Desktop
---

Simple desktop using Mutter and a panel

** NOTE: THIS IS NOT A FORK **

Note:
We currently use an ugly hack to make gnome-settings-daemon start
This will be altered soon, but it may be worth patching your build
to be accurate.

Override the following line in session/budgie-session.c:

    #define DESKTOP_SETTINGS "/usr/lib/gnome-settings-daemon-3.0/gnome-settings-daemon"


Author
===
 * Ikey Doherty <ikey.doherty@gmail.com>

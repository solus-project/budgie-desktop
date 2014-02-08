Budgie Desktop
---

Simple desktop using Mutter and a panel

** NOTE: THIS IS NOT A FORK **

Note:
Budgie Desktop integrates with the GNOME stack, and as such requires
certain components to operate correctly. Your distribution should provide
an autostart file for gnome-settings-daemon in its package.

budgie-session will attempt to parse the file and launch it if it is
found, which is guessed to be living in:
    /etc/xdg/autostart/gnome-settings-daemon.desktop

If budgie-session cannot locate the file, gnome-settings-daemon will not
be launched, and dynamic settings for themes, etc, will not work until
it is launched.


Author
===
 * Ikey Doherty <ikey.doherty@gmail.com>

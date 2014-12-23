/*
 * MprisWidget.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class MprisWidget : Gtk.Box
{
    DBusImpl impl;

    HashTable<string,ClientWidget> ifaces;

    public MprisWidget()
    {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 1);

        ifaces = new HashTable<string,ClientWidget>(str_hash, str_equal);

        Idle.add(()=> {
            setup_dbus();
            return false;
        });

        show_all();
    }

    /**
     * Add an interface handler/widget to known list and UI
     *
     * @param name DBUS name (object path)
     * @param iface The constructed MprisClient instance
     */
    void add_iface(string name, MprisClient iface)
    {
        ClientWidget widg = new ClientWidget(iface);
        widg.show_all();
        pack_start(widg, false, false, 0);
        ifaces.insert(name, widg);
    }

    /**
     * Destroy an interface handler and remove from UI
     *
     * @param name DBUS name to remove handler for
     */
    void destroy_iface(string name)
    {
        var widg = ifaces[name];
        if (widg  != null) {
            remove(widg);
            ifaces.remove(name);
        }
    }

    /**
     * Do basic dbus initialisation
     */
    public void setup_dbus()
    {
        try {
            impl = Bus.get_proxy_sync(BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");
            var names = impl.list_names();

            /* Search for existing players (launched prior to our start) */
            foreach (var name in names) {
                if (name.has_prefix("org.mpris.MediaPlayer2.")) {
                    var iface = new_iface(name);
                    if (iface != null) {
                        add_iface(name, iface);
                    }
                }
            }

            /* Also check for new mpris clients coming up while we're up */
            impl.name_owner_changed.connect((n,o,ne)=> {
                /* Separate.. */
                if (n.has_prefix("org.mpris.MediaPlayer2.")) {
                    if (o == "") {
                        var iface = new_iface(n);
                        if (iface != null) {
                            add_iface(n,iface);
                        }
                    } else {
                        Idle.add(()=> {
                            destroy_iface(n);
                            return false;
                        });
                    }
                }
            });
        } catch (Error e) {
            warning("Failed to initialise dbus: %s", e.message);
        }
    }
} // End class

/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
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

    int our_width = 250;

    public MprisWidget()
    {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 1);

        ifaces = new HashTable<string,ClientWidget>(str_hash, str_equal);

        setup_dbus.begin();

        size_allocate.connect(on_size_allocate);
        show_all();
    }

    void on_size_allocate()
    {
        int w = get_allocated_width();
        if (w > our_width) {
            our_width = w;
        }
    }

    /**
     * Add an interface handler/widget to known list and UI
     *
     * @param name DBUS name (object path)
     * @param iface The constructed MprisClient instance
     */
    void add_iface(string name, MprisClient iface)
    {
        ClientWidget widg = new ClientWidget(iface, our_width);
        widg.show_all();
        pack_start(widg, false, false, 0);
        ifaces.insert(name, widg);

        this.queue_draw();

        get_toplevel().queue_draw();
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
        this.queue_draw();
        get_toplevel().queue_draw();
    }

    void on_name_owner_changed(string? n, string? o, string? ne)
    {
        if (!n.has_prefix("org.mpris.MediaPlayer2.")) {
            return;
        }
        if (o == "") {
            new_iface.begin(n, (o,r) => {
                var iface = new_iface.end(r);
                if (iface != null) {
                    add_iface(n, iface);
                }
            });
        } else {
            Idle.add(()=> {
                destroy_iface(n);
                return false;
            });
        }
    }

    /**
     * Do basic dbus initialisation
     */
    public async void setup_dbus()
    {
        try {
            impl = yield Bus.get_proxy(BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");
            var names = yield impl.list_names();

            /* Search for existing players (launched prior to our start) */
            foreach (var name in names) {
                if (name.has_prefix("org.mpris.MediaPlayer2.")) {
                    var iface = yield new_iface(name);
                    if (iface != null) {
                        add_iface(name, iface);
                    }
                }
            }

            /* Also check for new mpris clients coming up while we're up */
            impl.name_owner_changed.connect(on_name_owner_changed);
        } catch (Error e) {
            warning("Failed to initialise dbus: %s", e.message);
        }
    }

} // End class

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */

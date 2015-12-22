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

namespace Arc {

public struct GsdAccel {
    string accelerator;
    uint flags;
}

[DBus (name = "org.gnome.Shell")]
public class ShellShim : GLib.Object
{

    HashTable<uint,string> grabs;
    HashTable<string,uint> watches;
    unowned Meta.Display? display;

    protected ShellShim(Arc.ArcWM? wm)
    {
        grabs = new HashTable<uint,string>(direct_hash, direct_equal);
        watches = new HashTable<string,uint>(str_hash, str_equal);

        display = wm.get_screen().get_display();
        display.accelerator_activated.connect(on_accelerator_activated);
    }

    private void on_accelerator_activated(uint action, uint device_id)
    {
        HashTable<string,Variant> params = new HashTable<string,Variant>(str_hash, str_equal);

        params.insert("device-id", device_id);
        params.insert("timestamp", new Variant.uint32(0));
        params.insert("action-mode", new Variant.uint32(0));

        this.accelerator_activated(action, params);
    }

    void on_disappeared(DBusConnection conn, string name)
    {
        unowned string val;
        unowned uint key;

        if (!watches.contains(name)) {
            return;
        }

        uint id = watches.lookup(name);
        Bus.unwatch_name(id);

        var iter = HashTableIter<uint,string>(grabs);
        while (iter.next(out key, out val)) {
            if (val != name) {
                continue;
            }
            display.ungrab_accelerator(key);
            grabs.remove(key);
        }
    }

    private uint _grab(string sender, string seq, uint flag)
    {
        var ret = display.grab_accelerator(seq);

        if (ret == Meta.KeyBindingAction.NONE) {
            return ret;
        }

        grabs.insert(ret, sender);

        if (!watches.contains(sender)) {
            var id = Bus.watch_name(BusType.SESSION, sender, BusNameWatcherFlags.NONE,
                null, on_disappeared);
            watches.insert(sender, id);
        }

        return ret;
    }

    void on_bus_acquired(DBusConnection conn)
    {
        try {
            conn.register_object("/org/gnome/Shell", this);
        } catch (Error e) {
            message("Unable to register ShellShim: %s", e.message);
        }
    }

    [DBus (visible = false)]
    public void serve()
    {
        Bus.own_name(BusType.SESSION, "org.gnome.Shell",
            BusNameOwnerFlags.ALLOW_REPLACEMENT|BusNameOwnerFlags.REPLACE,
            on_bus_acquired, null, null);
    }
    
    public uint GrabAccelerator(BusName sender, string accelerator, uint flags)
    {
        return _grab(sender, accelerator, flags);
    }
        
    public uint[] GrabAccelerators(BusName sender, GsdAccel[] accelerators)
    {
        uint[] t = { };
        foreach (var a in accelerators) {
            t += _grab(sender, a.accelerator, a.flags);
        }
        return t;
    }

    public bool ungrab_accelerator(BusName sender, uint action)
    {
        if (display.ungrab_accelerator(action)) {
            grabs.remove(action);
            return true;
        }
        return false;
    }
        
    public signal void accelerator_activated(uint action, HashTable<string,Variant> parameters);
} /* End ShellShim */

} /* End namespace */
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

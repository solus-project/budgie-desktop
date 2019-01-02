/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2019 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

public struct GsdAccel {
    string accelerator;
    uint flags;
}

[DBus (name = "org.gnome.SessionManager.EndSessionDialog")]
public class SessionHandler : GLib.Object
{

    public signal void ConfirmedLogout();
    public signal void ConfirmedReboot();
    public signal void ConfirmedShutdown();
    public signal void Canceled();
    public signal void Closed();

    private EndSessionDialog? proxy = null;

    public SessionHandler()
    {
        Bus.watch_name(BusType.SESSION, "org.budgie_desktop.Session.EndSessionDialog",
            BusNameWatcherFlags.NONE, has_dialog, lost_dialog);
    }

    void on_dialog_get(Object? o, AsyncResult? res)
    {
        try {
            proxy = Bus.get_proxy.end(res);
            proxy.ConfirmedLogout.connect(()=> {
                this.ConfirmedLogout();
            });
            proxy.ConfirmedReboot.connect(()=> {
                this.ConfirmedReboot();
            });
            proxy.ConfirmedShutdown.connect(()=> {
                this.ConfirmedShutdown();
            });
            proxy.Canceled.connect(()=> {
                this.Canceled();
            });
            proxy.Closed.connect(()=> {
                this.Closed();
            });
        } catch (Error e) {
            proxy = null;
        }
    }
    
    void has_dialog()
    {
        if (proxy != null) {
            return;
        }
        Bus.get_proxy.begin<EndSessionDialog>(BusType.SESSION, "org.budgie_desktop.Session.EndSessionDialog", "/org/budgie_desktop/Session/EndSessionDialog", 0, null, on_dialog_get);
    }

    void lost_dialog()
    {
        proxy = null;
    }

    public void Open(uint type, uint timestamp, uint open_length, ObjectPath[] inhibiters)
    {
        if (proxy == null) {
            return;
        }
        try {
            proxy.Open(type, timestamp, open_length, inhibiters);
        } catch (Error e) {
            message(e.message);
        }
    }

    public void Close()
    {
        if (proxy == null) {
            try {
                proxy.Close();
            } catch (Error e) {
                message(e.message);
            }
        }
    }
}

/**
 * Wrap the EndSessionDialog type inside Budgie itself
 */
[DBus (name = "org.budgie_desktop.Session.EndSessionDialog")]
public interface EndSessionDialog : GLib.Object
{

    public signal void ConfirmedLogout();
    public signal void ConfirmedReboot();
    public signal void ConfirmedShutdown();
    public signal void Canceled();
    public signal void Closed();

    public abstract void Open(uint type, uint timestamp, uint open_length, ObjectPath[] inhibiters) throws Error;

    public abstract void Close() throws Error;
}

/**
 * Expose the BudgieOSD functionality for proxying of the Shell OSD Functionality
 */
[DBus (name = "org.budgie_desktop.BudgieOSD")]
public interface BudgieOSD : GLib.Object
{
    /**
     * Budgie GTK+ On Screen Display
     *
     * Valid params:
     *  icon: string
     *  label: string
     *  level: int32
     *  monitor: int32
     */
    public abstract async void ShowOSD(HashTable<string,Variant> params) throws Error;
}

[DBus (name = "org.gnome.Shell")]
public class ShellShim : GLib.Object
{

    HashTable<uint,string> grabs;
    HashTable<string,uint> watches;
    unowned Meta.Display? display;

    private SessionHandler? handler = null;

    /* Proxy off the OSD Calls */
    private BudgieOSD? osd_proxy = null;

    [DBus (visible = false)]
    public ShellShim(Budgie.BudgieWM? wm)
    {
        grabs = new HashTable<uint,string>(direct_hash, direct_equal);
        watches = new HashTable<string,uint>(str_hash, str_equal);

        display = wm.get_display();
        display.accelerator_activated.connect(on_accelerator_activated);

        handler = new SessionHandler();

        Bus.watch_name(BusType.SESSION, "org.budgie_desktop.BudgieOSD",
            BusNameWatcherFlags.NONE, has_osd_proxy, lost_osd_proxy);
    }

    /**
     * BudgieOSD known to be present, now try to get the proxy
     */
    void on_osd_proxy_get(Object? o, AsyncResult? res)
    {
        try {
            osd_proxy = Bus.get_proxy.end(res);
        } catch (Error e) {
            osd_proxy = null;
        }
    }

    /**
     * BudgieOSD appeared, schedule a proxy-get
     */
    void has_osd_proxy()
    {
        if (osd_proxy  != null) {
            return;
        }
        Bus.get_proxy.begin<BudgieOSD>(BusType.SESSION, "org.budgie_desktop.BudgieOSD", "/org/budgie_desktop/BudgieOSD", 0, null, on_osd_proxy_get);
    }

    /**
     * BudgieOSD disappeared, drop the reference
     */
    void lost_osd_proxy()
    {
        osd_proxy = null;
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
            conn.register_object("/org/gnome/SessionManager/EndSessionDialog", handler);
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

    /**
     * Show the OSD when requested.
     */
    public void ShowOSD(HashTable<string,Variant> params)
    {
        if (osd_proxy != null) {
            osd_proxy.ShowOSD.begin(params);
        }
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

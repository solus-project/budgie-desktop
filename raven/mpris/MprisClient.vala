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

/**
 * Simple wrapper to ensure vala doesn't unref our shit.
 */
public class MprisClient : Object
{
    public PlayerIface player { construct set; get; }
    public DbusPropIface prop { construct set; get; }

    public MprisClient(PlayerIface player, DbusPropIface prop)
    {
        Object(player: player, prop: prop);
    }
}

/**
 * We need to probe the dbus daemon directly, hence this interface
 */
[DBus (name="org.freedesktop.DBus")]
public interface DBusImpl : Object
{
    public abstract async string[] list_names() throws IOError;
    public signal void name_owner_changed(string name, string old_owner, string new_owner);
    public signal void name_acquired(string name);
}

/**
 * Vala dbus property notifications are not working. Manually probe property changes.
 */
[DBus (name="org.freedesktop.DBus.Properties")]
public interface DbusPropIface : Object
{
    public signal void properties_changed(string iface, HashTable<string,Variant> changed, string[] invalid);
}

/**
 * Represents the base org.mpris.MediaPlayer2 spec
 */
[DBus (name="org.mpris.MediaPlayer2")]
public interface MprisIface : Object
{
    public abstract void raise() throws IOError;
    public abstract async void quit() throws IOError;

    public abstract bool can_quit { get; set; }
    public abstract bool fullscreen { get; } /* Optional */
    public abstract bool can_set_fullscreen { get; } /* Optional */
    public abstract bool can_raise { get; }
    public abstract bool has_track_list { get; }
    public abstract string identity { owned get; }
    public abstract string desktop_entry { owned get; } /* Optional */
    public abstract string[] supported_uri_schemes { owned get; }
    public abstract string[] supported_mime_types { owned get; }
}

/**
 * Interface for the org.mpris.MediaPlayer2.Player spec
 * This is the one that actually does cool stuff!
 *
 * @note We cheat and inherit from MprisIface to save faffing around with two
 * iface initialisations over one
 */
[DBus (name="org.mpris.MediaPlayer2.Player")]
public interface PlayerIface : MprisIface
{
    public abstract async void next() throws IOError;
    public abstract async void previous() throws IOError;
    public abstract async void pause() throws IOError;
    public abstract async void play_pause() throws IOError;
    public abstract async void stop() throws IOError;
    public abstract async void play() throws IOError;
    /* Eh we don't use everything in this iface :p */
    public abstract async void seek(int64 offset) throws IOError;
    public abstract async void open_uri(string uri) throws IOError;

    public abstract string playback_status { owned get; }
    public abstract string loop_status { owned get; set; } /* Optional */
    public abstract double rate { get; set; }
    public abstract bool shuffle { set; get; } /* Optional */

    public abstract HashTable<string,Variant> metadata { owned get; }

    public abstract double volume {get; set; }
    public abstract int64 position { get; }
    public abstract double minimum_rate { get; }
    public abstract double maximum_rate { get; }
    public abstract bool can_go_next { get; }
    public abstract bool can_go_previous { get; }
    public abstract bool can_play { get; }
    public abstract bool can_pause { get; }
    public abstract bool can_seek { get; }
    public abstract bool can_control { get; }
    
}

/**
 * Utility function, return a new iface instance, i.e. deal
 * with all the dbus cruft
 *
 * @param busname The busname to instaniate ifaces from
 * @return a new MprisClient, or null if errors occurred.
 */
public async MprisClient? new_iface(string busname)
{
    PlayerIface? play = null;
    MprisClient? cl = null;
    DbusPropIface? prop = null;

    try {
        play = yield Bus.get_proxy(BusType.SESSION, busname, "/org/mpris/MediaPlayer2");
    } catch (Error e) {
        message(e.message);
        return null;
    }
    try {
        prop = yield Bus.get_proxy(BusType.SESSION, busname, "/org/mpris/MediaPlayer2");
    } catch (Error e) {
        message(e.message);
        return null;
    }
    cl = new MprisClient(play, prop);

    return cl;
}

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

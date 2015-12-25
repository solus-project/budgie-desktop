/*
 * This file is part of arc-desktop.
 *
 * Copyright (C) 2015 Ikey Doherty
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Arc {

    [CCode (cheader_filename = "ArcPlugin.h")]
    public enum PanelAction {
        NONE,
        MENU,
        MAX,
    }

    [CCode (cheader_filename = "ArcPlugin.h")]
    public interface PopoverManager : GLib.Object
    {
        public abstract void register_popover(Gtk.Widget? widget, Gtk.Popover? popover);
        public abstract void unregister_popover(Gtk.Widget? widget);
        public abstract void show_popover(Gtk.Widget? parent);
    }

    [CCode (cheader_filename = "ArcPlugin.h")]
    public interface Plugin : GLib.Object {
        public abstract Arc.Applet get_panel_widget (string uuid);
    }
    [CCode (cheader_filename = "ArcPlugin.h")]
    public class Applet : Gtk.Bin {
        public Applet();

        public virtual void update_popovers(Arc.PopoverManager? manager) { }

        public GLib.Settings? get_applet_settings(string uuid);

        public string? settings_prefix { get; set; }
        public string? settings_schema { get; set; }
        public PanelAction supported_actions { get ; set; }

        public virtual Gtk.Widget? get_settings_ui();
        public virtual bool supports_settings();

        public virtual void invoke_action(Arc.PanelAction action);

        public signal void panel_size_changed(int panel_size, int icon_size);

    }

    [CCode (cheader_filename = "ArcPlugin.h")]
    public class AppletInfo : GLib.Object
    {

        public GLib.Settings? settings;

        public Arc.Applet applet { get; set; }

        public string icon {  get; set; }

        public string name { get;  set; }

        public string uuid { get; set; }

        public string alignment { get ; set; }


        public int position { get; set; }

        public AppletInfo(Peas.PluginInfo? plugin_info, string uuid, Arc.Applet? applet, GLib.Settings? settings);
    }

    [CCode (cheader_filename = "ArcPlugin.h")]
    public static const string APPLET_KEY_NAME;

    [CCode (cheader_filename = "ArcPlugin.h")]
    public static const string APPLET_KEY_ALIGN;

    [CCode (cheader_filename = "ArcPlugin.h")]
    public static const string APPLET_KEY_POS;

}

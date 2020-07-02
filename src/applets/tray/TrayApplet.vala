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

public class TrayPlugin : Budgie.Plugin, Peas.ExtensionBase {
    public Budgie.Applet get_panel_widget(string uuid) {
        return new TrayApplet(uuid);
    }
}

[GtkTemplate (ui = "/com/solus-project/tray/settings.ui")]
public class TraySettings : Gtk.Grid {
    Settings? settings = null;

    [GtkChild]
    private Gtk.SpinButton? spinbutton_spacing;

    public TraySettings(Settings? settings) {
        this.settings = settings;
        settings.bind("spacing", spinbutton_spacing, "value", SettingsBindFlags.DEFAULT);
    }
}

public class TrayApplet : Budgie.Applet {
    public string uuid { public set; public get; }
    private Carbon.Tray tray;
    private Gtk.EventBox box;
    private Settings? settings;
    private Gtk.Orientation orient;

    public TrayApplet(string uuid) {
        Object(uuid: uuid);

        box = new Gtk.EventBox();
        add(box);

        hexpand = false;
        vexpand = false;
        box.vexpand = false;
        box.hexpand = false;

        settings_schema = "com.solus-project.tray";
        settings_prefix = "/com/solus-project/budgie-panel/instance/tray";

        settings = get_applet_settings(uuid);
        settings.changed.connect(on_settings_change);

        maybe_integrate_tray();
    }

    public override bool supports_settings() {
        return true;
    }

    public override Gtk.Widget? get_settings_ui() {
        return new TraySettings(get_applet_settings(uuid));
    }

    void on_settings_change(string key) {
        if (key != "spacing") {
            return;
        }
        tray.set_spacing(settings.get_int(key));
    }

    public override void panel_position_changed(Budgie.PanelPosition position) {
        if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
            orient = Gtk.Orientation.VERTICAL;
        } else {
            orient = Gtk.Orientation.HORIZONTAL;
        }

        if (tray == null) {
            return;
        }

        tray.unregister();
        tray.remove_from_container(box);
        tray = null;
        maybe_integrate_tray();
    }

    protected void maybe_integrate_tray() {
        if (tray != null) {
            return;
        }

        tray = new Carbon.Tray(orient, 24, settings.get_int("spacing"));

        if (tray == null) {
            var label = new Gtk.Label("Tray unavailable");
            box.add(label);
            label.show_all();
            return;
        }

        switch (orient) {
        case Gtk.Orientation.HORIZONTAL:
            halign = Gtk.Align.START;
            valign = Gtk.Align.FILL;
            box.halign = Gtk.Align.START;
            box.valign = Gtk.Align.FILL;
            break;
        case Gtk.Orientation.VERTICAL:
            halign = Gtk.Align.FILL;
            valign = Gtk.Align.START;
            box.halign = Gtk.Align.FILL;
            box.valign = Gtk.Align.START;
            break;
        }

        tray.add_to_container(box);
        show_all();
        tray.register((Gdk.X11.Screen) get_screen());

        var win = get_toplevel();
        if (win == null) {
            return;
        }
        win.queue_draw();
        queue_resize();
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(TrayPlugin));
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

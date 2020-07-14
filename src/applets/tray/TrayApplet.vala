/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2020 Budgie Desktop Developers
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

private class TrayErrorIcon {
    public Budgie.PopoverManager manager;
    public Budgie.Popover popover;
    private Gtk.EventBox parent;

    public TrayErrorIcon(Gtk.EventBox parent, string text) {
        this.parent = parent;

        parent.add(new Gtk.Image.from_icon_name("gtk-dialog-error", Gtk.IconSize.LARGE_TOOLBAR));

        popover = new Budgie.Popover(parent);
        popover.get_style_context().add_class("system-tray-popover");

        Gtk.Label label = new Gtk.Label(text);
        label.show();
        popover.add(label);
        popover.hide();

        parent.button_press_event.connect(on_button_press);
    }

    ~TrayErrorIcon() {
        parent.button_press_event.disconnect(on_button_press);
    }

    public void register(Budgie.PopoverManager newManager) {
        manager = newManager;
        manager.register_popover(parent, popover);
    }

    private bool on_button_press(Gdk.EventButton event) {
        if (event.button != 1) {
            return Gdk.EVENT_PROPAGATE;
        }
        if (popover.get_visible()) {
            popover.hide();
        } else {
            manager.show_popover(parent);
        }
        return Gdk.EVENT_STOP;
    }
}

public class TrayApplet : Budgie.Applet {
    public string uuid { public set; public get; }
    private Carbon.Tray tray;
    private Gtk.EventBox box;
    private Settings? settings;
    private Gtk.Orientation orient;
    private Gdk.X11.Screen screen;

    // this property prevents the registration of more than one carbontray instance
    private static string activeUuid = null;
    private TrayErrorIcon errorIcon;

    public TrayApplet(string uuid) {
        Object(uuid: uuid);

        get_style_context().add_class("system-tray-applet");

        box = new Gtk.EventBox();
        add(box);

        settings_schema = "com.solus-project.tray";
        settings_prefix = "/com/solus-project/budgie-panel/instance/tray";

        settings = get_applet_settings(uuid);
        settings.changed["spacing"].connect((key) => {
            if (tray != null) tray.set_spacing(settings.get_int("spacing"));
        });

        if (activeUuid == null) {
            activeUuid = uuid;
            screen = (Gdk.X11.Screen) get_screen();

            screen.monitors_changed.connect(reintegrate_tray);
            parent_set.connect((old_parent) => {
                reintegrate_tray();
            });

            maybe_integrate_tray();
        } else {
            // there's already an active tray, create an informative icon with a popover
            errorIcon = new TrayErrorIcon(box, _("Only one instance of the System Tray can be active at a time."));
            show_all();
        }
    }

    ~TrayApplet() {
        if (activeUuid == uuid) activeUuid = null;
    }

    private void reintegrate_tray() {
        if (tray != null) {
            tray.remove_from_container(box);
            tray.dispose();
            tray = null;
        }

        if (activeUuid == null || activeUuid == uuid) {
            maybe_integrate_tray();
        }
    }

    private void maybe_integrate_tray() {
        tray = new Carbon.Tray(orient, 24, settings.get_int("spacing"));

        if (tray == null) {
            activeUuid = null;
            errorIcon = new TrayErrorIcon(box, _("The System Tray failed to initialize."));
            show_all();
            return;
        }

        activeUuid = uuid;

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
        tray.register(screen);
    }

    public override void panel_position_changed(Budgie.PanelPosition position) {
        if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
            orient = Gtk.Orientation.VERTICAL;
        } else {
            orient = Gtk.Orientation.HORIZONTAL;
        }

        reintegrate_tray();
    }

    public override void update_popovers(Budgie.PopoverManager? manager) {
        if (errorIcon != null) errorIcon.register(manager);
    }

    public override bool supports_settings() {
        return true;
    }

    public override Gtk.Widget? get_settings_ui() {
        return new TraySettings(get_applet_settings(uuid));
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module) {
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

/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class BudgieMenu : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new BudgieMenuApplet(uuid);
    }
}

[GtkTemplate (ui = "/com/solus-project/budgie-menu/settings.ui")]
public class BudgieMenuSettings : Gtk.Grid
{

    [GtkChild]
    private Gtk.Switch? switch_menu_label;

    [GtkChild]
    private Gtk.Switch? switch_menu_compact;

    [GtkChild]
    private Gtk.Switch? switch_menu_headers;

    [GtkChild]
    private Gtk.Switch? switch_menu_categories_hover;

    [GtkChild]
    private Gtk.Entry? entry_label;

    private Settings? settings;

    public BudgieMenuSettings(Settings? settings)
    {
        this.settings = settings;
        settings.bind("enable-menu-label", switch_menu_label, "active", SettingsBindFlags.DEFAULT);
        settings.bind("menu-compact", switch_menu_compact, "active", SettingsBindFlags.DEFAULT);
        settings.bind("menu-headers", switch_menu_headers, "active", SettingsBindFlags.DEFAULT);
        settings.bind("menu-categories-hover", switch_menu_categories_hover, "active", SettingsBindFlags.DEFAULT);
        settings.bind("menu-label", entry_label, "text", SettingsBindFlags.DEFAULT);
    }

}

public class BudgieMenuApplet : Budgie.Applet
{

    protected Gtk.ToggleButton widget;
    protected BudgieMenuWindow? popover;
    protected Settings settings;
    Gtk.Image img;
    Gtk.Label label;

    private unowned Budgie.PopoverManager? manager = null;

    public string uuid { public set ; public get; }

    public override Gtk.Widget? get_settings_ui()
    {
        return new BudgieMenuSettings(this.get_applet_settings(uuid));
    }

    public override bool supports_settings()
    {
        return true;
    }

    public BudgieMenuApplet(string uuid)
    {
        Object(uuid: uuid);

        settings_schema = "com.solus-project.budgie-menu";
        settings_prefix = "/com/solus-project/budgie-panel/instance/budgie-menu";

        settings = this.get_applet_settings(uuid);

        settings.changed.connect(on_settings_changed);

        widget = new Gtk.ToggleButton();
        widget.relief = Gtk.ReliefStyle.NONE;
        img = new Gtk.Image.from_icon_name("view-grid-symbolic", Gtk.IconSize.INVALID);
        img.pixel_size = 32;
        img.no_show_all = true;

        var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.pack_start(img, false, false, 3);
        label = new Gtk.Label("");
        label.halign = Gtk.Align.START;
        layout.pack_start(label, true, true, 3);

        widget.add(layout);

        // Better styling to fit in with the budgie-panel
        var st = widget.get_style_context();
        st.add_class("budgie-menu-launcher");
        st.add_class("panel-button");
        popover = new BudgieMenuWindow(settings, widget);
        popover.bind_property("visible", widget, "active");

        widget.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (popover.get_visible()) {
                popover.hide();
            } else {
                popover.get_child().show_all();
                this.manager.show_popover(widget);
            }
            return Gdk.EVENT_STOP;
        });

        popover.get_child().show_all();

        supported_actions = Budgie.PanelAction.MENU;

        add(widget);
        show_all();
        layout.valign = Gtk.Align.CENTER;
        valign = Gtk.Align.FILL;
        halign = Gtk.Align.FILL;
        on_settings_changed("enable-menu-label");
        on_settings_changed("menu-icon");
        on_settings_changed("menu-label");

        panel_size_changed.connect((p,i,s)=> {
            img.pixel_size = (int)i;
        });

        popover.key_release_event.connect((e)=> {
            if (e.keyval == Gdk.Key.Escape) {
                popover.hide();
            }
            return Gdk.EVENT_PROPAGATE;
        });
    }

    public override void invoke_action(Budgie.PanelAction action)
    {
        if ((action & Budgie.PanelAction.MENU) != 0) {
            if (popover.get_visible()) {
                popover.hide();
            } else {
                popover.get_child().show_all();
                this.manager.show_popover(widget);
            }
        }
    }

    protected void on_settings_changed(string key)
    {
        bool should_show = true;

        switch (key)
        {
            case "menu-icon":
                string? icon = settings.get_string(key);
                if ("/" in icon) {
                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(icon);
                    img.set_from_pixbuf(pixbuf.scale_simple(32, 32, Gdk.InterpType.BILINEAR));
                } else if (icon == "") {
                    should_show = false;
                } else {
                    img.set_from_icon_name(icon, Gtk.IconSize.INVALID);
                }
                img.set_visible(should_show);
                break;
            case "menu-label":
                label.set_label(settings.get_string(key));
                break;
            case "enable-menu-label":
                label.set_visible(settings.get_boolean(key));
                break;
            default:
                break;
        }
    }

    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        this.manager = manager;
        manager.register_popover(widget, popover);
    }

} // End class

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(BudgieMenu));
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

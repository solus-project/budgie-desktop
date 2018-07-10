/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2018 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
public class CaffeinePlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new CaffeineApplet(uuid);
    }
}

public class CaffeineApplet : Budgie.Applet
{
    private Gtk.EventBox event_box;
    private Budgie.Popover? popover = null;
    private unowned Budgie.PopoverManager? manager = null;
    private Settings? settings;

    public string uuid { public set; public get; }

    public CaffeineApplet(string uuid)
    {
        Object(uuid: uuid);

        settings_schema = "com.solus-project.caffeine";
        settings_prefix = "/com/solus-project/budgie-panel/instance/caffeine";

        settings = this.get_applet_settings(uuid);

        event_box = new Gtk.EventBox();
        var icon = new Gtk.Image.from_icon_name("caffeine-cup-empty", Gtk.IconSize.MENU);
        event_box.add(icon);
        this.add(event_box);

        popover = new Budgie.Popover(event_box);
        popover.get_style_context().add_class("caffeine-popover");
        var win = new CaffeineWindow ();
        popover.add(win);

        // On click icon
        event_box.button_press_event.connect((e)=> {
            if (e.button == 1) {
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    this.manager.show_popover(event_box);
                }
            } else {
                return Gdk.EVENT_PROPAGATE;
            }

            return Gdk.EVENT_STOP;
        });

        this.show_all();
    }

    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        manager.register_popover(event_box, popover);
        this.manager = manager;
    }

    public override bool supports_settings()
    {
        return true;
    }

    public override Gtk.Widget? get_settings_ui()
    {
        return new CaffeineSettings(this.get_applet_settings(uuid));
    }
}
} // end Namespace

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(CaffeinePlugin));
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

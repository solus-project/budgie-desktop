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

namespace Arc
{

public class SettingsView : Gtk.Box
{

    public signal void view_switch();

    public SettingsView()
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        /* TODO: Redo this whole *lot* as a composite. */
        var header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        header.get_style_context().add_class("raven-expander");
        pack_start(header, false, false, 0);

        var group1 = new Gtk.SizeGroup(Gtk.SizeGroupMode.VERTICAL);

        var icon = new Gtk.Image.from_icon_name("applications-system-symbolic", Gtk.IconSize.BUTTON);
        icon.valign = Gtk.Align.CENTER;
        icon.margin_start = 6;
        icon.margin_top = 4;
        icon.margin_bottom = 4;
        var label = new Gtk.Label("Budgie Settings");
        label.halign = Gtk.Align.START;
        label.valign = Gtk.Align.CENTER;
        label.margin_start = 6;
        label.margin_top = 4;
        label.margin_bottom = 4;
        var exit = new Gtk.Button.with_label("Exit");
        exit.valign = Gtk.Align.CENTER;
        exit.clicked.connect(()=> {
            this.view_switch();
        });
        exit.margin_top = 4;
        exit.margin_bottom = 4;
        exit.margin_end = 6;

        header.pack_start(icon, false, false, 0);
        group1.add_widget(icon);
        header.pack_start(label, true, true, 0);
        group1.add_widget(label);
        header.pack_end(exit, false, false, 0);
        group1.add_widget(exit);

        show_all();
    }
}

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

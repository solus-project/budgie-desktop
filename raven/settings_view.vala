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

[GtkTemplate (ui = "/com/solus-project/arc/raven/settings.ui")]
public class SettingsHeader : Gtk.Box
{
    private SettingsView? view = null;

    [GtkCallback]
    private void exit_clicked()
    {
        this.view.view_switch();
    }

    public SettingsHeader(SettingsView? view)
    {
        this.view = view;
    }
}

[GtkTemplate (ui = "/com/solus-project/arc/raven/appearance.ui")]
public class AppearanceSettings : Gtk.Box
{
}

public class SettingsView : Gtk.Box
{

    public signal void view_switch();

    private Gtk.Stack? stack = null;
    private Gtk.StackSwitcher? switcher = null;

    public SettingsView()
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        var header = new SettingsHeader(this);
        pack_start(header, false, false, 0);

        stack = new Gtk.Stack();
        stack.margin_top = 6;

        switcher = new Gtk.StackSwitcher();
        switcher.halign = Gtk.Align.CENTER;
        switcher.valign = Gtk.Align.CENTER;
        switcher.margin_top = 4;
        switcher.margin_bottom = 4;
        switcher.set_stack(stack);
        var sbox = new Gtk.EventBox();
        sbox.add(switcher);
        pack_start(sbox, false, false, 0);
        sbox.get_style_context().add_class("raven-switcher");

        pack_start(stack, true, true, 0);

        var appearance = new AppearanceSettings();
        stack.add_titled(appearance, "appearance", "General");
        stack.add_titled(new Gtk.Box(Gtk.Orientation.VERTICAL, 0), "panel", "Panel");

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

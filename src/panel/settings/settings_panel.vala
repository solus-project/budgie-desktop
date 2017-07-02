/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

/**
 * PanelPage allows users to change aspects of the fonts used
 */
public class PanelPage : Budgie.SettingsPage {

    unowned Budgie.Toplevel? toplevel;
    Gtk.Stack stack;
    Gtk.StackSwitcher switcher;
    Gtk.ComboBox combobox_position;
    Gtk.ComboBox combobox_autohide;
    Gtk.ComboBox combobox_transparency;

    Gtk.Switch switch_shadow;
    Gtk.Switch switch_regions;
    Gtk.Switch switch_dock;

    public PanelPage(Budgie.Toplevel? toplevel)
    {
        Object(group: SETTINGS_GROUP_PANEL,
               content_id: "panel-%s".printf(toplevel.uuid),
               title: PanelPage.get_panel_name(toplevel),
               icon_name: "gnome-panel");

        this.toplevel = toplevel;

        /* Main layout bits */
        switcher = new Gtk.StackSwitcher();
        switcher.halign = Gtk.Align.CENTER;
        stack = new Gtk.Stack();
        switcher.set_stack(stack);
        this.pack_start(switcher, false, false, 0);
        this.pack_start(stack, true, true, 0);

        this.stack.add_titled(this.applets_page(), "main", _("Applets"));
        this.stack.add_titled(this.settings_page(), "applets", _("Settings"));

        this.show_all();
    }

    /**
     * Determine a human readable named based on the panel's position on screen
     * For brownie points we'll identify docks differently
     */
    static string get_panel_name(Budgie.Toplevel? panel)
    {
        if (panel.dock_mode) {
            switch (panel.position) {
                case PanelPosition.TOP:
                    return _("Top Dock");
                case PanelPosition.RIGHT:
                    return _("Right Dock");
                case PanelPosition.LEFT:
                    return _("Left Dock");
                default:
                    return _("Bottom Dock");
            }
        } else {
            switch (panel.position) {
                case PanelPosition.TOP:
                    return _("Top Panel");
                case PanelPosition.RIGHT:
                    return _("Right Panel");
                case PanelPosition.LEFT:
                    return _("Left Panel");
                default:
                    return _("Bottom Panel");
            }
        }
    }

    /**
     * Convert a position into a usable, renderable Thing™
     */
    static string pos_to_display(Budgie.PanelPosition position)
    {
        switch (position) {
            case PanelPosition.TOP:
                return _("Top");
            case PanelPosition.RIGHT:
                return _("Right");
            case PanelPosition.LEFT:
                return _("Left");
            default:
                return _("Bottom");
        }
    }

    private Gtk.Widget? settings_page()
    {
        SettingsGrid? ret = new SettingsGrid();
        Gtk.SizeGroup group = new Gtk.SizeGroup(Gtk.SizeGroupMode.BOTH);

        /* Position */
        combobox_position = new Gtk.ComboBox();
        group.add_widget(combobox_position);
        ret.add_row(new SettingsRow(combobox_position,
            _("Position"),
            _("Set the edge of the screen that this panel will stay on. If another " +
              "panel is already there, they will automatically swap positions")));

        /* Autohide */
        combobox_autohide = new Gtk.ComboBox();
        group.add_widget(combobox_autohide);
        ret.add_row(new SettingsRow(combobox_autohide,
            _("Automatically hide"),
            _("When set, this panel will hide from view to maximize screen estate. " +
              "Use the intelligent mode to make this panel automatically avoid active windows")));

        /* Transparency */
        combobox_transparency = new Gtk.ComboBox();
        group.add_widget(combobox_transparency);
        ret.add_row(new SettingsRow(combobox_transparency,
            _("Transparency"),
            _("Control when this panel should have a solid background")));

        /* Shadow */
        switch_shadow = new Gtk.Switch();
        ret.add_row(new SettingsRow(switch_shadow,
            _("Shadow"),
            _("Adds a decorative drop-shadow, ideal for opaque panels")));

        /* Regions */
        switch_regions = new Gtk.Switch();
        ret.add_row(new SettingsRow(switch_regions,
            _("Stylize regions"),
            _("Adds a hint to the panel so that each of the panel's three main areas " +
              "may be themed differently.")));

        /* Dock */
        switch_dock = new Gtk.Switch();
        ret.add_row(new SettingsRow(switch_dock,
            _("Dock mode"),
            _("When in dock mode, the panel will use the minimal amount of space possible, " +
              "freeing up valuable screen estate")));

        /* Allow deletion of the panel */
        var button_remove_panel = new Gtk.Button.with_label(_("Remove"));
        button_remove_panel.valign = Gtk.Align.CENTER;
        button_remove_panel.vexpand = false;
        button_remove_panel.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        ret.add_row(new SettingsRow(button_remove_panel,
            _("Delete panel"),
            _("Permanently remove the panel and applets from the screen. This action cannot be undone")));


        /* Now let's sort out some models */
        var model = new Gtk.ListStore(2, typeof(Budgie.PanelPosition), typeof(string));
        Gtk.TreeIter iter;
        const Budgie.PanelPosition[] positions = {
            Budgie.PanelPosition.TOP,
            Budgie.PanelPosition.BOTTOM,
            Budgie.PanelPosition.LEFT,
            Budgie.PanelPosition.RIGHT,
        };
        foreach (var pos in positions) {
            model.append(out iter);
            model.set(iter, 0, pos, 1, PanelPage.pos_to_display(pos), -1);
        }
        combobox_position.set_model(model);
        combobox_position.set_id_column(0);

        /* We'll reuse this guy */
        var render = new Gtk.CellRendererText();
        combobox_position.pack_start(render, true);
        combobox_position.add_attribute(render, "text", 1);
        combobox_position.set_id_column(0);

        return ret;
    }

    private Gtk.Widget? applets_page()
    {
        return new SettingsGrid();
    }
    
} /* End class */

} /* End namespace */

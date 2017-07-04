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
 * StylePage simply provides a bunch of theme controls
 */
public class StylePage : Budgie.SettingsPage {


    private Gtk.ComboBox? combobox_gtk;
    private Gtk.ComboBox? combobox_icon;
    private Gtk.ComboBox? combobox_cursor;
    private Gtk.Switch? switch_dark;
    private Gtk.Switch? switch_builtin;
    private Gtk.Switch? switch_animations;
    private GLib.Settings ui_settings;
    private GLib.Settings budgie_settings;
    private ThemeScanner? theme_scanner;

    public StylePage()
    {
        Object(group: SETTINGS_GROUP_APPEARANCE,
               content_id: "style",
               title: _("Style"),
               display_weight: 0,
               icon_name: "preferences-desktop-theme");

        var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
        var grid = new SettingsGrid();
        this.add(grid);

        combobox_gtk = new Gtk.ComboBox();
        grid.add_row(new SettingsRow(combobox_gtk,
            _("Widgets"),
            _("Set the appearance of window decorations, controls and input fields")));

        combobox_icon = new Gtk.ComboBox();
        grid.add_row(new SettingsRow(combobox_icon,
            _("Icons"),
            _("Set the global icon theme used for applications and the desktop")));

        combobox_cursor = new Gtk.ComboBox();
        grid.add_row(new SettingsRow(combobox_cursor,
            _("Cursors"),
            _("Set the global cursor theme used for applications and the desktop")));

        /* Stick the combos in a size group */
        group.add_widget(combobox_gtk);
        group.add_widget(combobox_icon);
        group.add_widget(combobox_cursor);

        switch_dark = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_dark, _("Dark theme")));

        switch_builtin = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_builtin,
            _("Built-in theme"),
            _("When enabled, the desktop component style will be overriden with the built-in one")));

        switch_animations = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_animations,
            _("Animations"),
            _("Control whether windows and controls use animations")));

        /* Sort out renderers for all of our dropdowns */
        var render = new Gtk.CellRendererText();
        combobox_gtk.pack_start(render, true);
        combobox_gtk.add_attribute(render, "text", 0);
        combobox_icon.pack_start(render, true);
        combobox_icon.add_attribute(render, "text", 0);
        combobox_cursor.pack_start(render, true);
        combobox_cursor.add_attribute(render, "text", 0);

        /* Hook up settings */
        ui_settings = new GLib.Settings("org.gnome.desktop.interface");
        budgie_settings = new GLib.Settings("com.solus-project.budgie-panel");
        budgie_settings.bind("dark-theme", switch_dark, "active", SettingsBindFlags.DEFAULT);
        budgie_settings.bind("builtin-theme", switch_builtin, "active", SettingsBindFlags.DEFAULT);
        ui_settings.bind("enable-animations", switch_animations, "active", SettingsBindFlags.DEFAULT);
        this.theme_scanner = new ThemeScanner();

        Idle.add(()=> {
            this.load_themes();
            return false;
        });
    }

    public void load_themes()
    {
        /* Scan the themes */
        this.theme_scanner.scan_themes.begin(()=> {
            /* Gtk themes */
            {
                Gtk.TreeIter iter;
                var model = new Gtk.ListStore(1, typeof(string));
                bool hit = false;
                foreach (var theme in theme_scanner.get_gtk_themes()) {
                    model.append(out iter);
                    model.set(iter, 0, theme, -1);
                    hit = true;
                }
                combobox_gtk.set_model(model);
                combobox_gtk.set_id_column(0);
                model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
                if (hit) {
                    combobox_gtk.sensitive = true;
                    ui_settings.bind("gtk-theme", combobox_gtk, "active-id", SettingsBindFlags.DEFAULT);
                }
            }
            /* Icon themes */
            {
                Gtk.TreeIter iter;
                var model = new Gtk.ListStore(1, typeof(string));
                bool hit = false;
                foreach (var theme in theme_scanner.get_icon_themes()) {
                    model.append(out iter);
                    model.set(iter, 0, theme, -1);
                    hit = true;
                }
                combobox_icon.set_model(model);
                combobox_icon.set_id_column(0);
                model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
                if (hit) {
                    combobox_icon.sensitive = true;
                    ui_settings.bind("icon-theme", combobox_icon, "active-id", SettingsBindFlags.DEFAULT);
                }
            }

            /* Cursor themes */
            {
                Gtk.TreeIter iter;
                var model = new Gtk.ListStore(1, typeof(string));
                bool hit = false;
                foreach (var theme in theme_scanner.get_cursor_themes()) {
                    model.append(out iter);
                    model.set(iter, 0, theme, -1);
                    hit = true;
                }
                combobox_cursor.set_model(model);
                combobox_cursor.set_id_column(0);
                model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
                if (hit) {
                    combobox_cursor.sensitive = true;
                    ui_settings.bind("cursor-theme", combobox_cursor, "active-id", SettingsBindFlags.DEFAULT);
                }
            }
            queue_resize();
        });
    }

} /* End class */

} /* End namespace */

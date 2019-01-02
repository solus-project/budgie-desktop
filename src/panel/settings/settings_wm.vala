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

namespace Budgie {

/**
 * WindowsPage allows users to control window manager settings
 */
public class WindowsPage : Budgie.SettingsPage {

    private GLib.Settings gnome_wm_settings;
    private GLib.Settings budgie_wm_settings;
    private Gtk.Switch center_windows;
    private Gtk.Switch disable_night_light;
    private Gtk.ComboBox combo_layouts;
    private Gtk.Switch switch_dialogs;
    private Gtk.Switch switch_focus;
    private Gtk.Switch switch_tiling;
    private Gtk.Switch switch_unredirect;

    public WindowsPage()
    {
        Object(group: SETTINGS_GROUP_APPEARANCE,
               content_id: "windows",
               title: _("Windows"),
               display_weight: 4,
               icon_name: "preferences-system-windows");

        var grid = new SettingsGrid();
        this.add(grid);

        switch_dialogs = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_dialogs,
            _("Attach modal dialogs to windows"),
            _("Modal dialogs will become attached to the parent window and move together when dragged")
        ));

        combo_layouts = new Gtk.ComboBox();
        grid.add_row(new SettingsRow(combo_layouts,
            _("Button layout"),
            _("Change the layout of buttons in application titlebars")
        ));

        center_windows = new Gtk.Switch();
        grid.add_row(new SettingsRow(center_windows,
            _("Center new windows on screen"),
            _("Center newly launched windows on the current screen")
        ));

        disable_night_light = new Gtk.Switch();
        grid.add_row(new SettingsRow(disable_night_light,
            _("Disable Night Light mode when windows are fullscreen"),
            _("Disables Night Light mode when a window is fullscreen. Re-enables when leaving fullscreen.")
        ));

        switch_tiling = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_tiling,
            _("Automatic tiling"),
            _("Windows will automatically tile when dragged into the top of the screen or the far corners")
        ));

        switch_focus = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_focus,
            _("Enable window focus change on mouse enter and leave"),
            _("Enables window focus to apply when the mouse enters the window and unfocus when the mouse leaves the window.")
        ));

        /* Unredirect.. */
        switch_unredirect = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_unredirect,
            _("Disable unredirection of windows"),
            _("This option is for advanced users. Use this if you are having graphical or performance issues with dedicated GPUs")
        ));

        /* Button layout  */
        var model = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter iter;
        model.append(out iter);
        model.set(iter, 0, "traditional", 1, _("Right (standard)"), -1);
        model.append(out iter);
        model.set(iter, 0, "left", 1, _("Left"), -1);
        combo_layouts.set_model(model);
        combo_layouts.set_id_column(0);

        var render = new Gtk.CellRendererText();
        combo_layouts.pack_start(render, true);
        combo_layouts.add_attribute(render, "text", 1);
        combo_layouts.set_id_column(0);

        /* Hook up settings */
        gnome_wm_settings = new GLib.Settings("org.gnome.mutter");
        budgie_wm_settings = new GLib.Settings("com.solus-project.budgie-wm");
        gnome_wm_settings.bind("attach-modal-dialogs", switch_dialogs,  "active", SettingsBindFlags.DEFAULT);
        budgie_wm_settings.bind("button-style", combo_layouts,  "active-id", SettingsBindFlags.DEFAULT);
        budgie_wm_settings.bind("center-windows", center_windows, "active", SettingsBindFlags.DEFAULT);
        budgie_wm_settings.bind("disable-night-light-on-fullscreen", disable_night_light, "active", SettingsBindFlags.DEFAULT);
        gnome_wm_settings.bind("edge-tiling", switch_tiling,  "active", SettingsBindFlags.DEFAULT);
        budgie_wm_settings.bind("focus-mode", switch_focus, "active", SettingsBindFlags.DEFAULT);
        budgie_wm_settings.bind("force-unredirect", switch_unredirect, "active", SettingsBindFlags.DEFAULT);
    }

} /* End class */

} /* End namespace */

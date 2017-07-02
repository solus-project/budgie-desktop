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
 * WindowsPage allows users to control window manager settings
 */
public class WindowsPage : Budgie.SettingsPage {

    private GLib.Settings budgie_wm_settings;
    private Gtk.ComboBox combo_layouts;
    private Gtk.Switch switch_unredirect;
    private Gtk.Switch switch_dialogs;
    private Gtk.Switch switch_tiling;

    public WindowsPage()
    {
        Object(group: SETTINGS_GROUP_APPEARANCE,
               content_id: "windows",
               title: _("Windows"),
               icon_name: "preferences-system-windows");

        var grid = new SettingsGrid();
        this.add(grid);

        combo_layouts = new Gtk.ComboBox();
        grid.add_row(new SettingsRow(combo_layouts,
            _("Button layout"),
            _("Change the layout of buttons in application titlebars")));

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

        /* Dialogs attach modally */
        switch_dialogs = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_dialogs,
            _("Attach modal dialogs to windows"),
            _("Modal dialogs will become attached to the parent window and move together when dragged")));

        switch_tiling = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_tiling,
            _("Automatic tiling"),
            _("Windows will automatically tile when dragged into the top of the screen or the far corners")));

        /* Unredirect.. */
        switch_unredirect = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_unredirect,
            _("Disable unredirection of windows"),
            _("This option is for advanced users. " +
              "Use this if you are having graphical or performance issues with dedicated GPUs")));

        /* Hook up settings */
        budgie_wm_settings = new GLib.Settings("com.solus-project.budgie-wm");
        budgie_wm_settings.bind("attach-modal-dialogs", switch_dialogs,  "active", SettingsBindFlags.DEFAULT);
        budgie_wm_settings.bind("button-style", combo_layouts,  "active-id", SettingsBindFlags.DEFAULT);
        budgie_wm_settings.bind("edge-tiling", switch_tiling,  "active", SettingsBindFlags.DEFAULT);
        budgie_wm_settings.bind("force-unredirect", switch_unredirect, "active", SettingsBindFlags.DEFAULT);
    }
    
} /* End class */

} /* End namespace */

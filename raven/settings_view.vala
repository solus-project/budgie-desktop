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

public enum ThemeType {
    ICON_THEME,
    GTK_THEME,
    WM_THEME,
    CURSOR_THEME
}

public enum PanelColumn {
    UUID = 0,
    DESCRIPTION = 1,
    N_COLUMNS = 2,
}

[GtkTemplate (ui = "/com/solus-project/arc/raven/panel.ui")]
public class PanelEditor : Gtk.Box
{

    public Arc.DesktopManager? manager { public set ; public get ; }

    [GtkChild]
    private Gtk.ComboBox? combobox_panels;
    private ulong panels_id;

    [GtkChild]
    private Gtk.Button? button_add_panel;

    [GtkChild]
    private Gtk.Button? button_remove_panel;

    [GtkChild]
    private Gtk.ComboBox? combobox_position;
    private ulong position_id;

    [GtkChild]
    private Gtk.SpinButton? spinbutton_size;
    private ulong spin_id;

    [GtkChild]
    private Gtk.ComboBox? combobox_policy;

    [GtkChild]
    private Gtk.Switch? switch_shadow;
    private ulong shadow_id;

    HashTable<string?,Arc.Toplevel?> panels;
    unowned Arc.Toplevel? current_panel = null;
    private ulong notify_id;

    [GtkChild]
    private Gtk.ScrolledWindow? scrolledwindow_applets;

    Gtk.ListBox? listbox_applets = null;

    public PanelEditor(Arc.DesktopManager? manager)
    {
        Object(manager: manager);

        manager.panels_changed.connect(on_panels_changed);

        button_add_panel.clicked.connect(()=> {
            this.manager.create_new_panel();
        });
        button_remove_panel.clicked.connect(()=> {
            this.manager.delete_panel(current_panel.uuid);
        });

        /* PanelPosition */
        var model = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter iter;
        model.append(out iter);
        model.set(iter, 0, "top", 1, "Top", -1);
        model.append(out iter);
        model.set(iter, 0, "bottom", 1, "Bottom", -1);
        combobox_position.set_model(model);
        combobox_position.set_id_column(0);
        var render = new Gtk.CellRendererText();
        combobox_position.pack_start(render, true);
        combobox_position.add_attribute(render, "text", 1);
        combobox_position.set_id_column(0);


        model = new Gtk.ListStore(2, typeof(string), typeof(string));
        render = new Gtk.CellRendererText();
        combobox_panels.set_model(model);
        combobox_panels.pack_start(render, true);
        combobox_panels.add_attribute(render, "text", PanelColumn.DESCRIPTION);
        combobox_panels.set_id_column(PanelColumn.UUID);

        position_id = combobox_position.changed.connect(on_position_changed);
        spin_id = spinbutton_size.value_changed.connect(on_size_changed);

        spinbutton_size.set_range(16, 200);
        spinbutton_size.set_numeric(true);

        shadow_id = switch_shadow.notify["active"].connect(on_shadow_changed);

        panels_id = combobox_panels.changed.connect(on_panel_changed);

        listbox_applets = new Gtk.ListBox();
        listbox_applets.get_style_context().remove_class("background");
        scrolledwindow_applets.add(listbox_applets);
    }

    void on_panel_changed()
    {
        var id = combobox_panels.get_active_id();
        set_active_panel(id);
    }

    void on_shadow_changed()
    {
        current_panel.shadow_visible = this.switch_shadow.active;
    }

    void on_size_changed()
    {
        manager.set_size(current_panel.uuid, (int)spinbutton_size.get_value());
    }

    string get_panel_id(Arc.Toplevel? panel)
    {
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

    string positition_to_id(PanelPosition pos)
    {
        switch (pos) {
            case PanelPosition.TOP:
                return "top";
            case PanelPosition.LEFT:
                return "left";
            case PanelPosition.RIGHT:
                return "right";
            default:
                return "bottom";
        }
    }

    public void on_panels_changed()
    {
        button_add_panel.set_sensitive(manager.slots_available() >= 1);
        button_remove_panel.set_sensitive(manager.slots_used() > 1);
        string? uuid = null;
        string? old_uuid = null;

        if (current_panel != null) {
            old_uuid = current_panel.uuid;
        }

        panels = new HashTable<string?,Arc.Toplevel?>(str_hash, str_equal);

        var panels = manager.get_panels();
        if (panels == null || panels.length() < 1) {
            return;
        }

        var model = new Gtk.ListStore(PanelColumn.N_COLUMNS, typeof(string), typeof(string));
        Gtk.TreeIter iter;
        foreach (var panel in panels) {
            string? pos = this.get_panel_id(panel);
            model.append(out iter);
            if (uuid == null) {
                uuid = panel.uuid;
            }
            this.panels.insert(panel.uuid, panel);
            model.set(iter, PanelColumn.UUID, panel.uuid, PanelColumn.DESCRIPTION, pos, -1);
        }

        model.set_sort_column_id(PanelColumn.DESCRIPTION, Gtk.SortType.DESCENDING);
        combobox_panels.set_model(model);
        combobox_panels.set_id_column(PanelColumn.UUID);

        /* In future check we haven't got one selected already.. */
        if (old_uuid != null && this.panels.contains(old_uuid)) {
            set_active_panel(old_uuid);
        } else {
            set_active_panel(uuid);
        }
    }

    /*
     * Hook up our current UI to this toplevel
     */
    void set_active_panel(string uuid)
    {
        unowned Arc.Toplevel? panel = panels.lookup(uuid);
        SignalHandler.block(combobox_panels, panels_id);
        combobox_panels.set_active_id(uuid);
        SignalHandler.unblock(combobox_panels, panels_id);

        if (panel == null || panel == this.current_panel) {
            return;
        }

        /* Unbind old panel?! */
        if (current_panel != null) {
            SignalHandler.disconnect(current_panel, notify_id);
        }
        current_panel = panel;

        /* Bind position.. ? */
        notify_id = panel.notify.connect(on_panel_update);

        SignalHandler.block(combobox_position, position_id);
        combobox_position.set_active_id(positition_to_id(panel.position));
        SignalHandler.unblock(combobox_position, position_id);

        SignalHandler.block(spinbutton_size, spin_id);
        spinbutton_size.set_value(panel.intended_size);
        SignalHandler.unblock(spinbutton_size, spin_id);

        switch_shadow.set_active(panel.shadow_visible);

        update_applets();
    }

    void update_applets()
    {
        foreach (var child in listbox_applets.get_children()) {
            child.destroy();
        }

        if (current_panel == null) {
            return;
        }

        foreach (var applet in current_panel.get_applets()) {
            var widgem = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var img = new Gtk.Image.from_icon_name(applet.icon, Gtk.IconSize.LARGE_TOOLBAR);
            img.margin_start = 6;
            img.margin_end = 8;
            img.margin_top = 4;
            img.margin_bottom = 4;
            widgem.pack_start(img, false, false, 0);

            var label = new Gtk.Label(applet.name);
            widgem.pack_start(label, true, true, 0);
            label.halign = Gtk.Align.START;

            listbox_applets.add(widgem);
        }
    }

    /* Handle updates to the current panel
     */
    void on_panel_update(Object o, ParamSpec p)
    {
        var panel = o as Arc.Toplevel;

        /* Update position */
        if (p.name == "position") {
            var pos = this.positition_to_id(panel.position);
            SignalHandler.block(combobox_position, position_id);
            combobox_position.set_active_id(pos);
            SignalHandler.unblock(combobox_position, position_id);
        } else if (p.name == "intended-size") {
            SignalHandler.block(spinbutton_size, spin_id);
            spinbutton_size.set_value(panel.intended_size);
            SignalHandler.unblock(spinbutton_size, spin_id);
        } else if (p.name == "shadow-visible") {
            SignalHandler.block(switch_shadow, shadow_id);
            switch_shadow.set_active(panel.shadow_visible);
            SignalHandler.unblock(switch_shadow, shadow_id);
        }
    }

    void on_position_changed()
    {
        var id = combobox_position.active_id;
        PanelPosition pos;
        switch (id) {
            case "top":
                pos = PanelPosition.TOP;
                break;
            case "left":
                pos = PanelPosition.LEFT;
                break;
            case "right":
                pos = PanelPosition.RIGHT;
                break;
            default:
                pos = PanelPosition.BOTTOM;
                break;
        }

        manager.set_placement(current_panel.uuid, pos);
    }
}

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

    [GtkChild]
    private Gtk.ComboBox? combobox_gtk;

    [GtkChild]
    private Gtk.ComboBox? combobox_icon;

    [GtkChild]
    private Gtk.Switch? switch_dark;

    private GLib.Settings ui_settings;
    private GLib.Settings arc_settings;

    construct {
        var render = new Gtk.CellRendererText();
        combobox_gtk.pack_start(render, true);
        combobox_gtk.add_attribute(render, "text", 0);
    
        combobox_icon.pack_start(render, true);
        combobox_icon.add_attribute(render, "text", 0);

        ui_settings = new GLib.Settings("org.gnome.desktop.interface");
        arc_settings = new GLib.Settings("com.solus-project.arc-panel");
        arc_settings.bind("dark-theme", switch_dark, "active", SettingsBindFlags.DEFAULT);
    }

    public void load_themes()
    {
        load_themes_by_type.begin(ThemeType.GTK_THEME, (obj,res)=> {
            bool b = load_themes_by_type.end(res);
            combobox_gtk.sensitive = b;
            queue_resize();
            if (b) {
                ui_settings.bind("gtk-theme", combobox_gtk, "active-id", SettingsBindFlags.DEFAULT);
            }
        });
        load_themes_by_type.begin(ThemeType.ICON_THEME, (obj,res)=> {
            bool b = load_themes_by_type.end(res);
            combobox_icon.sensitive = b;
            queue_resize();
            if (b) {
                ui_settings.bind("icon-theme", combobox_icon, "active-id", SettingsBindFlags.DEFAULT);
            }
        });
    }

    /* Load theme list */
    async bool load_themes_by_type(ThemeType type)
    {
        var spc = Environment.get_system_data_dirs();
        spc += Environment.get_user_data_dir();
        string[] search = {};
        string? item = "";
        string? suffix = "";
        string[] results = {};
        FileTest test_type = FileTest.IS_DIR;

        unowned Gtk.ComboBox? target = null;
        Gtk.ListStore? model = null;
        Gtk.TreeIter iter;

        switch (type) {
            case ThemeType.GTK_THEME:
                item = "themes";
                suffix = "gtk-3.0";
                target = this.combobox_gtk;
                break;
            case ThemeType.ICON_THEME:
                item = "icons";
                suffix = "index.theme";
                test_type = FileTest.IS_REGULAR;
                target = this.combobox_icon;
                break;
            case ThemeType.CURSOR_THEME:
                item = "icons";
                suffix = "cursors";
                break;
            default:
                return false;
        }

        if (target == null) {
            return false;
        }

        model = new Gtk.ListStore(1, typeof(string));

        foreach (var dir in spc) {
            // Not making FS assumptions ftw.
            dir = (dir + Path.DIR_SEPARATOR_S +  item);
            if (FileUtils.test(dir, FileTest.IS_DIR)) {
                search += dir;
            }
        }
        string home = Environment.get_home_dir() + Path.DIR_SEPARATOR_S + "." + item;
        if (FileUtils.test(home, FileTest.IS_DIR)) {
            search += home;
        }

        foreach (var dir in search) {
            File f = File.new_for_path(dir);
            try {
                var en = yield f.enumerate_children_async("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, null);
                while (true) {
                    var files = yield en.next_files_async(10, Priority.DEFAULT, null);
                    if (files == null) {
                        break;
                    }
                    foreach (var file in files) {
                        var display_name = file.get_display_name();
                        var test_path = dir + Path.DIR_SEPARATOR_S + display_name + Path.DIR_SEPARATOR_S + suffix;
                        if (!(display_name in results) && FileUtils.test(test_path, test_type)) {
                            results += display_name;
                            model.append(out iter);
                            model.set(iter, 0, display_name, -1);
                        }
                    }
                }
            } catch (Error e) {
                message("Error: %s", e.message);
            }
        }
        target.set_id_column(0);
        model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
        target.set_model(model);
        return true;
    }
}

public class SettingsView : Gtk.Box
{

    public signal void view_switch();

    private Gtk.Stack? stack = null;
    private Gtk.StackSwitcher? switcher = null;

    public Arc.DesktopManager? manager { public set ; public get ; }

    public SettingsView(Arc.DesktopManager? manager)
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0, manager: manager);

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
        sbox.get_style_context().add_class("raven-background");

        pack_start(stack, true, true, 0);

        stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
        var appearance = new AppearanceSettings();
        stack.add_titled(appearance, "appearance", _("General"));

        var panel = new PanelEditor(manager);
        stack.add_titled(panel, "panel", _("Panel"));
        stack.add_titled(new Gtk.Box(Gtk.Orientation.VERTICAL, 0), "sidebar", _("Sidebar"));

        appearance.load_themes();

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

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

namespace Budgie
{

public enum PanelColumn {
    UUID = 0,
    DESCRIPTION = 1,
    N_COLUMNS = 2,
}

[GtkTemplate (ui = "/com/solus-project/budgie/raven/applet_settings.ui")]
public class AppletSettings : Gtk.Box {

    [GtkChild]
    private Gtk.Label? label_title;

    [GtkChild]
    private Gtk.ScrolledWindow? scrolledwindow;

    public signal void view_switch();

    [GtkCallback]
    void back_clicked()
    {
        view_switch();
    }

    public void set_applet(Budgie.AppletInfo? info)
    {
        if (scrolledwindow.get_child() != null) {
            scrolledwindow.remove(scrolledwindow.get_child());
        }
        label_title.set_text(info.name);
        scrolledwindow.add(info.applet.get_settings_ui());
        scrolledwindow.show_all();
    }

    public AppletSettings()
    {
    }

}

[GtkTemplate (ui = "/com/solus-project/budgie/raven/applets.ui")]
public class AppletPicker : Gtk.Box {

    [GtkChild]
    private Gtk.Button? button_add;

    [GtkChild]
    private Gtk.Button? button_back;

    [GtkChild]
    private Gtk.ScrolledWindow? scrolledwindow;

    private Gtk.ListBox? listbox;

    private unowned Peas.PluginInfo? current_info = null;

    public AppletPicker() {
        listbox = new Gtk.ListBox();
        listbox.set_selection_mode(Gtk.SelectionMode.SINGLE);
        listbox.set_sort_func(lb_sort);
        scrolledwindow.add(listbox);
        listbox.row_selected.connect(on_row_selected);
        listbox.set_activate_on_single_click(false);
        listbox.row_activated.connect(on_row_activate);
    }


    public signal void view_switch();
    public signal void applet_add(Peas.PluginInfo? info);

    [GtkCallback]
    void back_clicked()
    {
        view_switch();
    }

    [GtkCallback]
    void add_clicked()
    {
        view_switch();
        applet_add(this.current_info);
    }

    int lb_sort(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after)
    {
        unowned Peas.PluginInfo? before_info = before.get_child().get_data("info");
        unowned Peas.PluginInfo? after_info = after.get_child().get_data("info");

        if (before_info != null && after_info != null ) {
            return GLib.strcmp(before_info.get_description(), after_info.get_description());
        }
        return 0;
    }

    public void set_plugin_list(GLib.List<Peas.PluginInfo?> plugins)
    {
        foreach (var child in listbox.get_children()) {
            child.destroy();
        }

        button_add.sensitive = false;

        foreach (var info in plugins) {
            var widgem = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var img = new Gtk.Image.from_icon_name(info.get_icon_name(), Gtk.IconSize.MENU);
            img.margin_start = 10;
            img.margin_end = 8;
            img.margin_top = 4;
            img.margin_bottom = 4;
            widgem.pack_start(img, false, false, 0);
            widgem.set_data("info", info);

            var label = new Gtk.Label(info.get_description());
            widgem.pack_start(label, true, true, 0);
            label.halign = Gtk.Align.START;

            widgem.show_all();
            listbox.add(widgem);
            listbox.show_all();
            scrolledwindow.show_all();
        }
        listbox.invalidate_sort();
    }

    /**
     * Handle double click/enter usage
     */
    void on_row_activate(Gtk.ListBoxRow? row)
    {
        if (this.current_info == null) {
            return;
        }
        this.add_clicked();
    }

    /**
     * Handle row selection for setting the current applet info
     */
    void on_row_selected(Gtk.ListBoxRow? row)
    {
        unowned Peas.PluginInfo? info = null;

        if (row == null) {
            button_add.sensitive = false;
            current_info = null;
            return;
        }

        info = row.get_child().get_data("info");
        button_add.sensitive = true;
        current_info = info;
    }
}


[GtkTemplate (ui = "/com/solus-project/budgie/raven/panel.ui")]
public class PanelEditor : Gtk.Box
{

    public Budgie.DesktopManager? manager { public set ; public get ; }

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

    [GtkChild]
    private Gtk.Switch? switch_regions;
    private ulong region_id;

    HashTable<string?,Budgie.Toplevel?> panels;
    unowned Budgie.Toplevel? current_panel = null;
    private ulong notify_id;

    [GtkChild]
    private Gtk.ScrolledWindow? scrolledwindow_applets;
    Gtk.ListBox? listbox_applets = null;

    [GtkChild]
    private Gtk.Button? button_add_applet;

    [GtkChild]
    private Gtk.Button? button_remove_applet;

    [GtkChild]
    private Gtk.Button? button_move_applet_left;

    [GtkChild]
    private Gtk.Button? button_move_applet_right;

    [GtkChild]
    private Gtk.Button? button_settings;

    /* Removal confirmation so nobody kicks themselves in the teeth.. */
    private Gtk.Popover removal_popover;
    private Gtk.Button removal_ok;
    private Gtk.Button removal_cancel;

    [GtkCallback]
    void settings_clicked()
    {
        this.appsettings.set_applet(current_applet);
        this.panel_stack.set_visible_child_name("settings");
    }

    private unowned Budgie.AppletInfo? current_applet = null;
    private ulong applets_changed_id;
    private ulong applet_added_id;
    private ulong applet_removed_id;

    private AppletPicker? picker;
    private AppletSettings? appsettings;

    private HashTable<string?,Gtk.Widget?> applets = null;

    private unowned Gtk.Stack? panel_stack = null;

    public PanelEditor(Budgie.DesktopManager? manager, Gtk.Stack? panel_stack)
    {
        Object(manager: manager);
        this.panel_stack = panel_stack;

        manager.panels_changed.connect(on_panels_changed);

        button_add_panel.clicked.connect(()=> {
            this.manager.create_new_panel();
        });

        /* Removal confirmation for panels */
        removal_popover = new Gtk.Popover(button_remove_panel);
        removal_ok = new Gtk.Button.with_label(_("Remove panel"));
        removal_ok.get_style_context().add_class("destructive-action");
        removal_ok.set_property("margin", 3);
        removal_cancel = new Gtk.Button.with_label(_("Cancel"));
        removal_cancel.get_style_context().add_class("suggested-action");
        removal_cancel.set_property("margin", 3);
        var size_group = new Gtk.SizeGroup(Gtk.SizeGroupMode.BOTH);
        size_group.add_widget(removal_ok);
        size_group.add_widget(removal_cancel);

        // Confirmation prompt: Does the user really wish to remove the given panel?
        var removal_label = new Gtk.Label("<b>%s</b>".printf(_("Really remove this panel?")));
        removal_label.set_halign(Gtk.Align.START);
        removal_label.set_property("xalign", 0.0);
        removal_label.set_use_markup(true);
        removal_label.set_property("margin", 5);
        var removal_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        var removal_box2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        removal_box.pack_start(removal_label, false, false, 2);
        removal_box.pack_start(removal_box2, false, false, 2);
        removal_box2.pack_start(removal_cancel, false, false, 2);
        removal_box2.pack_start(removal_ok, false, false, 2);

        removal_box.show_all();
        removal_popover.add(removal_box);

        /* When clicking remove, show the confirmation UI */
        button_remove_panel.clicked.connect(()=> {
            this.removal_popover.show();
        });

        /* User confirmed removal */
        removal_ok.clicked.connect(()=> {
            this.removal_popover.hide();
            if (this.current_panel != null) {
                this.manager.delete_panel(current_panel.uuid);
            }
        });
        /* User declined removal */
        removal_cancel.clicked.connect(()=> {
            this.removal_popover.hide();
        });

        applets = new HashTable<string?,Gtk.Widget?>(str_hash, str_equal);

        /* PanelPosition */
        var model = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter iter;
        model.append(out iter);
        model.set(iter, 0, "top", 1, _("Top"), -1);
        model.append(out iter);
        model.set(iter, 0, "bottom", 1, _("Bottom"), -1);
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
        region_id = switch_regions.notify["active"].connect(on_region_changed);

        panels_id = combobox_panels.changed.connect(on_panel_changed);

        listbox_applets = new Gtk.ListBox();
        listbox_applets.get_style_context().remove_class("background");
        scrolledwindow_applets.add(listbox_applets);
        listbox_applets.set_sort_func(lb_sort);
        listbox_applets.set_header_func(lb_headers);
        listbox_applets.row_activated.connect(on_row_activate);

        button_remove_applet.clicked.connect(()=> {
            if (current_applet != null && current_panel != null) {
                current_panel.remove_applet(current_applet);
            }
        });
        button_move_applet_left.clicked.connect(()=> {
            if (current_applet != null && current_panel != null) {
                current_panel.move_applet_left(current_applet);
            }
        });
        button_move_applet_right.clicked.connect(()=> {
            if (current_applet != null && current_panel != null) {
                current_panel.move_applet_right(current_applet);
            }
        });
        button_add_applet.clicked.connect(()=> {
            this.picker.set_plugin_list(manager.get_panel_plugins());
            this.panel_stack.set_visible_child_name("applets");
        });


        picker = new AppletPicker();
        picker.view_switch.connect(()=> {
            this.panel_stack.set_visible_child_name("panel");
        });
        picker.applet_add.connect(do_applet_add);
        this.panel_stack.add_titled(picker, "applets", "Applets");

        appsettings = new AppletSettings();
        appsettings.view_switch.connect(()=> {
            this.panel_stack.set_visible_child_name("panel");
        });
        this.panel_stack.add_titled(appsettings, "settings", "Settings");
    }

    void do_applet_add(Peas.PluginInfo? info)
    {
        if (info == null || current_panel == null) {
            return;
        }

        current_panel.add_new_applet(info.get_name());
    }

    void init_applets()
    {
        picker.set_plugin_list(manager.get_panel_plugins());
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

    void on_region_changed()
    {
        current_panel.theme_regions = this.switch_regions.active;
    }

    void on_size_changed()
    {
        manager.set_size(current_panel.uuid, (int)spinbutton_size.get_value());
    }

    string get_panel_id(Budgie.Toplevel? panel)
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

        panels = new HashTable<string?,Budgie.Toplevel?>(str_hash, str_equal);

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
        unowned Budgie.Toplevel? panel = panels.lookup(uuid);
        SignalHandler.block(combobox_panels, panels_id);
        combobox_panels.set_active_id(uuid);
        SignalHandler.unblock(combobox_panels, panels_id);

        if (panel == null || panel == this.current_panel) {
            return;
        }

        /* Unbind old panel?! */
        if (current_panel != null) {
            SignalHandler.disconnect(current_panel, notify_id);
            SignalHandler.disconnect(current_panel, applets_changed_id);
            SignalHandler.disconnect(current_panel, applet_added_id);
            SignalHandler.disconnect(current_panel, applet_removed_id);
        }
        current_panel = panel;

        /* Bind position.. ? */
        notify_id = panel.notify.connect(on_panel_update);
        applets_changed_id = panel.applets_changed.connect(refresh_applets);
        applet_added_id = panel.applet_added.connect(applet_added);
        applet_removed_id = panel.applet_removed.connect(applet_removed);

        SignalHandler.block(combobox_position, position_id);
        combobox_position.set_active_id(positition_to_id(panel.position));
        SignalHandler.unblock(combobox_position, position_id);

        SignalHandler.block(spinbutton_size, spin_id);
        spinbutton_size.set_value(panel.intended_size);
        SignalHandler.unblock(spinbutton_size, spin_id);

        switch_shadow.set_active(panel.shadow_visible);
        switch_regions.set_active(panel.theme_regions);

        update_applets();
        init_applets();

        this.panel_stack.set_visible_child_name("panel");
    }

    void applet_added(Budgie.AppletInfo? info)
    {
        insert_applet(info);
        refresh_applets();
    }

    void applet_removed(string uuid)
    {
        update_applets();
    }

    void insert_applet(Budgie.AppletInfo? applet)
    {
        var widgem = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var img = new Gtk.Image.from_icon_name(applet.icon, Gtk.IconSize.MENU);
        img.margin_start = 6;
        img.margin_end = 8;
        img.margin_top = 4;
        img.margin_bottom = 4;
        widgem.pack_start(img, false, false, 0);
        widgem.set_data("ainfo", applet);

        var label = new Gtk.Label(applet.description);
        widgem.pack_start(label, true, true, 0);
        label.halign = Gtk.Align.START;

        widgem.show_all();
        listbox_applets.add(widgem);
        applets.insert(applet.uuid, widgem);
    }

    void refresh_applets()
    {
        listbox_applets.invalidate_sort();
        listbox_applets.invalidate_headers();

        var row = listbox_applets.get_selected_row();;
        if (row != null) {
            on_row_activate(row);
        }
    }

    void update_applets()
    {
        foreach (var child in listbox_applets.get_children()) {
            child.destroy();
        }

        applets.remove_all();
        if (current_panel == null) {
            return;
        }

        button_remove_applet.sensitive = false;
        button_move_applet_left.sensitive = false;
        button_move_applet_right.sensitive = false;
        button_settings.sensitive = false;
        current_applet = null;

        foreach (var applet in current_panel.get_applets()) {
            insert_applet(applet);
        }

        listbox_applets.invalidate_sort();
        listbox_applets.invalidate_headers();
    }

    int align_to_int(string al)
    {
        switch (al) {
            case "start":
                return 0;
            case "center":
                return 1;
            default:
                return 2;
        }
    }

    int lb_sort(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after)
    {
        unowned Budgie.AppletInfo? before_info = before.get_child().get_data("ainfo");
        unowned Budgie.AppletInfo? after_info = after.get_child().get_data("ainfo");

        if (before_info != null && after_info != null && before_info.alignment != after_info.alignment) {
            int bi = align_to_int(before_info.alignment);
            int ai = align_to_int(after_info.alignment);

            if (ai > bi) {
                return -1;
            } else {
                return 1;
            }
        }

        if (after_info == null) {
            return 0;
        }
        if (before_info.position < after_info.position) {
            return -1;
        } else if (before_info.position > after_info.position) {
            return 1;
        }
        return 0;
    }

    void lb_headers(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after)
    {
        Gtk.Widget? child = null;
        string? prev = null;
        string? next = null;
        unowned Budgie.AppletInfo? before_info = null;
        unowned Budgie.AppletInfo? after_info = null;

        if (before != null) {
            before_info = before.get_child().get_data("ainfo");
            prev = before_info.alignment;
        }

        if (after != null) {
            after_info = after.get_child().get_data("ainfo");
            next = after_info.alignment;
        }

        if (before == null || after == null || prev != next) {
            Gtk.Label? label = null;
            switch (prev) {
                case "start":
                    label = new Gtk.Label(_("Start"));
                    break;
                case "center":
                    label = new Gtk.Label(_("Center"));
                    break;
                default:
                    label = new Gtk.Label(_("End"));
                    break;
            }
            label.get_style_context().add_class("dim-label");
            label.halign = Gtk.Align.START;
            var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
            sep.set_valign(Gtk.Align.CENTER);
            label.margin_start = 8;
            label.margin_end = 6;
            label.margin_top = 3;
            label.margin_bottom = 3;

            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start(label, false, false, 0);
            box.pack_start(sep, true, true, 0);
            label.use_markup = true;
            box.show_all();
            before.set_header(box);
        } else {
            before.set_header(null);
        }
    }

    void on_row_activate(Gtk.ListBoxRow? row)
    {
        unowned Budgie.AppletInfo? info = null;

        if (current_panel == null || row == null) {
            button_move_applet_left.sensitive = false;
            button_move_applet_right.sensitive = false;
            button_remove_applet.sensitive = false;
            button_settings.sensitive = false;
            return;
        }

        info = row.get_child().get_data("ainfo");
        button_move_applet_left.sensitive = current_panel.can_move_applet_left(info);
        button_move_applet_right.sensitive = current_panel.can_move_applet_right(info);
        button_remove_applet.sensitive = true;
        button_settings.sensitive = info.applet.supports_settings();
        current_applet = info;
    }

    /* Handle updates to the current panel
     */
    void on_panel_update(Object o, ParamSpec p)
    {
        var panel = o as Budgie.Toplevel;

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
        } else if (p.name == "theme-regions") {
            SignalHandler.block(switch_regions, region_id);
            switch_regions.set_active(panel.theme_regions);
            SignalHandler.unblock(switch_regions, region_id);
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

[GtkTemplate (ui = "/com/solus-project/budgie/raven/settings.ui")]
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

[GtkTemplate (ui = "/com/solus-project/budgie/raven/fonts.ui")]
public class FontSettings : Gtk.Box
{

    [GtkChild]
    private Gtk.FontButton? fontbutton_title;

    [GtkChild]
    private Gtk.FontButton? fontbutton_document;

    [GtkChild]
    private Gtk.FontButton? fontbutton_interface;

    [GtkChild]
    private Gtk.FontButton? fontbutton_monospace;

    private GLib.Settings ui_settings;
    private GLib.Settings wm_settings;

    construct {
        ui_settings = new GLib.Settings("org.gnome.desktop.interface");
        wm_settings = new GLib.Settings("org.gnome.desktop.wm.preferences");

        ui_settings.bind("document-font-name", fontbutton_document, "font-name", SettingsBindFlags.DEFAULT);
        ui_settings.bind("font-name", fontbutton_interface, "font-name", SettingsBindFlags.DEFAULT);
        ui_settings.bind("monospace-font-name", fontbutton_monospace, "font-name", SettingsBindFlags.DEFAULT);
        wm_settings.bind("titlebar-font", fontbutton_title, "font-name", SettingsBindFlags.DEFAULT);
    }
}

[GtkTemplate (ui = "/com/solus-project/budgie/raven/background.ui")]
public class BackgroundSettings : Gtk.Box
{
    [GtkChild]
    private Gtk.Switch? switch_icons;

    private GLib.Settings background_settings;

    construct {
        background_settings = new GLib.Settings("org.gnome.desktop.background");
        background_settings.bind("show-desktop-icons", switch_icons, "active", SettingsBindFlags.DEFAULT);
    }
}

/**
 * Window manager settings pane
 */
[GtkTemplate (ui = "/com/solus-project/budgie/raven/wm.ui")]
public class WmSettings : Gtk.Box
{
    [GtkChild]
    private Gtk.Switch? switch_unredirect;

    /** Button layout */
    [GtkChild]
    private Gtk.ComboBox? combo_layouts;

    private GLib.Settings wm_settings;

    construct {
        wm_settings = new GLib.Settings("com.solus-project.budgie-wm");
        /* Force unredirect of the display, i.e. nvidia folks */
        wm_settings.bind("force-unredirect", switch_unredirect, "active", SettingsBindFlags.DEFAULT);

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
        wm_settings.bind("button-style", combo_layouts,  "active-id", SettingsBindFlags.DEFAULT);
    }
}

[GtkTemplate (ui = "/com/solus-project/budgie/raven/appearance.ui")]
public class AppearanceSettings : Gtk.Box
{

    [GtkChild]
    private Gtk.ComboBox? combobox_gtk;

    [GtkChild]
    private Gtk.ComboBox? combobox_icon;

    [GtkChild]
    private Gtk.ComboBox? combobox_cursor;

    [GtkChild]
    private Gtk.Switch? switch_dark;

    [GtkChild]
    private Gtk.Switch? switch_builtin;

    private GLib.Settings ui_settings;
    private GLib.Settings budgie_settings;

    private ThemeScanner? theme_scanner;

    construct {
        var render = new Gtk.CellRendererText();
        combobox_gtk.pack_start(render, true);
        combobox_gtk.add_attribute(render, "text", 0);

        combobox_icon.pack_start(render, true);
        combobox_icon.add_attribute(render, "text", 0);

        combobox_cursor.pack_start(render, true);
        combobox_cursor.add_attribute(render, "text", 0);

        ui_settings = new GLib.Settings("org.gnome.desktop.interface");
        budgie_settings = new GLib.Settings("com.solus-project.budgie-panel");
        budgie_settings.bind("dark-theme", switch_dark, "active", SettingsBindFlags.DEFAULT);
        budgie_settings.bind("builtin-theme", switch_builtin, "active", SettingsBindFlags.DEFAULT);
        this.theme_scanner = new ThemeScanner();
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
}

public class SettingsView : Gtk.Box
{

    public signal void view_switch();

    private Gtk.Stack? stack = null;
    private Gtk.StackSwitcher? switcher = null;

    public Budgie.DesktopManager? manager { public set ; public get ; }

    private Gtk.Stack? panel_stack = null;

    public SettingsView(Budgie.DesktopManager? manager)
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
        var appearance_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        var appearance = new AppearanceSettings();

        /* Appearance expander */
        var app_exp = new RavenExpander(new HeaderWidget(_("Appearance"), null, false));
        app_exp.add(appearance);
        
        appearance_box.pack_start(app_exp, false, false, 0);
        /* This option currently only affects Nautilus. */
        if (Environment.find_program_in_path("nautilus") != null) {
            var background_settings = new BackgroundSettings();
            var back_exp = new RavenExpander(new HeaderWidget(_("Background"), null, false));
            back_exp.add(background_settings);
            appearance_box.pack_start(back_exp, false, false, 0);
        }

        /* Font settings */
        var fonts = new FontSettings();
        var fonts_exp = new RavenExpander(new HeaderWidget(_("Fonts"), null, false));
        fonts_exp.add(fonts);
        appearance_box.pack_start(fonts_exp, false, false, 0);

        /* WM Settings */
        var wm = new WmSettings();
        var wm_exp = new RavenExpander(new HeaderWidget(_("Windows"), null, false));
        wm_exp.add(wm);
        appearance_box.pack_start(wm_exp, false, false, 0);

        stack.add_titled(appearance_box, "appearance", _("General"));

        panel_stack = new Gtk.Stack();
        panel_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
        var panel = new PanelEditor(manager, panel_stack);


        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scroll.add(panel);

        panel_stack.add_titled(scroll, "panel", _("Panel"));
        stack.add_titled(panel_stack, "panel", _("Panel"));
        /*stack.add_titled(new Gtk.Box(Gtk.Orientation.VERTICAL, 0), "sidebar", _("Sidebar"));*/

        appearance.load_themes();

        show_all();
    }

    public void set_clean()
    {
        stack.set_visible_child_name("appearance");
        panel_stack.set_visible_child_name("panel");
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

/*
 * BudgiePanel.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public enum ThemeType {
    ICON_THEME,
    GTK_THEME,
    WM_THEME,
    CURSOR_THEME
}


public class PanelEditor : Gtk.Window
{
    // Holds our content, basically.
    Gtk.ListBox content;

    // Our applet config area
    Gtk.Grid applet_config;

    // Our panel reference
    unowned Budgie.Panel? panel;

    Gtk.ComboBox pack_type;
    Gtk.Switch is_status;
    Gtk.SpinButton pad_start;
    Gtk.SpinButton pad_end;

    // Wrap everything in a stack
    Gtk.Stack book;

    Gtk.Dialog add_dialog;

    // Currently selected AppletInfo
    unowned AppletInfo? current_info;

    // Currently selected PluginInfo
    unowned Peas.PluginInfo? current_plugin;

    protected Gtk.Button app_add_btn;
    protected Gtk.Button app_cancel_btn;

    protected Settings settings;
    protected Settings ui_settings;
    protected Settings wm_settings;

    ulong is_status_id;
    ulong pack_type_id;
    ulong pad_start_id;
    ulong pad_end_id;

    public PanelEditor(Budgie.Panel parent_panel)
    {
        this.panel = parent_panel;
        //resizable = false;
        title = "Panel preferences";
        icon_name = "preferences-desktop";
        window_position = Gtk.WindowPosition.CENTER;

        var header = new Gtk.HeaderBar();
        header.set_show_close_button(true);
        set_titlebar(header);
        header.show_all();
        header.set_title("Budgie Settings"); // Ubuntu craq

        settings = new Settings("com.evolve-os.budgie.panel");
        ui_settings = new Settings("org.gnome.desktop.interface");
        wm_settings = new Settings("org.gnome.desktop.wm.preferences");

        book = new Gtk.Stack();
        book.border_width = 30;
        book.set_transition_type(Gtk.StackTransitionType.SLIDE_UP_DOWN);
        var sbar = new Budgie.Sidebar();
        sbar.set_stack(book);
        var ssep = new Gtk.Separator(Gtk.Orientation.VERTICAL);
        ssep.show();

        var wrap = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrap.pack_start(sbar, false, false, 0);
        wrap.pack_start(ssep, false, false, 0);
        wrap.pack_start(book, true, true, 0);
        wrap.show_all();

        add(wrap);

        var child = create_personalize_page();
        book.add_titled(child, "appearance", "Appearance");
        book.child_set(child, "icon-name", "preferences-desktop-wallpaper-symbolic");

        child = create_applet_main_area();
        book.add_titled(child, "applets", "Applets");
        book.child_set(child, "icon-name", "install-symbolic");

        child = create_menu_area();
        book.add_titled(child, "menu", "Menu");
        book.child_set(child, "icon-name", "folder-documents-symbolic");

        child = create_panel_area();
        book.add_titled(child, "panel", "Panel");
        book.child_set(child, "icon-name", "user-home-symbolic");

        book.show_all();
        sbar.show_all();
        set_size_request(400, 390);
    }

    public int on_sort(Gtk.ListBoxRow before, Gtk.ListBoxRow after)
    {
        AppletInfo? before_info = before.get_child().get_data("app_info");
        AppletInfo? after_info = after.get_child().get_data("app_info");

        /* Simply ensures status items go last */
        if (before_info != null && after_info != null && before_info.status_area != after_info.status_area) {
            if (before_info.status_area) {
                return 1;
            } else {
                return -1;
            }
        }

        /* Else, we'll sort by packing index */
        if (after_info == null) {
            return 0;
        }
        if (before_info.position < after_info.position) {
            return -1;
        } else if (before_info.position > after_info.position) {
            return 1;
        } else {
            return 0;
        }
    }

    public void on_row_selected(Gtk.ListBoxRow? row)
    {
        if (row == null) {
            applet_config.sensitive = false;
            return;
        }
        applet_config.sensitive = true;
        AppletInfo app_info = row.get_child().get_data("app_info");
        current_info = app_info;
        update_config(app_info);
    }

    public void update_config(AppletInfo applet)
    {
        SignalHandler.block(is_status, is_status_id);
        SignalHandler.block(pack_type, pack_type_id);
        SignalHandler.block(pad_start, pad_start_id);
        SignalHandler.block(pad_end, pad_end_id);

        switch (applet.pack_type) {
            case Gtk.PackType.START:
                pack_type.active = 0;
                break;
            case Gtk.PackType.END:
            default:
                pack_type.active = 1;
                break;
        }
        is_status.set_active(applet.status_area);
        pad_start.set_value(applet.pad_start);
        pad_end.set_value(applet.pad_end);

        SignalHandler.unblock(is_status, is_status_id);
        SignalHandler.unblock(pack_type, pack_type_id);
        SignalHandler.unblock(pad_start, pad_start_id);
        SignalHandler.unblock(pad_end, pad_end_id);

    }

    public void on_applet_added(ref AppletInfo applet)
    {
        // Add item to list
        var item = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        var label = new Gtk.Label(applet.name);
        label.set_use_markup(true);
        label.set_halign(Gtk.Align.START);
        var image = new Gtk.Image.from_icon_name(applet.icon, Gtk.IconSize.LARGE_TOOLBAR);
        item.pack_start(image, false, false, 10);
        item.pack_start(label, true, true, 5);
        content.add(item);
        item.set_data("app_info", applet);
        item.show_all();

        content.invalidate_sort();
    }

    public void on_applet_removed(string name)
    {
        foreach (var child in content.get_children()) {
            if (child.get_visible() && child.get_child_visible()) {
                Gtk.ListBoxRow row = child as Gtk.ListBoxRow;
                Budgie.AppletInfo? child_applet = row.get_child().get_data("app_info");
                // The app info will actually be null'd by now as BudgiePanel free'd the data
                if (child_applet.name == name) {
                    row.destroy();
                    break;
                }
            }
        }
    }

    protected int applet_sort(Gtk.ListBoxRow before, Gtk.ListBoxRow after)
    {
        Peas.PluginInfo? before_info = before.get_child().get_data("plugin-info");
        Peas.PluginInfo? after_info = after.get_child().get_data("plugin-info");

        /* Sort by text.. */
        if (after_info == null) {
            return 0;
        }

        return strcmp(before_info.get_name(), after_info.get_name());
    }

    protected Gtk.Widget? create_applet_main_area()
    {
        var master_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        var label = new Gtk.Label("<big>Panel applets</big>");
        label.halign = Gtk.Align.START;
        label.get_style_context().add_class("dim-label");
        label.set_use_markup(true);

        master_layout.pack_start(label, false, false, 0);
        var ssep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        ssep.margin_top = 12;
        ssep.margin_bottom = 12;
        master_layout.pack_start(ssep, false, false, 0);

        var sidesplit = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        master_layout.pack_start(sidesplit, true, true, 0);

        var layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        content = new Gtk.ListBox();
        content.set_border_width(3);
        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.set_shadow_type(Gtk.ShadowType.ETCHED_IN);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scroll.add(content);
        scroll.get_style_context().set_junction_sides(Gtk.JunctionSides.BOTTOM);

        var tbar = new Gtk.Toolbar();
        tbar.set_icon_size(Gtk.IconSize.SMALL_TOOLBAR);
        tbar.get_style_context().add_class(Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        tbar.get_style_context().set_junction_sides(Gtk.JunctionSides.TOP);

        // Create items.
        var add_btn = new Gtk.ToolButton(null, null);
        add_btn.set_icon_name("list-add-symbolic");
        add_btn.clicked.connect(()=> {
            add_dialog.show_all();
            app_add_btn.visible = true;
            app_cancel_btn.visible = true;
        });

        tbar.add(add_btn);

        var remove_btn = new Gtk.ToolButton(null, null);
        remove_btn.set_icon_name("list-remove-symbolic");
        remove_btn.clicked.connect(()=> {
            if (current_info == null) {
                return;
            }
            panel.remove_applet(current_info.name);
        });
        tbar.add(remove_btn);

        // up/down
        var up_btn = new Gtk.ToolButton(null, null);
        up_btn.clicked.connect(()=> {
            if (current_info == null) {
                return;
            }
            var position = current_info.position;
            var new_position = position - 1;
            if (new_position < 0) {
                new_position = 0;
            }

            /* Perform a hot swap */
            foreach (var child in content.get_children()) {
                if (child.get_visible() && child.get_child_visible()) {
                    AppletInfo? data = ((Gtk.ListBoxRow)child).get_child().get_data("app_info");
                    if (data.position == new_position && data.status_area == current_info.status_area) {
                        data.position = position;
                        break;
                    }
                }
            }
            current_info.position = new_position;

            update_config(current_info);
            content.invalidate_sort();
        });

        up_btn.set_icon_name("go-up-symbolic");
        tbar.add(up_btn);

        var down_btn = new Gtk.ToolButton(null, null);
        /* Allow movement. */
        down_btn.clicked.connect(()=> {
            if (current_info == null) {
                return;
            }
            var position = current_info.position;
            var new_position = position + 1;

            /* Perform a hot swap */
            foreach (var child in content.get_children()) {
                if (child.get_visible() && child.get_child_visible()) {
                    AppletInfo? data = ((Gtk.ListBoxRow)child).get_child().get_data("app_info");
                    if (data.position == new_position && data.status_area == current_info.status_area) {
                        data.position = position;
                        break;
                    }
                }
            }
            current_info.position = new_position;
            update_config(current_info);
            content.invalidate_sort();
        });

        down_btn.set_icon_name("go-down-symbolic");
        tbar.add(down_btn);

        // pack
        layout.pack_start(scroll, true, true, 0);
        layout.pack_end(tbar, false, false, 0);

        var grid = new Gtk.Grid();
        grid.row_spacing = 4;
        grid.column_spacing = 4;

        // Various options here for individual applets
        label = new Gtk.Label("Place in status area");
        var is_status = new Gtk.Switch();
        this.is_status = is_status;
        is_status.halign = Gtk.Align.END;
        is_status.active = false;
        grid.attach(label, 0, 0, 1, 1);
        grid.attach(is_status, 1, 0, 1, 1);
        is_status_id = is_status.state_flags_changed.connect((previous_state_flags)=> {
            if (current_info == null) {
                return;
            }
            // Don't fire unneeded signals!
            if (is_status.active != current_info.status_area) {
                current_info.status_area = is_status.active;
                content.invalidate_sort();
                update_config(current_info);
            }
        });

        sidesplit.pack_start(layout, true, true, 0);
        sidesplit.pack_start(grid, false, false, 10);

        // Padding start
        var spinner = new Gtk.SpinButton.with_range(0, 100, 1);
        label = new Gtk.Label("Start padding");
        pad_start = spinner;
        label.set_halign(Gtk.Align.START);
        grid.attach(label, 0, 1, 1, 1);
        grid.attach(spinner, 1, 1, 1, 1);

        // Padding end
        spinner = new Gtk.SpinButton.with_range(0, 100, 1);
        label = new Gtk.Label("End padding");
        pad_end = spinner;
        label.set_halign(Gtk.Align.START);
        grid.attach(label, 0, 2, 1, 1);
        grid.attach(spinner, 1, 2, 1, 1);
        applet_config = grid;

        // pack type
        label = new Gtk.Label("Placement");
        label.set_halign(Gtk.Align.START);
        var combo = new Gtk.ComboBoxText();
        pack_type = combo;
        combo.append_text("start");
        //combo.append_text("center");
        combo.append_text("end");
        grid.attach(label, 0, 3, 1, 1);
        grid.attach(combo, 1, 3, 1, 1);
        pack_type_id = combo.changed.connect(()=> {
            if (current_info == null) {
                return;
            }
            /* Update pack type on the applet info */
            switch (combo.active) {
                case 0:
                    current_info.pack_type = Gtk.PackType.START;
                    break;
                /* TODO: Support center! */
                default:
                    current_info.pack_type = Gtk.PackType.END;
                    break;
            }
        });

        on_row_selected(content.get_selected_row());

        panel.applet_added.connect(on_applet_added);
        panel.applet_removed.connect(on_applet_removed);

        content.set_activate_on_single_click(true);
        content.row_selected.connect(on_row_selected);

        pad_start_id = pad_start.changed.connect(()=> {
            if (current_info == null) {
                return;
            }
            current_info.pad_start = (int)pad_start.get_value();
        });
        pad_end_id = pad_end.changed.connect(()=> {
            if (current_info == null) {
                return;
            }
            current_info.pad_end = (int)pad_end.get_value();
        });

        content.set_sort_func(on_sort);

        add_dialog = create_applet_area();

        return master_layout;
    }

    /** Create the area used to add applets.. */
    protected Gtk.Dialog create_applet_area()
    {
        Gtk.ListBox rows = new Gtk.ListBox();
        Gtk.ScrolledWindow scroller = new Gtk.ScrolledWindow(null, null);
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scroller.set_shadow_type(Gtk.ShadowType.IN);
        scroller.add(rows);

        rows.set_sort_func(applet_sort);

        Gtk.Dialog dialog = new Gtk.Dialog();
        dialog.set_transient_for(this);
        dialog.set_modal(true);
        dialog.set_title("Add applet");
        dialog.set_size_request(350, 350);
        dialog.get_content_area().pack_start(scroller, true, true, 0);

        /* Populate :) */
        foreach (var plugin in Peas.Engine.get_default().get_plugin_list()) {
            Gtk.Box row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            Gtk.Image icon = new Gtk.Image.from_icon_name(plugin.get_icon_name(), Gtk.IconSize.INVALID);
            icon.pixel_size = 48;
            row.pack_start(icon, false, false, 10);
            string? cleaned = Markup.printf_escaped("<big>%s</big>\n%s", plugin.get_name(), plugin.get_description());
            Gtk.Label label = new Gtk.Label(cleaned);
            row.pack_start(label, true, true, 5);
            label.use_markup = true;
            label.set_halign(Gtk.Align.START);

            row.set_data("plugin-info", plugin);
            row.show_all();
            rows.add(row);
        }

        var cancel_btn = new Gtk.Button.with_label("Cancel");
        dialog.add_action_widget(cancel_btn, Gtk.ResponseType.CANCEL);
        app_cancel_btn = cancel_btn;
        cancel_btn.visible = false;
        cancel_btn.clicked.connect(()=> {
            dialog.hide();
        });

        var add_btn = new Gtk.Button.with_label("Add");
        dialog.add_action_widget(add_btn, Gtk.ResponseType.OK);
        app_add_btn = add_btn;
        add_btn.visible = false;
        add_btn.sensitive = false;

        rows.row_selected.connect((r)=> {
            if (r == null) {
                add_btn.sensitive = false;
                return;
            }
            current_plugin = r.get_child().get_data("plugin-info");
            add_btn.sensitive = true;
        });

        add_btn.clicked.connect(()=> {
            /* Don't want lockups if loading in background */
            Idle.add(()=> {
                panel.add_new_applet(current_plugin.get_name());
                return false;
            });
            add_btn.visible = false;
            cancel_btn.visible = false;
            dialog.hide();
        });

        return dialog;
    }

    protected Gtk.Widget? create_panel_area()
    {
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.BOTH);
        var label = new Gtk.Label("<big>Panel configuration</big>");
        label.halign = Gtk.Align.START;
        label.get_style_context().add_class("dim-label");
        label.set_use_markup(true);

        layout.pack_start(label, false, false, 0);
        var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        sep.margin_top = 12;
        sep.margin_bottom = 12;
        layout.pack_start(sep, false, false, 0);

        // gnome panel theme integration
        var check = new Gtk.Switch();
        settings.bind("gnome-panel-theme-integration", check, "active", SettingsBindFlags.DEFAULT);
        var item = create_action_item("GNOME Panel theme integration", "Enables a more traditional panel appearance", check);
        layout.pack_start(item, false, false, 0);

        // shadow for panel
        check = new Gtk.Switch();
        settings.bind("enable-shadow", check, "active", SettingsBindFlags.DEFAULT);
        item = create_action_item("Enable panel shadow", "Adds a shadow to the panels edge", check);
        layout.pack_start(item, false, false, 0);

        // panel position
        var combo = new Gtk.ComboBoxText();
        group.add_widget(combo);
        combo.insert(-1, "top", "Top");
        combo.insert(-1, "left", "Left");
        combo.insert(-1, "right", "Right");
        combo.insert(-1, "bottom", "Bottom");
        settings.bind("location", combo, "active-id", SettingsBindFlags.DEFAULT);
        item = create_action_item("Position on screen", null, combo);
        layout.pack_start(item, false, false, 0);

        // size
        var spin = new Gtk.SpinButton.with_range(15, 200, 1);
        group.add_widget(spin);
        settings.bind("size", spin, "value", SettingsBindFlags.DEFAULT);
        item = create_action_item("Size", null, spin);
        layout.pack_start(item, false, false, 0);

        // can haz autohide plox?
        combo = new Gtk.ComboBoxText();
        group.add_widget(combo);
        combo.insert(-1, "never", "Never");
        combo.insert(-1, "automatic", "Automatic");
        settings.bind("hide-policy", combo, "active-id", SettingsBindFlags.DEFAULT);
        item = create_action_item("Autohide policy", null, combo);
        layout.pack_start(item, false, false, 0);

        return layout;
    }

    protected Gtk.Widget? create_menu_area()
    {
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.BOTH);
        var label = new Gtk.Label("<big>Menu configuration</big>");
        label.halign = Gtk.Align.START;
        label.get_style_context().add_class("dim-label");
        label.set_use_markup(true);

        layout.pack_start(label, false, false, 0);
        var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        sep.margin_top = 12;
        sep.margin_bottom = 12;
        layout.pack_start(sep, false, false, 0);

        // show menu label?
        var check = new Gtk.Switch();
        settings.bind("enable-menu-label", check, "active", SettingsBindFlags.DEFAULT);
        var item = create_action_item("Menu label on panel", null, check);
        layout.pack_start(item, false, false, 0);

        // compact menu
        check = new Gtk.Switch();
        settings.bind("menu-compact", check, "active", SettingsBindFlags.DEFAULT);
        item = create_action_item("Compact menu", "Use a smaller menu with no category navigation", check);
        layout.pack_start(item, false, false, 0);

        // menu headers
        check = new Gtk.Switch();
        settings.bind("menu-headers", check, "active", SettingsBindFlags.DEFAULT);
        item = create_action_item("Category headers in menu", null, check);
        layout.pack_start(item, false, false, 0);

        // size
        var spin = new Gtk.SpinButton.with_range(16, 96, 1);
        group.add_widget(spin);
        settings.bind("menu-icons-size", spin, "value", SettingsBindFlags.DEFAULT);
        item = create_action_item("Icon size", "Set a size to use for icons in the menu.", spin);
        layout.pack_start(item, false, false, 0);

        // menu label
        var entry = new Gtk.Entry();
        group.add_widget(entry);
        settings.bind("menu-label", entry, "text", SettingsBindFlags.DEFAULT);
        item = create_action_item("Menu label", null, entry);
        layout.pack_start(item, false, false, 0);

        // menu icon
        entry = new Gtk.Entry();
        group.add_widget(entry);
        settings.bind("menu-icon", entry, "text", SettingsBindFlags.DEFAULT);
        item = create_action_item("Menu icon", null, entry);
        layout.pack_start(item, false, false, 0);

        return layout;
    }

    Gtk.Widget? create_action_item(string title, string? subtitle, Gtk.Widget? action_item)
    {
        Gtk.Box wrap = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        wrap.pack_start(layout, true, true, 0);

        var lab = new Gtk.Label(@"<b>$title</b>");
        lab.set_use_markup(true);

        layout.pack_start(lab, true, true, 0);
        lab.margin_right = 20;
        lab.valign = Gtk.Align.CENTER;
        lab.halign = Gtk.Align.START;

        if (subtitle != null) {
            lab = new Gtk.Label(@"<small>$subtitle</small>");
            lab.margin_right = 40;
            lab.set_use_markup(true);

            layout.pack_start(lab, true, true, 0);
            lab.valign = Gtk.Align.CENTER;
            lab.halign = Gtk.Align.START;
        }

        if (action_item != null) {
            action_item.valign = Gtk.Align.CENTER;
            action_item.halign = Gtk.Align.CENTER;
            wrap.pack_end(action_item, false, false, 0);
            wrap.margin_bottom = 12;
        } else {
            wrap.margin_bottom = 24;
        }

        return wrap;
    }

    Gtk.Widget? create_personalize_page()
    {
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.BOTH);
        var label = new Gtk.Label("<big>Personalise Budgie</big>");
        label.halign = Gtk.Align.START;
        label.get_style_context().add_class("dim-label");
        label.set_use_markup(true);

        layout.pack_start(label, false, false, 0);
        var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        sep.margin_top = 12;
        sep.margin_bottom = 12;
        layout.pack_start(sep, false, false, 0);

        var check = new Gtk.Switch();
        var item = create_action_item("Dark theme", "Activate the dark theme option for the Budgie desktop", check);
        settings.bind("dark-theme", check, "active", SettingsBindFlags.DEFAULT);
        layout.pack_start(item, false, false, 0);

        var combo = new Gtk.ComboBoxText();
        group.add_widget(combo);
        populate(ref combo, ThemeType.GTK_THEME);
        ui_settings.bind("gtk-theme", combo, "active-id", SettingsBindFlags.DEFAULT);
        item = create_action_item("Widget theme", "Select a widget (GTK+) theme to use for applications", combo);
        layout.pack_start(item, false, false, 0);

        combo = new Gtk.ComboBoxText();
        group.add_widget(combo);
        populate(ref combo, ThemeType.WM_THEME);
        wm_settings.bind("theme", combo, "active-id", SettingsBindFlags.DEFAULT);
        item = create_action_item("Window theme", null, combo);
        layout.pack_start(item, false, false, 0);

        combo = new Gtk.ComboBoxText();
        group.add_widget(combo);
        populate(ref combo, ThemeType.ICON_THEME);
        ui_settings.bind("icon-theme", combo, "active-id", SettingsBindFlags.DEFAULT);
        item = create_action_item("Icon theme", null, combo);
        layout.pack_start(item, false, false, 0);

        return layout;
    }

    /*
     * Because a working solution for array sorting was too much to ask for.
     * And Vala is on craq and makes all kinds of crazy-shit "optimizations"
     * such as dereferencing NULL pointers in if-checks for qsort, etc. Slow clap.
     */
    void sort_array(ref string[]? input)
    {
        if (input == null) {
            return;
        }
        int i = 0, length = input.length;
        bool sorting = true;
        while (sorting) {
            --length;
            sorting = false;
            for (i = 0; i < length; i++) {
                /* g_strdown could be spensive.. plus the g_strcmp0's  */
                if (i < input.length && input[i].down() > input[i+1].down()) {
                    var tmp = input[i];
                    input[i] = input[i+1];
                    input[i+1] = tmp;
                    sorting = true;
                }
            }
        }
    }

    /* This is kinda expensive - but we'll change it up in future .. */
    protected void populate(ref Gtk.ComboBoxText box, ThemeType type)
    {
        var spc = Environment.get_system_data_dirs();
        spc += Environment.get_user_data_dir();
        string[] search = {};
        string? item = "";
        string? suffix = "";
        string[] results = {};
        FileTest test_type = FileTest.IS_DIR;
        switch (type) {
            case ThemeType.GTK_THEME:
                item = "themes";
                suffix = "gtk-3.0";
                break;
            case ThemeType.WM_THEME:
                item = "themes";
                suffix = "metacity-1";
                break;
            case ThemeType.ICON_THEME:
                item = "icons";
                suffix = "index.theme";
                test_type = FileTest.IS_REGULAR;
                break;
            case ThemeType.CURSOR_THEME:
                item = "icons";
                suffix = "cursors";
                break;
            default:
                break;
        }
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
            FileInfo? fi;
            File f = File.new_for_path(dir);
            try {
                var files = f.enumerate_children("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
                while ((fi = files.next_file(null)) != null) {
                    var display_name = fi.get_display_name();
                    var test_path = dir + Path.DIR_SEPARATOR_S + display_name + Path.DIR_SEPARATOR_S + suffix;
                    if (!(display_name in results) && FileUtils.test(test_path, test_type)) {
                        results += display_name;
                    }
                }
            } catch (Error e) { }
        }

        /* Need to show these alphabetically */
        sort_array(ref results);

        foreach (var result in results) {
            box.append(result, result);
        }
    }
}

} // End namespace

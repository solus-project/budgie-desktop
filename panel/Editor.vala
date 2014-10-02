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

public class PanelEditor : Gtk.Dialog
{
    // Holds our content, basically.
    Gtk.ListBox content;

    // Because.
    Gtk.HeaderBar header;

    // Our applet config area
    Gtk.Grid applet_config;

    // Our panel reference
    unowned Budgie.Panel? panel;

    Gtk.ComboBox pack_type;
    Gtk.CheckButton is_status;
    Gtk.SpinButton pad_start;
    Gtk.SpinButton pad_end;

    // The real layout is just a stack.
    Gtk.Stack main_layout;

    // Wrap everything in a Notebook
    Gtk.Notebook book;

    // Currently selected AppletInfo
    unowned AppletInfo? current_info;

    // Currently selected PluginInfo
    unowned Peas.PluginInfo? current_plugin;

    protected Gtk.Button app_add_btn;
    protected Gtk.Button app_cancel_btn;

    protected Settings settings;

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

        settings = new Settings("com.evolve-os.budgie.panel");

        book = new Gtk.Notebook();
        get_content_area().pack_start(book, true, true, 0);

        var close = new Gtk.Button.with_label("Close");
        add_action_widget(close, Gtk.ResponseType.CLOSE);
        Gtk.Container owner = close.get_parent() as Gtk.Container;
        owner.child_set_property(close, "secondary", true);
        owner.set_border_width(0);
        owner.set_property("margin-left", 0);
        owner.set_property("margin-right", 0);
        owner.set_property("margin-top", 6);

        close.clicked.connect(()=> {
            destroy();
        });

        main_layout = new Gtk.Stack();
        main_layout.set_border_width(6);
        book.append_page(main_layout, new Gtk.Label("Applets"));
        // If someone switches to the other page, make sure we hide these now
        // undocumented behaviours..
        book.switch_page.connect((p, n)=> {
            if (n != 0) {
                app_add_btn.hide();
                app_cancel_btn.hide();
                main_layout.set_visible_child_name("main");
            }
        });
        set_size_request(400, 390);
        var sidesplit = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        main_layout.add_named(sidesplit, "main");

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
            main_layout.set_visible_child_name("add-applet");
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

        var sep = new Gtk.SeparatorToolItem();
        //tbar.add(sep);
        sep.set_draw(false);
        sep.set_expand(true);

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
        var label = new Gtk.Label("Place in status area");
        var is_status = new Gtk.CheckButton();
        this.is_status = is_status;
        is_status.halign = Gtk.Align.END;
        is_status.active = false;
        grid.attach(label, 0, 0, 1, 1);
        grid.attach(is_status, 1, 0, 1, 1);
        is_status_id = is_status.clicked.connect(()=> {
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
        label.set_alignment(0.0f, 0.5f);
        grid.attach(label, 0, 1, 1, 1);
        grid.attach(spinner, 1, 1, 1, 1);

        // Padding end
        spinner = new Gtk.SpinButton.with_range(0, 100, 1);
        label = new Gtk.Label("End padding");
        pad_end = spinner;
        label.set_alignment(0.0f, 0.5f);
        grid.attach(label, 0, 2, 1, 1);
        grid.attach(spinner, 1, 2, 1, 1);
        applet_config = grid;

        // pack type
        label = new Gtk.Label("Placement");
        label.set_alignment(0.0f, 0.5f);
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
        set_border_width(10);

        content.set_sort_func(on_sort);

        main_layout.add_named(create_applet_area(), "add-applet");
        main_layout.set_transition_type(Gtk.StackTransitionType.CROSSFADE);

        book.append_page(create_panel_area(), new Gtk.Label("Panel"));
        book.show_all();
        close.show();
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
        label.set_alignment(0.0f, 0.5f);
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

    /** Create the area used to add applets.. */
    protected Gtk.Widget? create_applet_area()
    {
        Gtk.ListBox rows = new Gtk.ListBox();
        Gtk.ScrolledWindow scroller = new Gtk.ScrolledWindow(null, null);
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scroller.set_shadow_type(Gtk.ShadowType.IN);
        scroller.add(rows);

        rows.set_sort_func(applet_sort);

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
            label.set_alignment(0.0f, 0.5f);

            row.set_data("plugin-info", plugin);
            row.show_all();
            rows.add(row);
        }

        var cancel_btn = new Gtk.Button.with_label("Cancel");
        add_action_widget(cancel_btn, Gtk.ResponseType.CANCEL);
        app_cancel_btn = cancel_btn;
        cancel_btn.visible = false;
        cancel_btn.clicked.connect(()=> {
            main_layout.set_visible_child_name("main");
            app_add_btn.visible = false;
            cancel_btn.visible = false;
        });

        var add_btn = new Gtk.Button.with_label("Add");
        add_action_widget(add_btn, Gtk.ResponseType.OK);
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
            main_layout.set_visible_child_name("main");
        });

        return scroller;
    }

    protected Gtk.Widget? create_panel_area()
    {
        Gtk.Grid wrap = new Gtk.Grid();
        wrap.valign = Gtk.Align.FILL;
        wrap.halign = Gtk.Align.FILL;
        wrap.set_border_width(6);

        wrap.row_spacing = 6;
        wrap.column_spacing = 30;

        // panel position
        var label = new Gtk.Label("Position on screen");
        label.hexpand = true;
        label.set_alignment(0.0f, 0.5f);
        var combo = new Gtk.ComboBoxText();
        combo.insert(-1, "top", "Top");
        combo.insert(-1, "left", "Left");
        combo.insert(-1, "right", "Right");
        combo.insert(-1, "bottom", "Bottom");
        settings.bind("location", combo, "active-id", SettingsBindFlags.DEFAULT);
        combo.valign = Gtk.Align.END;
        wrap.attach(label, 0, 0, 1, 1);
        wrap.attach(combo, 1, 0, 1, 1);

        // size
        label = new Gtk.Label("Size");
        label.set_alignment(0.0f, 0.5f);
        var spin = new Gtk.SpinButton.with_range(15, 200, 1);
        settings.bind("size", spin, "value", SettingsBindFlags.DEFAULT);
        spin.valign = Gtk.Align.END;
        wrap.attach(label, 0, 1, 1, 1);
        wrap.attach(spin, 1, 1, 1, 1);

        // gnome panel theme integration
        label = new Gtk.Label("GNOME Panel theme integration");
        label.set_alignment(0.0f, 0.5f);
        var check = new Gtk.Switch();
        settings.bind("gnome-panel-theme-integration", check, "active", SettingsBindFlags.DEFAULT);
        check.valign = Gtk.Align.START;
        wrap.attach(label, 0, 2, 1, 1);
        wrap.attach(check, 1, 2, 1, 1);

        return wrap;
    }
}

} // End namespace

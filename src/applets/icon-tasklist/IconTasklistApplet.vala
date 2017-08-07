/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2017 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class IconTasklist : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid) {
        return new IconTasklistApplet(uuid);
    }
}

[GtkTemplate (ui = "/com/solus-project/icon-tasklist/settings.ui")]
public class IconTasklistSettings : Gtk.Grid
{

    [GtkChild]
    private Gtk.Switch? switch_restrict;

    [GtkChild]
    private Gtk.Switch? switch_lock_icons;

    [GtkChild]
    private Gtk.Switch? switch_only_pinned;

    private GLib.Settings? settings;

    public IconTasklistSettings(GLib.Settings? settings)
    {
        this.settings = settings;
        settings.bind("restrict-to-workspace", switch_restrict, "active", SettingsBindFlags.DEFAULT);
        settings.bind("lock-icons", switch_lock_icons, "active", SettingsBindFlags.DEFAULT);
        settings.bind("only-pinned", switch_only_pinned, "active", SettingsBindFlags.DEFAULT);
    }

}

/**
 * Trivial helper for IconTasklist - i.e. desktop lookups
 */
public class DesktopHelper : Object
{
    public static GLib.Settings settings;
    public static Wnck.Screen screen;
    public static Gtk.Box icon_layout;
    public static bool lock_icons = false;

    public const Gtk.TargetEntry[] targets = {
        { "application/x-icon-tasklist-launcher-id", 0, 0 },
        { "text/uri-list", 0, 0 },
        { "application/x-desktop", 0, 0 }
    };

    public static void update_pinned()
    {
        string[] buttons = {};
        foreach (Gtk.Widget widget in icon_layout.get_children()) {
            IconButton button = (widget as ButtonWrapper).button;
            if (!button.get_pinned()) {
                continue;
            }
            if (button.get_appinfo() == null) {
                continue;
            }
            string id = button.get_appinfo().get_id();
            if (id in buttons) {
                continue;
            }
            buttons += id;
        }

        settings.set_strv("pinned-launchers", buttons);
    }

    public static GLib.List<unowned Wnck.Window> get_stacked_for_classgroup(Wnck.ClassGroup class_group)
    {
        GLib.List<unowned Wnck.Window> list = new GLib.List<unowned Wnck.Window>();
        screen.get_windows_stacked().foreach((window) => {
            if (window.get_class_group() == class_group && !window.is_skip_tasklist()) {
                if (window.get_workspace() == get_active_workspace()) {
                    list.append(window);
                }
            }
        });

        return list.copy();
    }

    public static Wnck.Window get_active_window() {
        return screen.get_active_window();
    }

    public static Wnck.Workspace get_active_workspace() {
        return screen.get_active_workspace();
    }
}

public class IconTasklistApplet : Budgie.Applet
{
    private GLib.HashTable<string, IconButton> buttons;
    private GLib.Settings settings;
    private Wnck.Screen screen;
    private Budgie.AppSystem app_system;
    private Gtk.Box main_layout;
    private int icon_size;
    private int panel_size;
    private Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;
    private bool only_show_pinned = false;
    private bool restrict_to_workspace = false;

    public string uuid { public set; public get; }

    public override Gtk.Widget? get_settings_ui() {
        return new IconTasklistSettings(this.get_applet_settings(uuid));
    }

    public override bool supports_settings() {
        return true;
    }

    public IconTasklistApplet(string uuid)
    {
        GLib.Object(uuid: uuid);

        Wnck.set_client_type(Wnck.ClientType.PAGER);

        screen = Wnck.Screen.get_default();
        DesktopHelper.screen = screen;
        app_system = new Budgie.AppSystem();

        settings_schema = "com.solus-project.icon-tasklist";
        settings_prefix = "/com/solus-project/budgie-panel/instance/icon-tasklist";

        settings = this.get_applet_settings(uuid);
        settings.changed.connect(on_settings_changed);
        DesktopHelper.settings = settings;
        buttons = new GLib.HashTable<string, IconButton>(str_hash, str_equal);
        main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        DesktopHelper.icon_layout = main_layout;
        main_layout.get_style_context().add_class("pinned");
        this.add(main_layout);

        startup();

        Gtk.drag_dest_set(main_layout, Gtk.DestDefaults.ALL, DesktopHelper.targets, Gdk.DragAction.COPY);
        main_layout.drag_data_received.connect(on_drag_data_received);

        app_system.app_launched.connect((desktop_file) => {
            GLib.DesktopAppInfo? info = new GLib.DesktopAppInfo.from_filename(desktop_file);
            if (info == null) {
                return;
            }
            if (buttons.contains(info.get_id())) {
                IconButton button = buttons[info.get_id()];
                if (!button.icon.waiting) {
                    button.icon.waiting = true;
                    button.icon.animate_wait();
                }
            }
        });

        on_settings_changed("restrict-to-workspace");
        on_settings_changed("lock-icons");
        on_settings_changed("only-pinned");

        this.get_style_context().add_class("icon-tasklist");
        this.show_all();
    }

    private void on_settings_changed(string key)
    {
        switch (key) {
            case "lock-icons":
                DesktopHelper.lock_icons = settings.get_boolean(key);
                break;
            case "restrict-to-workspace":
                this.restrict_to_workspace = settings.get_boolean(key);
                break;
            case "only-pinned":
                this.only_show_pinned = settings.get_boolean(key);
                break;
        }

        update_buttons();
    }

    private void update_buttons()
    {
        Idle.add(()=> {
            buttons.foreach((id, button) => {
                bool visible = true;

                if (this.restrict_to_workspace) {
                    visible = button.has_window_on_workspace(this.screen.get_active_workspace());
                }

                if (this.only_show_pinned) {
                    visible = button.get_pinned();
                }

                visible = visible || button.get_pinned();

                (button.get_parent() as Gtk.Revealer).set_reveal_child(visible);
                button.update();
            });
            return false;
        });
    }

    private void on_drag_data_received(Gtk.Widget widget, Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint item, uint time)
    {
        if (item != 0) {
            message("Invalid target type");
            return;
        }

        // id of app that is currently being dragged
        var app_id = (string)selection_data.get_data();
        ButtonWrapper? original_button = null;

        if (app_id.has_prefix("file://")) {
            app_id = app_id.split("://")[1];
            stdout.printf(app_id + "\n");
            GLib.DesktopAppInfo? info = new GLib.DesktopAppInfo.from_filename(app_id.strip());
            if (info == null) {
                stdout.printf("info was null\n");
                return;
            }
            app_id = info.get_id();
            if (buttons.contains(app_id)) {
                original_button = (buttons[app_id].get_parent() as ButtonWrapper);
            } else {
                IconButton button = new IconButton(null, info);
                button.panel_size = this.panel_size;
                button.icon_size = this.icon_size;
                button.orient = this.get_orientation();
                button.panel_position = this.panel_position;
                button.set_pinned(true);
                button.update();

                buttons.set(app_id, button);
                original_button = new ButtonWrapper(button);
                original_button.orient = this.get_orientation();
                button.became_empty.connect(() => {
                    buttons.remove(app_id);
                    original_button.gracefully_die();
                });
                main_layout.pack_start(original_button, false, false, 0);
            }
        } else {
            if (!buttons.contains(app_id)) {
                return;
            }
            original_button = (buttons[app_id].get_parent() as ButtonWrapper);
        }

        if (original_button == null) {
            return;
        }

        // Iterate through launchers
        foreach (Gtk.Widget widget1 in main_layout.get_children()) {
            ButtonWrapper current_button = (widget1 as ButtonWrapper);

            Gtk.Allocation alloc;

            current_button.get_allocation(out alloc);

            if ((get_orientation() == Gtk.Orientation.HORIZONTAL && x <= (alloc.x + (alloc.width / 2))) ||
                (get_orientation() == Gtk.Orientation.VERTICAL && y <= (alloc.y + (alloc.height / 2))))
            {
                int new_position, old_position;
                main_layout.child_get(original_button, "position", out old_position, null);
                main_layout.child_get(current_button, "position", out new_position, null);

                if (new_position == old_position) {
                    break;
                }

                if (new_position == old_position + 1) {
                    break;
                }

                if (new_position > old_position) {
                    new_position = new_position - 1;
                }

                main_layout.reorder_child((buttons[app_id].get_parent() as ButtonWrapper), new_position);
                break;
            }

            if ((get_orientation() == Gtk.Orientation.HORIZONTAL && x <= (alloc.x + alloc.width)) ||
                (get_orientation() == Gtk.Orientation.VERTICAL && y <= (alloc.y + alloc.height)))
            {
                int new_position, old_position;
                main_layout.child_get(original_button, "position", out old_position, null);
                main_layout.child_get(current_button, "position", out new_position, null);

                if (new_position == old_position) {
                    break;
                }

                if (new_position == old_position - 1) {
                    break;
                }

                if (new_position < old_position) {
                    new_position = new_position + 1;
                }

                main_layout.reorder_child((buttons[app_id].get_parent() as ButtonWrapper), new_position);
                break;
            }
        }
        original_button.set_transition_type(Gtk.RevealerTransitionType.NONE);
        original_button.set_reveal_child(true);

        DesktopHelper.update_pinned();

        Gtk.drag_finish(context, true, true, time);
    }

    void set_icons_size()
    {
        Wnck.set_default_icon_size(this.icon_size);

        Idle.add(()=> {
            buttons.foreach((id, button) => {
                button.icon_size = this.icon_size;
                button.panel_size = this.panel_size;
                button.panel_position = this.panel_position;
                button.orient = this.get_orientation();
                (button.get_parent() as ButtonWrapper).orient = this.get_orientation();
                button.update_icon();
            });
            return false;
        });

        queue_resize();
        queue_draw();
    }

    public override void panel_position_changed(Budgie.PanelPosition position) {
        this.panel_position = position;
        main_layout.set_orientation(get_orientation());

        set_icons_size();
    }

    public override void panel_size_changed(int panel, int icon, int small_icon)
    {
        this.icon_size = small_icon;

        panel_size = panel - 1;
        if (get_orientation() == Gtk.Orientation.HORIZONTAL) {
            panel_size = panel - 6;
        }

        set_icons_size();
    }

    private void window_opened(Wnck.Window window)
    {
        if (window.is_skip_tasklist()) {
            return;
        }

        window.state_changed.connect_after(() => {
            if (window.needs_attention()) {
                buttons.foreach((id, button) => {
                    if (button.has_window(window)) {
                        button.attention();
                    }
                });
            }
        });

        Wnck.ClassGroup class_group = window.get_class_group();
        GLib.DesktopAppInfo? info = app_system.query_window(window);

        if (class_group == null) {
            return;
        }

        string id;

        if (info != null) {
            id = info.get_id();
        } else {
            id = class_group.get_id();
        }

        if (buttons.contains(id)) {
            IconButton button = buttons.get(id);
            if (button.class_group == null) {
                button.class_group = class_group;
            }
            button.update();
        } else {
            IconButton button = new IconButton(class_group, info);
            button.panel_size = this.panel_size;
            button.icon_size = this.icon_size;
            button.orient = this.get_orientation();
            button.panel_position = this.panel_position;
            button.update();

            buttons.set(id, button);
            ButtonWrapper button_wrapper = new ButtonWrapper(button);
            button_wrapper.orient = this.get_orientation();
            button.became_empty.connect(() => {
                buttons.remove(id);
                button_wrapper.gracefully_die();
            });
            main_layout.pack_start(button_wrapper, false, false, 0);
            button_wrapper.set_reveal_child(true);
        }
    }

    private void window_closed(Wnck.Window window)
    {
        if (window.is_skip_tasklist()) {
            return;
        }
        GLib.Idle.add(() => {
            buttons.foreach((id, button) => {
                button.update();
            });
            return false;
        });
    }

    private void active_window_changed()
    {
        Wnck.Window active_window = screen.get_active_window();

        buttons.foreach((id, button) => {
            button.set_active(button.has_window(active_window));
            button.update();
            if (button.has_window(active_window)) {
                button.attention(false);
            }
        });
    }

    private void connect_signals()
    {
        screen.window_opened.connect_after(window_opened);
        screen.window_closed.connect_after(window_closed);
        screen.active_window_changed.connect_after(active_window_changed);
        screen.active_workspace_changed.connect_after(update_buttons);
    }

    private void startup()
    {
        string[] launchers = settings.get_strv("pinned-launchers");

        foreach (string id in launchers) {
            GLib.DesktopAppInfo? info = new GLib.DesktopAppInfo(id);
            if (info == null) {
                continue;
            }
            IconButton button = new IconButton(null, info, true);
            button.panel_size = this.panel_size;
            button.icon_size = this.icon_size;
            button.orient = this.get_orientation();
            button.panel_position = this.panel_position;
            button.update();
            buttons.set(info.get_id(), button);
            ButtonWrapper button_wrapper = new ButtonWrapper(button);
            button_wrapper.orient = this.get_orientation();
            button.became_empty.connect(() => {
                buttons.remove(info.get_id());
                button_wrapper.gracefully_die();
            });
            main_layout.pack_start(button_wrapper, false, false, 0);
            button_wrapper.set_reveal_child(true);
        }

        GLib.Idle.add(() => {
            screen.get_windows().foreach((window) => {
                window_opened(window);
            });
            return false;
        });

        GLib.Timeout.add(2000, () => {
            connect_signals();
            return false;
        });
    }

    private Gtk.Orientation get_orientation() {
        switch (this.panel_position) {
            case Budgie.PanelPosition.TOP:
            case Budgie.PanelPosition.BOTTOM:
                return Gtk.Orientation.HORIZONTAL;
            default:
                return Gtk.Orientation.VERTICAL;
        }
    }
}

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(IconTasklist));
}

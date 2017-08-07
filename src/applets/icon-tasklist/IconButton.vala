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

/**
 * Default opacity when beginning urgency cycles in the launcher
 */
const double DEFAULT_OPACITY = 0.1;
const int INDICATOR_SIZE     = 2;
const int INDICATOR_SPACING  = 2;

public class ButtonWrapper : Gtk.Revealer
{
    public unowned IconButton? button;

    public Gtk.Orientation orient {
        set {
            if (value == Gtk.Orientation.VERTICAL) {
                this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
            } else {
                this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);
            }
        }
        get {
            if (this.get_transition_type() == Gtk.RevealerTransitionType.SLIDE_DOWN) {
                return Gtk.Orientation.VERTICAL;
            }
            return Gtk.Orientation.HORIZONTAL;
        }
    }

    public ButtonWrapper(IconButton? button)
    {
        this.button = button;
        this.add(button);
        this.set_reveal_child(false);
        this.show_all();
    }

    public void gracefully_die()
    {
        if (!get_settings().gtk_enable_animations) {
            this.destroy();
            return;
        }

        if (this.orient == Gtk.Orientation.HORIZONTAL) {
            this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_LEFT);
        } else {
            this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
        }
        this.notify["child-revealed"].connect_after(()=> {
            this.destroy();
        });
        this.set_reveal_child(false);
    }
}

public class IconButton : Gtk.ToggleButton
{
    public Wnck.ClassGroup? class_group = null;
    private GLib.DesktopAppInfo? app_info = null;
    private Gdk.AppLaunchContext launch_context;
    private bool pinned;
    private Gtk.Menu menu;
    private Gtk.Allocation definite_allocation;
    public Icon icon;
    private int64 last_scroll_time = 0;
    private bool context_menu_has_items = false;

    public int panel_size = 39;
    public int icon_size = 24;
    public Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;
    public Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;
    private bool needs_attention = false;

    public signal void became_empty();

    public IconButton(Wnck.ClassGroup? group, GLib.DesktopAppInfo? info, bool pinned = false)
    {
        this.class_group = group;
        this.app_info = info;
        this.pinned = pinned;
        this.launch_context = this.get_display().get_app_launch_context();

        this.add_events(Gdk.EventMask.SCROLL_MASK);

        definite_allocation.width = 0;
        definite_allocation.height = 0;

        icon = new Icon();
        this.add(icon);

        var st = get_style_context();
        st.remove_class(Gtk.STYLE_CLASS_BUTTON);
        st.remove_class("toggle");
        st.add_class("launcher");
        relief = Gtk.ReliefStyle.NONE;

        this.show_all();

        launch_context.launched.connect(this.on_launched);
        launch_context.launch_failed.connect(this.on_launch_failed);

        // Drag and drop
        this.set_draggable(!DesktopHelper.lock_icons);

        drag_begin.connect((context) => {
            unowned Gdk.Pixbuf? pixbuf_icon = this.icon.pixbuf;

            if (pixbuf_icon != null) {
                Gtk.drag_set_icon_pixbuf(context, pixbuf_icon, (pixbuf_icon.width / 2), (pixbuf_icon.height / 2));
            } else {
                Gtk.drag_set_icon_default(context);
            }
        });

        drag_data_get.connect((widget, context, selection_data, info, time)=> {
            string id;
            if (this.app_info != null) {
                id = this.app_info.get_id();
            } else {
                id = this.class_group.get_id();
            }
            selection_data.set(selection_data.get_target(), 8, (uchar[])id.to_utf8());
        });

        /*
         * Deactive the button after clicking on it because we use the
         * active_window_changed signal to decide which button to activate
         */
        this.button_release_event.connect_after((event) => {
            if (event.button != 2) {
                this.set_active(false);
            }
            return false;
        });
    }

    public override bool scroll_event(Gdk.EventScroll event) {
        if (class_group == null) {
            return Gdk.EVENT_STOP;
        }

        if (event.direction >= 4) {
            return Gdk.EVENT_STOP;
        }

        if (GLib.get_monotonic_time() - last_scroll_time < 300000) {
            return Gdk.EVENT_STOP;
        }

        Wnck.Window? target_window = null;

        if (event.direction == Gdk.ScrollDirection.DOWN) {
            target_window = this.get_next_window();
        } else if (event.direction == Gdk.ScrollDirection.UP) {
            target_window = this.get_previous_window();
        }

        if (target_window != null) {
            target_window.activate(event.time);
            last_scroll_time = GLib.get_monotonic_time();
        }

        return Gdk.EVENT_STOP;
    }

    private Wnck.Window get_next_window()
    {
        Wnck.Window target_window = class_group.get_windows().first().data;

        bool found_active = false;
        foreach (Wnck.Window window in class_group.get_windows()) {
            if (found_active && !window.is_skip_tasklist()) {
                target_window = window;
                break;
            }

            if (window == DesktopHelper.get_active_window()) {
                found_active = true;
            }
        }

        return target_window;
    }

    private Wnck.Window get_previous_window() {
        GLib.List<unowned Wnck.Window> list = class_group.get_windows().copy();
        list.reverse();
        Wnck.Window target_window = list.first().data;

        bool found_active = false;
        foreach (Wnck.Window window in list) {
            if (found_active && !window.is_skip_tasklist()) {
                target_window = window;
                break;
            }

            if (window == DesktopHelper.get_active_window()) {
                found_active = true;
            }
        }

        return target_window;
    }

    /**
     * Handle startup notification, set our own ID to the ID selected
     */
    private void on_launched(GLib.AppInfo info, Variant v)
    {
        GLib.Variant? elem;

        var iter = v.iterator();

        while ((elem = iter.next_value()) != null) {
            string? key = null;
            GLib.Variant? val = null;

            elem.get("{sv}", out key, out val);

            if (key == null) {
                continue;
            }

            if (!val.is_of_type(GLib.VariantType.STRING)) {
                continue;
            }

            if (key != "startup-notification-id") {
                continue;
            }

            this.get_display().notify_startup_complete(val.get_string());
        }
    }

    private void on_launch_failed(string id) {
        warning("launch_failed");
        this.get_display().notify_startup_complete(id);
    }

    public override bool draw(Cairo.Context cr)
    {
        int x = definite_allocation.x;
        int y = definite_allocation.y;
        int width = definite_allocation.width;
        int height = definite_allocation.height;

        int count;
        if (!this.has_valid_windows(out count)) {
            return base.draw(cr);
        }

        double opacity = 0.3;

        if (this.get_active() || this.needs_attention) {
            opacity = 1;
        }

        var wid = new Gtk.Button();
        Gdk.RGBA col = wid.get_style_context().get_background_color(Gtk.StateFlags.ACTIVE);
        if (needs_attention) {
            col.parse("#D84E4E");
        }

        int counter = 0;
        class_group.get_windows().foreach((window) => {
            if (!window.is_skip_tasklist()) {
                int indicator_x = 0;
                int indicator_y = 0;
                switch (this.panel_position) {
                    case Budgie.PanelPosition.TOP:
                        indicator_x = x + (width / 2);
                        indicator_x -= ((count * (INDICATOR_SIZE + INDICATOR_SPACING)) / 2) - INDICATOR_SPACING;
                        indicator_x += (((INDICATOR_SIZE) + INDICATOR_SPACING) * counter);
                        indicator_y = y + (INDICATOR_SIZE / 2);
                        break;
                    case Budgie.PanelPosition.BOTTOM:
                        indicator_x = x + (width / 2);
                        indicator_x -= ((count * (INDICATOR_SIZE + INDICATOR_SPACING)) / 2) - INDICATOR_SPACING;
                        indicator_x += (((INDICATOR_SIZE) + INDICATOR_SPACING) * counter);
                        indicator_y = y + height - (INDICATOR_SIZE / 2);
                        break;
                    case Budgie.PanelPosition.LEFT:
                        indicator_y = x + (height / 2);
                        indicator_y -= ((count * (INDICATOR_SIZE + INDICATOR_SPACING)) / 2) - (INDICATOR_SPACING * 2);
                        indicator_y += (((INDICATOR_SIZE) + INDICATOR_SPACING) * counter);
                        indicator_x = y + (INDICATOR_SIZE / 2);
                        break;
                    case Budgie.PanelPosition.RIGHT:
                        indicator_y = x + (height / 2);
                        indicator_y -= ((count * (INDICATOR_SIZE + INDICATOR_SPACING)) / 2) - INDICATOR_SPACING;
                        indicator_y += ((INDICATOR_SIZE + INDICATOR_SPACING) * counter);
                        indicator_x = y + width - (INDICATOR_SIZE / 2);
                        break;
                    default:
                        break;
                }

                cr.set_source_rgba(col.red, col.green, col.blue, opacity);
                cr.arc(indicator_x, indicator_y, INDICATOR_SIZE, 0, Math.PI * 2);
                cr.fill();
                counter++;
            }
        });

        return base.draw(cr);
    }

    public override void size_allocate(Gtk.Allocation allocation) {
        definite_allocation.x = allocation.x;
        definite_allocation.y = allocation.y;

        base.size_allocate(definite_allocation);

        if (class_group == null) {
            return;
        }

        int x, y;
        var toplevel = get_toplevel();
        translate_coordinates(toplevel, 0, 0, out x, out y);
        toplevel.get_window().get_root_coords(x, y, out x, out y);

        class_group.get_windows().foreach((window) => {
            window.set_icon_geometry(x, y, definite_allocation.width, definite_allocation.height);
        });
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        /* Stop GTK from bitching */
        int m, n;
        base.get_preferred_width(out m, out n);

        int width = this.panel_size;
        if (this.orient == Gtk.Orientation.HORIZONTAL) {
            width += 6;
        }
        min = nat = definite_allocation.width = width;
    }

    public override void get_preferred_height(out int min, out int nat)
    {
        /* Stop GTK from bitching */
        int m, n;
        base.get_preferred_height(out m, out n);

        min = nat = definite_allocation.height = this.panel_size;
    }

    private void launch_app(uint32 time)
    {
        if (app_info == null) {
            return;
        }

        if (this.icon.waiting) {
            return;
        }

        this.icon.animate_launch(this.panel_position);
        this.icon.waiting = true;
        this.icon.animate_wait();

        launch_context.set_screen(this.get_screen());
        launch_context.set_timestamp(time);

        try {
            app_info.launch(null, launch_context);
        } catch (GLib.Error e) {
            warning(e.message);
        }
    }

    public override bool button_release_event(Gdk.EventButton event)
    {
        if (event.button == 1) {
            if (class_group == null) {
                launch_app(event.time);
            } else {
                bool all_unminimized = true;
                bool one_active = false;
                int num = 0;

                GLib.List<unowned Wnck.Window> list = DesktopHelper.get_stacked_for_classgroup(this.class_group);

                foreach (Wnck.Window window in list) {
                    if (window.is_minimized()) {
                        all_unminimized = false;
                    }
                    if (window.is_active()) {
                        one_active = true;
                    }
                    num++;
                }
                if (num > 0) { // we have windows on this workspace
                    /*
                     * Operations are restricted to the current workspace
                     * because that makes the most sense.
                     * If all windows are visible (unminimized):
                     *   If there is one active window:
                     *     minimize all windows
                     *   else:
                     *     activate all windows
                     * else:
                     *   activate all minimized windows
                     */

                    list.foreach((w) => {
                        if (all_unminimized) {
                            if (one_active) {
                                w.minimize();
                            } else {
                                w.activate(event.time);
                            }
                        } else if (w.is_minimized()) {
                            w.unminimize(event.time);
                            w.activate(event.time);
                        }
                    });
                } else {
                    /* Activate the first window in the group (on another workspace) */
                    class_group.get_windows().first().data.activate(event.time);
                }
            }
        } else if (event.button == 2) {
            launch_app(event.time);
        }

        return base.button_release_event(event);
    }

    public override bool button_press_event(Gdk.EventButton event) {
        if (event.button == 3 && context_menu_has_items) {
            menu.popup(null, null, null, event.button, event.time);
        }
        return base.button_press_event(event);
    }

    private void update_context_menu()
    {
        menu = new Gtk.Menu();

        context_menu_has_items = false;

        if (!DesktopHelper.lock_icons && this.app_info != null) {
            Gtk.CheckMenuItem pinned_item = new Gtk.CheckMenuItem.with_mnemonic(_("Pinned"));
            menu.append(pinned_item);
            pinned_item.show();
            context_menu_has_items = true;
            pinned_item.set_active(pinned);

            pinned_item.toggled.connect(() => {
                this.pinned = pinned_item.get_active();
                DesktopHelper.update_pinned();
                if (!has_valid_windows(null) && !this.pinned) {
                    became_empty();
                    return;
                }
            });
        }

        int num_windows;

        if (has_valid_windows(out num_windows)) {
            Gtk.MenuItem close_item = new Gtk.MenuItem.with_label((num_windows > 1) ? _("Close all") : _("Close"));
            menu.append(close_item);
            close_item.show();
            context_menu_has_items = true;

            close_item.activate.connect(() => {
                if (class_group == null) {
                    return;
                }

                class_group.get_windows().foreach((window) => {
                    var timestamp = Gtk.get_current_event_time();
                    window.close(timestamp);
                });
            });
        }

        if (app_info != null) {
            // Desktop app actions =)
            unowned string[] actions = app_info.list_actions();
            if (actions.length != 0) {
                Gtk.SeparatorMenuItem sep = new Gtk.SeparatorMenuItem();
                menu.append(sep);
                sep.show();
                foreach (var action in actions) {
                    var display_name = app_info.get_action_name(action);
                    var item = new Gtk.MenuItem.with_label(display_name);
                    item.set_data("__aname", action);
                    item.activate.connect(() => {
                        string? act = item.get_data("__aname");
                        if (act == null) {
                            return;
                        }
                        // Never know.
                        if (app_info == null) {
                            return;
                        }
                        launch_context.set_screen(get_screen());
                        launch_context.set_timestamp(Gdk.CURRENT_TIME);
                        app_info.launch_action(act, launch_context);
                    });
                    item.show_all();
                    context_menu_has_items = true;
                    menu.append(item);
                }
            }
        }

        if (has_valid_windows(out num_windows) && num_windows > 1) {
            Gtk.SeparatorMenuItem sep = new Gtk.SeparatorMenuItem();
            menu.append(sep);
            sep.show();
            foreach (Wnck.Window window in class_group.get_windows()) {
                if (window.is_skip_tasklist()) {
                    continue;
                }
                string title = window.get_name();
                if (title.length > 35) {
                    title = title[0:35] + "…";
                }
                Gtk.ImageMenuItem window_item = new Gtk.ImageMenuItem.with_label(title);
                window_item.set_tooltip_text(window.get_name());
                window_item.set_sensitive(window != DesktopHelper.get_active_window());
                window_item.always_show_image = true;
                window_item.set_image(get_icon());
                menu.append(window_item);
                window_item.show();
                context_menu_has_items = true;

                window_item.activate.connect(() => {
                    window.activate(Gtk.get_current_event_time());
                });
            }
        }
    }

    private Gtk.Image get_icon()
    {
        unowned GLib.Icon? app_icon = null;
        if (app_info != null) {
            app_icon = app_info.get_icon();
            if (app_icon != null) {
                return new Gtk.Image.from_gicon(app_icon, Gtk.IconSize.MENU);
            }
        }

        unowned Gdk.Pixbuf? pixbuf_icon = null;
        if (class_group != null) {
            pixbuf_icon = class_group.get_icon();
            if (pixbuf_icon != null) {
                return new Gtk.Image.from_pixbuf(pixbuf_icon);
            }
        }

        return new Gtk.Image.from_icon_name("image-missing", Gtk.IconSize.MENU);
    }

    /**
     * Update the icon
     */
    public void update_icon()
    {
        if (has_valid_windows(null)) {
            this.icon.waiting = false;
        } else if (!this.pinned) {
            became_empty();
        }

        unowned GLib.Icon? app_icon = null;
        if (app_info != null) {
            app_icon = app_info.get_icon();
        }

        unowned Gdk.Pixbuf? pixbuf_icon = null;
        if (class_group != null) {
            pixbuf_icon = class_group.get_icon();
        }

        if (app_icon != null) {
            icon.set_from_gicon(app_icon, this.icon_size);
        } else if (pixbuf_icon != null) {
            icon.set_from_pixbuf(pixbuf_icon, this.icon_size);
        } else {
            icon.set_from_icon_name("image-missing", this.icon_size);
        }

        this.queue_resize();
        this.queue_draw();
    }

    public void update() {
        if (class_group != null) {
            if (!has_valid_windows(null)) {
                if (!this.pinned) {
                    became_empty();
                    return;
                } else {
                    class_group = null;
                }
            }
        }

        if (has_valid_windows(null) && this.app_info != null) {
            this.set_tooltip_text(this.app_info.get_display_name());
        } else if (this.app_info != null) {
            this.set_tooltip_text(_("Launch %s").printf(this.app_info.get_display_name()));
        } else {
            this.set_tooltip_text(this.class_group.get_name());
        }

        this.set_draggable(!DesktopHelper.lock_icons);

        update_context_menu();
        update_icon();
    }

    private bool has_valid_windows(out int num_windows)
    {
        int n;
        num_windows = n = 0;

        if (class_group == null) {
            return false;
        }

        bool has_valid = false;
        class_group.get_windows().foreach((window) => {
            if (!window.is_skip_tasklist()) {
                has_valid = true;
                n++;
            }
        });

        num_windows = n;
        return has_valid;
    }

    public bool has_window(Wnck.Window? window)
    {
        if (class_group == null) {
            return false;
        }

        if (window == null) {
            return false;
        }

        bool has = false;
        class_group.get_windows().foreach((w) => {
            if (w == window) {
                has = true;
                return;
            }
        });

        return has;
    }

    public bool has_window_on_workspace(Wnck.Workspace workspace)
    {
        if (class_group == null || workspace == null) {
            return false;
        }

        bool has = false;
        class_group.get_windows().foreach((w) => {
            if (!w.is_skip_tasklist() && w.is_on_workspace(workspace)) {
                has = true;
                return;
            }
        });

        return has;
    }

    public void attention(bool needs_it = true)
    {
        this.needs_attention = needs_it;
        this.queue_draw();
        if (needs_it) {
            this.icon.animate_attention(this.panel_position);
        }
    }

    public bool get_pinned() {
        return this.pinned;
    }

    public void set_pinned(bool pinned) {
        this.pinned = pinned;
    }

    private void set_draggable(bool draggable)
    {
        if (draggable) {
            Gtk.drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, DesktopHelper.targets, Gdk.DragAction.COPY);
        } else {
            Gtk.drag_source_unset(this);
        }
    }

    public GLib.DesktopAppInfo? get_appinfo() {
        return this.app_info;
    }
}
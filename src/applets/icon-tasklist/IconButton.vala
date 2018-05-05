/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2018 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const double DEFAULT_OPACITY = 0.1;
const int INDICATOR_SIZE     = 2;
const int INDICATOR_SPACING  = 1;
const int INACTIVE_INDICATOR_SPACING = 2;

/**
 * The wrapper provides nice visual effects to house an IconButton, allowing
 * us to slide the buttons into view when ready, and dispose of them as and
 * when our slide-out animation has finished. Without the wrapper, we'd have
 * a very ugly effect of icons just "popping" off.
 */
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

/**
 * IconButton provides the pretty IconTasklist button to house one or more
 * windows in a group, as well as selection capabilities, interaction, animations
 * and rendering of "dots" for the renderable windows.
 */
public class IconButton : Gtk.ToggleButton
{
    private Wnck.Window? window = null;          // This will always be null if grouping is enabled
    private Wnck.ClassGroup? class_group = null; // This will always be null if grouping is disabled
    private GLib.DesktopAppInfo? app_info = null;
    public Icon icon;
    private Gtk.Allocation definite_allocation;
    private bool pinned = false;
    private bool is_from_window = false;
    private Gdk.AppLaunchContext launch_context;
    private int64 last_scroll_time = 0;
    public Wnck.Window? last_active_window = null;
    private bool needs_attention = false;
    private bool context_menu_has_items = false;
    private Gtk.Menu? menu = null;
    public signal void became_empty();

    /* Pointer to our DesktopHelper at the time of construction */
    public unowned DesktopHelper? desktop_helper { public set; public get; default = null; }

    /**
     * We have race conditions in glib between the desired properties..
     */
    private void gobject_constructors_suck()
    {
        icon = new Icon();
        icon.get_style_context().add_class("icon");
        this.add(icon);

        definite_allocation.width = 0;
        definite_allocation.height = 0;

        this.launch_context = this.get_display().get_app_launch_context();
        this.add_events(Gdk.EventMask.SCROLL_MASK);
        this.set_draggable(!this.desktop_helper.lock_icons);

        /*
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
                id = this.window.get_name();
            }
            selection_data.set(selection_data.get_target(), 8, (uchar[])id.to_utf8());
        });*/

        var st = get_style_context();
        st.remove_class(Gtk.STYLE_CLASS_BUTTON);
        st.remove_class("toggle");
        st.add_class("launcher");
        this.relief = Gtk.ReliefStyle.NONE;

        launch_context.launched.connect(this.on_launched);
        launch_context.launch_failed.connect(this.on_launch_failed);
    }

    public IconButton(DesktopHelper? helper, GLib.DesktopAppInfo info, bool pinned)
    {
        Object(desktop_helper: helper);
        this.app_info = info;
        this.pinned = pinned;
        gobject_constructors_suck();
        update_icon();
    }

    public IconButton.from_window(DesktopHelper? helper, Wnck.Window window, GLib.DesktopAppInfo? info, bool pinned = false)
    {
        Object(desktop_helper: helper);

        this.window = window;
        this.app_info = info;
        this.is_from_window = true;
        this.pinned = pinned;

        gobject_constructors_suck();

        window.state_changed.connect_after(() => {
            if (window.needs_attention()) {
                attention();
            }
        });

        update_icon();

        if (has_valid_windows(null)) {
            this.get_style_context().add_class("running");
        }
    }

    public IconButton.from_group(DesktopHelper? helper, Wnck.ClassGroup class_group, GLib.DesktopAppInfo? info)
    {
        Object(desktop_helper: helper);

        this.class_group = class_group;
        this.app_info = info;

        gobject_constructors_suck();

        foreach (unowned Wnck.Window window in class_group.get_windows()) {
            window.state_changed.connect_after(() => {
                if (window.needs_attention()) {
                    attention();
                }
            });
        }   

        update_icon();

        if (has_valid_windows(null)) {
            this.get_style_context().add_class("running");
        }
    }

    public void set_class_group(Wnck.ClassGroup? class_group) {
        this.class_group = class_group;

        if (class_group == null) {
            return;
        }

        foreach (unowned Wnck.Window window in class_group.get_windows()) {
            window.state_changed.connect_after(() => {
                if (window.needs_attention()) {
                    attention();
                }
            });
        }
    }

    public void set_wnck_window(Wnck.Window? window) {
        this.window = window;

        if (window == null) {
            return;
        }

        window.state_changed.connect_after(() => {
            if (window.needs_attention()) {
                attention();
            }
        });
    }

    public void set_draggable(bool draggable)
    {
        if (draggable) {
            Gtk.drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, DesktopHelper.targets, Gdk.DragAction.COPY);
        } else {
            Gtk.drag_source_unset(this);
        }
    }

    private Gtk.Image get_icon()
    {
        unowned GLib.Icon? app_icon = null;
        if (this.app_info != null) {
            app_icon = this.app_info.get_icon();
            if (app_icon != null) {
                return new Gtk.Image.from_gicon(app_icon, Gtk.IconSize.MENU);
            }
        }

        unowned Gdk.Pixbuf? pixbuf_icon = null;
        if (this.window != null) {
            pixbuf_icon = this.window.get_icon();
        }
        if (this.class_group != null) {
            pixbuf_icon = this.class_group.get_icon();
        }

        if (pixbuf_icon != null) {
            return new Gtk.Image.from_pixbuf(pixbuf_icon);
        }

        return new Gtk.Image.from_icon_name("image-missing", Gtk.IconSize.MENU);
    }

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
        if (this.window != null) {
            pixbuf_icon = this.window.get_icon();
        }
        if (class_group != null) {
            pixbuf_icon = class_group.get_icon();
        }

        if (app_icon != null) {
            icon.set_from_gicon(app_icon, Gtk.IconSize.INVALID);
        } else if (pixbuf_icon != null) {
            icon.set_from_pixbuf(pixbuf_icon);
        } else {
            icon.set_from_icon_name("image-missing", Gtk.IconSize.INVALID);
        }
        icon.pixel_size = this.desktop_helper.icon_size;
    }

    public void update()
    {
        if (!has_valid_windows(null)) {
            this.get_style_context().remove_class("running");
            if (!this.pinned || this.is_from_window) {
                became_empty();
                return;
            } else {
                class_group = null;
            }
        } else {
            this.get_style_context().add_class("running");
        }

        bool has_active = false;
        if (this.window != null) {
            has_active = this.window.is_active();
        } else if (class_group != null) {
            has_active = (class_group.get_windows().find(this.desktop_helper.get_active_window()) != null);
        }
        this.set_active(has_active);

        if (has_valid_windows(null) && this.app_info != null) {
            this.set_tooltip_text(this.app_info.get_display_name());
        } else if (this.app_info != null) {
            this.set_tooltip_text("Launch %s".printf(this.app_info.get_display_name()));
        } else {
            if (class_group != null) {
                this.set_tooltip_text(this.class_group.get_name());
            } else if (this.window != null) {
                this.set_tooltip_text(this.window.get_name());
            }
        }

        this.set_draggable(!this.desktop_helper.lock_icons);

        update_context_menu();
        update_icon();
        this.queue_resize();
        this.queue_draw();
    }

    private bool has_valid_windows(out int num_windows)
    {
        int n;
        num_windows = n = 0;

        if (class_group == null) {
            num_windows = 1;
            return (this.window != null);
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
        if (window == null) {
            return false;
        }

        if (this.window != null) {
            return (this.window == window);
        }

        if (class_group == null) {
            return false;
        }

        foreach (Wnck.Window win in class_group.get_windows()) {
            if (win == window) {
                return true;
            }
        }

        return false;
    }

    public bool has_window_on_workspace(Wnck.Workspace workspace)
    {
        if (workspace == null) {
            return false;
        }

        if (this.window != null) {
            return (!this.window.is_skip_tasklist() && this.window.is_on_workspace(workspace));
        } else if (class_group != null) {
            foreach (Wnck.Window win in class_group.get_windows()) {
                if (!win.is_skip_tasklist() && win.is_on_workspace(workspace)) {
                    return true;
                }
            }
        }

        return false;
    }

    private void launch_app(uint32 time)
    {
        if (app_info == null) {
            return;
        }

        launch_context.set_screen(this.get_screen());
        launch_context.set_timestamp(time);

        this.icon.animate_launch(this.desktop_helper.panel_position);
        this.icon.waiting = true;
        this.icon.animate_wait();

        try {
            app_info.launch(null, launch_context);
        } catch (GLib.Error e) {
            warning(e.message);
        }
    }

    private Wnck.Window get_next_window()
    {        
        if (class_group == null) {
            return this.window;
        }

        Wnck.Window target_window = class_group.get_windows().nth_data(0);

        bool found_active = false;
        foreach (Wnck.Window window in class_group.get_windows()) {
            if (found_active && !window.is_skip_tasklist()) {
                target_window = window;
                break;
            }

            if (window == this.desktop_helper.get_active_window()) {
                found_active = true;
            }
        }

        return target_window;
    }

    private Wnck.Window get_previous_window() {
        if (class_group == null) {
            return this.window;
        }

        GLib.List<unowned Wnck.Window> list = class_group.get_windows().copy();
        list.reverse();
        Wnck.Window target_window = list.first().data;

        bool found_active = false;
        foreach (Wnck.Window window in list) {
            if (found_active && !window.is_skip_tasklist()) {
                target_window = window;
                break;
            }

            if (window == this.desktop_helper.get_active_window()) {
                found_active = true;
            }
        }

        return target_window;
    }

    public bool is_empty() {
        return (this.window == null && class_group == null);
    }

    public bool is_pinned() {
        return pinned;
    }

    public void attention(bool needs_it = true)
    {
        this.needs_attention = needs_it;
        this.queue_draw();
        if (needs_it) {
            this.icon.animate_attention(this.desktop_helper.panel_position);
        }
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

    public void draw_inactive(Cairo.Context cr, Gdk.RGBA col)
    {
        int x = definite_allocation.x;
        int y = definite_allocation.y;
        int width = definite_allocation.width;
        int height = definite_allocation.height;
        GLib.List<unowned Wnck.Window> windows;

        if (class_group != null) {
            windows = class_group.get_windows().copy();
        } else {
            windows = new GLib.List<unowned Wnck.Window>();
            windows.insert(this.window, 0);
        }

        int count;
        if (!this.has_valid_windows(out count)) {
            return;
        }

        count = (count > 5) ? 5 : count;

        int counter = 0;
        foreach (Wnck.Window window in windows) {
            if (counter == count) {
                break;
            }

            if (!window.is_skip_tasklist()) {
                int indicator_x = 0;
                int indicator_y = 0;
                switch (this.desktop_helper.panel_position) {
                    case Budgie.PanelPosition.TOP:
                        indicator_x = x + (width / 2);
                        indicator_x -= ((count * (INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING)) / 2) - INACTIVE_INDICATOR_SPACING;
                        indicator_x += (((INDICATOR_SIZE) + INACTIVE_INDICATOR_SPACING) * counter);
                        indicator_y = y + (INDICATOR_SIZE / 2);
                        break;
                    case Budgie.PanelPosition.BOTTOM:
                        indicator_x = x + (width / 2);
                        indicator_x -= ((count * (INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING)) / 2) - INACTIVE_INDICATOR_SPACING;
                        indicator_x += (((INDICATOR_SIZE) + INACTIVE_INDICATOR_SPACING) * counter);
                        indicator_y = y + height - (INDICATOR_SIZE / 2);
                        break;
                    case Budgie.PanelPosition.LEFT:
                        indicator_y = x + (height / 2);
                        indicator_y -= ((count * (INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING)) / 2) - (INACTIVE_INDICATOR_SPACING * 2);
                        indicator_y += (((INDICATOR_SIZE) + INACTIVE_INDICATOR_SPACING) * counter);
                        indicator_x = y + (INDICATOR_SIZE / 2);
                        break;
                    case Budgie.PanelPosition.RIGHT:
                        indicator_y = x + (height / 2);
                        indicator_y -= ((count * (INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING)) / 2) - INACTIVE_INDICATOR_SPACING;
                        indicator_y += ((INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING) * counter);
                        indicator_x = y + width - (INDICATOR_SIZE / 2);
                        break;
                    default:
                        break;
                }

                cr.set_source_rgba(col.red, col.green, col.blue, 1);
                cr.arc(indicator_x, indicator_y, INDICATOR_SIZE, 0, Math.PI * 2);
                cr.fill();
                counter++;
            }
        }
    }

    public override bool draw(Cairo.Context cr)
    {
        int x = definite_allocation.x;
        int y = definite_allocation.y;
        int width = definite_allocation.width;
        int height = definite_allocation.height;
        GLib.List<unowned Wnck.Window> windows;

        if (class_group != null) {
            windows = class_group.get_windows().copy();
        } else {
            windows = new GLib.List<unowned Wnck.Window>();
            windows.insert(this.window, 0);
        }

        int count;
        if (!this.has_valid_windows(out count)) {
            return base.draw(cr);
        }

        count = (count > 5) ? 5 : count;

        Gtk.StyleContext context = this.get_style_context();

        Gdk.RGBA col;
        if (!context.lookup_color("budgie_tasklist_indicator_color", out col)) {
            col.parse("#3C6DA6");
        }

        if (this.get_active()) {
            if (!context.lookup_color("budgie_tasklist_indicator_color_active", out col)) {
                col.parse("#5294E2");
            }
        } else {
            if (this.needs_attention) {
                if (!context.lookup_color("budgie_tasklist_indicator_color_attention", out col)) {
                    col.parse("#D84E4E");
                }
            }
            draw_inactive(cr, col);
            return base.draw(cr);
        }

        int counter = 0;
        int previous_x = 0;
        int previous_y = 0;
        int spacing = width % count;
        spacing = (spacing == 0) ? 1 : spacing;
        foreach (Wnck.Window window in windows) {
            if (counter == count) {
                break;
            }

            if (!window.is_skip_tasklist()) {
                int indicator_x = 0;
                int indicator_y = 0;
                switch (this.desktop_helper.panel_position) {
                    case Budgie.PanelPosition.TOP:
                        if (counter == 0) {
                            indicator_x = x;
                        } else {
                            previous_x = indicator_x = previous_x + (width/count);
                            indicator_x += spacing;
                        }
                        indicator_y = y;
                        break;
                    case Budgie.PanelPosition.BOTTOM:
                        if (counter == 0) {
                            indicator_x = x;
                        } else {
                            previous_x = indicator_x = previous_x + (width/count);
                            indicator_x += spacing;
                        }
                        indicator_y = y + height;
                        break;
                    case Budgie.PanelPosition.LEFT:
                        if (counter == 0) {
                            indicator_y = y;
                        } else {
                            previous_y = indicator_y = previous_y + (height/count);
                            indicator_y += spacing;
                        }
                        indicator_x = x;
                        break;
                    case Budgie.PanelPosition.RIGHT:
                        if (counter == 0) {
                            indicator_y = y;
                        } else {
                            previous_y = indicator_y = previous_y + (height/count);
                            indicator_y += spacing;
                        }
                        indicator_x = x + width;
                        break;
                    default:
                        break;
                }

                cr.set_line_width(6);
                if (this.desktop_helper.get_active_window() == window && count > 1) {
                    Gdk.RGBA col2 = col;
                    if (!context.lookup_color("budgie_tasklist_indicator_color_active_window", out col2)) {
                        col2.parse("#6BBFFF");
                    }
                    cr.set_source_rgba(col2.red, col2.green, col2.blue, 1);
                } else {
                    cr.set_source_rgba(col.red, col.green, col.blue, 1);
                }
                cr.move_to(indicator_x, indicator_y);

                switch (this.desktop_helper.panel_position) {
                    case Budgie.PanelPosition.LEFT:
                    case Budgie.PanelPosition.RIGHT:
                        int to = 0;
                        if (counter == count-1) {
                            to = y + height; 
                        } else {
                            to = previous_y+(height/count);
                        }
                        cr.line_to(indicator_x, to);
                        break;
                    default:
                        int to = 0;
                        if (counter == count-1) {
                            to = x + width; 
                        } else {
                            to = previous_x+(width/count);
                        }
                        cr.line_to(to, indicator_y);
                        break;
                }

                cr.stroke();
                counter++;
            }
        }


        return base.draw(cr);
    }

    public override void size_allocate(Gtk.Allocation allocation) {
        definite_allocation.x = allocation.x;
        definite_allocation.y = allocation.y;

        base.size_allocate(definite_allocation);

        int x, y;
        var toplevel = get_toplevel();
        if (toplevel == null || toplevel.get_window() == null) {
            return;
        }
        translate_coordinates(toplevel, 0, 0, out x, out y);
        toplevel.get_window().get_root_coords(x, y, out x, out y);

        if (this.window != null) {
            this.window.set_icon_geometry(x, y, definite_allocation.width, definite_allocation.height);
        } else if (class_group != null) {
            foreach (Wnck.Window win in class_group.get_windows()) {
                win.set_icon_geometry(x, y, definite_allocation.width, definite_allocation.height);
            }
        }
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        /* Stop GTK from bitching */
        int m, n;
        base.get_preferred_width(out m, out n);

        int width = this.desktop_helper.panel_size;
        if (this.desktop_helper.orientation == Gtk.Orientation.HORIZONTAL) {
            width += 6;
        }
        min = nat = definite_allocation.width = width;
    }

    public override void get_preferred_height(out int min, out int nat)
    {
        /* Stop GTK from bitching */
        int m, n;
        base.get_preferred_height(out m, out n);

        min = nat = definite_allocation.height = this.desktop_helper.panel_size;
    }

    public override bool button_release_event(Gdk.EventButton event)
    {
        if (class_group != null && (last_active_window == null || class_group.get_windows().find(last_active_window) == null)) {
            last_active_window = class_group.get_windows().nth_data(0);
        }


        if (event.button == 2) {
            launch_app(event.time);
            return Gdk.EVENT_STOP;
        } else if (event.button == 1) {
            if (this.window != null) {
                if (this.window.is_active()) {
                    this.window.minimize();
                } else {
                    this.window.unminimize(event.time);
                    this.window.activate(event.time);
                }
                return Gdk.EVENT_STOP;
            } else if (class_group != null) {
                bool all_unminimized = true;
                bool one_active = false;
                int num = 0;

                GLib.List<unowned Wnck.Window> list = this.desktop_helper.get_stacked_for_classgroup(this.class_group);

                foreach (Wnck.Window win in list) {
                    if (win.is_minimized()) {
                        all_unminimized = false;
                    }
                    if (win.is_active()) {
                        one_active = true;
                    }
                    num++;
                }
                if (num > 0) { // we have windows on this workspace
                    /*
                     * Operations are restricted to the current workspace
                     * because that makes the most sense.
                     *   If there is one active window:
                     *     minimize all windows
                     *   else:  
                     *     activate previously active window
                     */

                    list.foreach((w) => {
                        if (one_active) {
                            w.minimize();
                        } else {
                            last_active_window.activate(event.time);
                        }
                    });
                } else {
                    last_active_window.activate(event.time);
                }
            } else {
                launch_app(event.time);
            }
        }

        return base.button_release_event(event);
    }

    public override bool scroll_event(Gdk.EventScroll event) {
        if (this.window != null) {
            this.window.unminimize(event.time);
            this.window.activate(event.time);
            return Gdk.EVENT_STOP;
        }

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

    public override bool button_press_event(Gdk.EventButton event) {
        if (event.button == 3 && context_menu_has_items) {
            this.menu.popup(null, null, null, event.button, event.time);
        }
        return base.button_press_event(event);
    }

    private void update_context_menu()
    {
        this.menu = new Gtk.Menu();

        this.context_menu_has_items = false;

        if (!this.desktop_helper.lock_icons && this.app_info != null) {
            if (!this.pinned || !this.is_from_window) {
                Gtk.CheckMenuItem pinned_item = new Gtk.CheckMenuItem.with_mnemonic("Pinned");
                menu.append(pinned_item);
                pinned_item.show();
                this.context_menu_has_items = true;
                pinned_item.set_active(pinned);

                pinned_item.toggled.connect(() => {
                    this.pinned = pinned_item.get_active();
                    this.is_from_window = !this.pinned;
                    this.desktop_helper.update_pinned();
                    if (!has_valid_windows(null) && !this.pinned) {
                        became_empty();
                        return;
                    }
                });
            }
        }

        int num_windows;

        if (has_valid_windows(out num_windows)) {
            Gtk.MenuItem close_item = new Gtk.MenuItem.with_label((num_windows > 1) ? "Close all" : "Close");
            menu.append(close_item);
            close_item.show();
            context_menu_has_items = true;

            close_item.activate.connect(() => {
                if (window != null) {
                    var timestamp = Gtk.get_current_event_time();
                    window.close(timestamp);
                    return;
                }

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
                window_item.set_sensitive(window != this.desktop_helper.get_active_window());
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

    public GLib.DesktopAppInfo? get_appinfo() {
        return this.app_info;
    }

    public unowned Wnck.ClassGroup? get_class_group() {
        return this.class_group;
    }
}

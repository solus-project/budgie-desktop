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

namespace Budgie
{

public const string RAVEN_DBUS_NAME        = "org.budgie_desktop.Raven";
public const string RAVEN_DBUS_OBJECT_PATH = "/org/budgie_desktop/Raven";

[DBus (name = "org.budgie_desktop.Raven")]
public class RavenIface
{

    private Raven? parent = null;
    [DBus (visible = false)]
    public uint notifications = 0;

    [DBus (visible = false)]
    public RavenIface(Raven? parent)
    {
        this.parent = parent;
    }

    public bool is_expanded {
        public set {
            parent.set_expanded(value);
        }
        public get {
            return parent.get_expanded();
        }
    }

    public signal void ExpansionChanged(bool expanded);

    public bool GetExpanded() {
        return this.is_expanded;
    }

    public void SetExpanded(bool b) {
        this.is_expanded = b;
    }

    public void Toggle() {
        this.is_expanded = !this.is_expanded;

        if (this.is_expanded) {
            if (this.notifications == 0){
                parent.expose_main_view();
            } else {
                parent.expose_notification();
                this.ReadNotifications();
            }
        }
    }

    /**
     * Toggle Raven, opening only the "main" applet view
     */
    public void ToggleAppletView() {
        if (this.is_expanded) {
            this.is_expanded = !this.is_expanded;
            return;
        }
        parent.expose_main_view();
        this.is_expanded = !this.is_expanded;
    }

    /**
     * Toggle Raven, opening only the "main" applet view
     */
    public void ToggleNotificationsView() {
        if (this.is_expanded) {
            this.is_expanded = !this.is_expanded;
            return;
        }
        parent.expose_notification();
        this.is_expanded = !this.is_expanded;
    }

    public void Dismiss() {
        if (this.is_expanded) {
            this.is_expanded = !this.is_expanded;
        }
    }

    public signal void NotificationsChanged();

    public uint GetNotificationCount() {
        return this.notifications;
    }

    public signal void UnreadNotifications();
    public signal void ReadNotifications();

    public string get_version()
    {
        return "1";
    }
}

public class Raven : Gtk.Window
{

    /* Use 15% of screen estate */
    private double intended_size = 0.15;
    private static Raven? _instance = null;

    int our_width = 0;
    int our_height = 0;
    int our_x = 0;
    int our_y = 0;

    private Budgie.ShadowBlock? shadow;
    private RavenIface? iface = null;
    bool expanded = false;
    bool outside_win = false;

    Gdk.Rectangle old_rect;

    private double scale = 0.0;

    public int required_size { public get ; protected set; }

    private PowerStrip? strip = null;

    unowned Budgie.Toplevel? toplevel_top = null;
    unowned Budgie.Toplevel? toplevel_bottom = null;

    private Budgie.MainView? main_view = null;
    private Budgie.SettingsView? settings_view = null;
    private Gtk.Stack? main_stack;

    private uint n_count = 0;

    public Budgie.DesktopManager? manager { public set; public get; }

    public double nscale {
        public set {
            scale = value;
            if (nscale > 0.0 && nscale < 1.0) {
                required_size = (int)(get_allocated_width() * nscale);
            } else {
                required_size = get_allocated_width();
            }
            queue_draw();
        }
        public get {
            return scale;
        }
    }

    public void ReadNotifications() {
        if (iface != null) {
            iface.ReadNotifications();
        }
    }

    public void UnreadNotifications() {
        if (iface != null) {
            iface.UnreadNotifications();
        }
    }

    private void on_bus_acquired(DBusConnection conn)
    {
        try {
            iface = new RavenIface(this);
            conn.register_object(Budgie.RAVEN_DBUS_OBJECT_PATH, iface);
        } catch (Error e) {
            stderr.printf("Error registering Raven: %s\n", e.message);
            Process.exit(1);
        }
    }

    public void expose_main_view()
    {
        main_stack.set_visible_child_name("main");
        main_view.set_clean();
        settings_view.set_clean();
    }

    public void expose_notification()
    {
        main_stack.set_visible_child_name("main");
        main_view.expose_notification();
    }

    public static unowned Raven? get_instance()
    {
        return Raven._instance;
    }

    public void set_notification_count(uint count)
    {
        if (this.n_count != count) {
            this.n_count = count;
            this.iface.notifications = count;
            this.iface.NotificationsChanged();
        }
    }

    bool on_enter_notify()
    {
        this.outside_win = false;
        return Gdk.EVENT_PROPAGATE;
    }

    bool on_focus_out()
    {
        if (this.outside_win && this.expanded) {
            this.set_expanded(false);
        }
        return Gdk.EVENT_PROPAGATE;
    }

    bool on_leave_notify(Gtk.Widget? widget, Gdk.EventCrossing? evt)
    {
        if (evt.x_root < this.our_x ||
            evt.x_root > (this.our_x+this.our_width) ||
            evt.y_root < this.our_y ||
            evt.y_root > (this.our_y+this.our_height))
        {
            this.outside_win = true;
        } else {
            this.outside_win = false;
        }
        return Gdk.EVENT_PROPAGATE;
    }

    private void steal_focus()
    {
        unowned Gdk.Window? window = get_window();
        if (window == null) {
            return;
        }
        if (!has_toplevel_focus) {
            /* X11 specific. */
            Gdk.Display? display = screen.get_display();
            if (display is Gdk.X11Display) {
                window.focus(Gdk.X11Display.get_user_time(display));
            } else {
                window.focus(Gtk.get_current_event_time());
            }
        }
    }

    public Raven(Budgie.DesktopManager? manager)
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK, manager: manager);
        get_style_context().add_class("budgie-container");

        Raven._instance = this;

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("No RGBA functionality");
        } else {
            set_visual(vis);
        }

        // Response to a scale factor change
        notify["scale-factor"].connect(()=> {
            this.update_geometry(this.old_rect, this.toplevel_top, this.toplevel_bottom);
            queue_resize();
        });

        leave_notify_event.connect(on_leave_notify);
        enter_notify_event.connect(on_enter_notify);
        focus_out_event.connect(on_focus_out);

        /* Set up our main layout */
        var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(layout);


        enter_notify_event.connect((e)=> {
            steal_focus();
            return Gdk.EVENT_PROPAGATE;
        });

        shadow = new Budgie.ShadowBlock(PanelPosition.RIGHT);
        layout.pack_start(shadow, false, false, 0);
        /* For now Raven is always on the right */
        this.get_style_context().add_class(Budgie.position_class_name(PanelPosition.RIGHT));

        var frame = new Gtk.Frame(null);
        frame.get_style_context().add_class("raven-frame");
        layout.pack_start(frame, true, true, 0);

        var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context().add_class("raven");
        frame.add(main_box);

        /* "Main" switcher */
        main_stack = new Gtk.Stack();
        main_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
        main_box.pack_start(main_stack, true, true, 0);

        /* Applets */
        main_view = new Budgie.MainView();
        main_view.view_switch.connect(on_view_switch);
        main_stack.add_named(main_view, "main");

        /* Settings */
        settings_view = new Budgie.SettingsView(manager);
        settings_view.view_switch.connect(on_view_switch);
        main_stack.add_named(settings_view, "settings");

        strip = new PowerStrip(this);
        main_box.pack_end(strip, false, false, 0);

        resizable = false;
        skip_taskbar_hint = true;
        skip_pager_hint = true;
        set_keep_above(true);
        set_decorated(false);

        set_size_request(-1, -1);
        if (!this.get_realized()) {
            this.realize();
        }

        notify["visible"].connect(()=> {
            if (!get_visible()) {
                if (this.toplevel_top != null) {
                    toplevel_top.reset_shadow();
                }
                if (this.toplevel_bottom != null) {
                    toplevel_bottom.reset_shadow();
                }
            }
        });

        this.get_child().show_all();
    }


    void on_view_switch(Gtk.Widget? widget)
    {
        string? name = "";

        if (widget == this.main_view) {
            name = "settings";
        } else {
            name = "main";
        }

        this.main_stack.set_visible_child_name(name);
    }

    public override void size_allocate(Gtk.Allocation rect)
    {
        int w = 0;

        base.size_allocate(rect);
        if ((w = get_allocated_width()) != this.required_size) {
            this.required_size = w;
            this.update_geometry(this.old_rect, this.toplevel_top, this.toplevel_bottom);
        }
    }

    public void setup_dbus()
    {
        Bus.own_name(BusType.SESSION, Budgie.RAVEN_DBUS_NAME, BusNameOwnerFlags.ALLOW_REPLACEMENT|BusNameOwnerFlags.REPLACE,
            on_bus_acquired, ()=> {}, ()=> { warning("Raven could not take dbus!"); });
    }

    void bind_panel_shadow(Budgie.Toplevel? toplevel)
    {
        weak Binding? b = bind_property("required-size", toplevel, "shadow-width", BindingFlags.DEFAULT, (b,v, ref v2)=> {
            var d = v.get_int()-5;
            v2 = Value(typeof(int));
            v2.set_int(d);
            return true;
        });
        toplevel.set_data("_binding_shadow", b);
    }

    void unbind_panel_shadow(Budgie.Toplevel? top)
    {
        if (top == null) {
            return;
        }
        weak Binding? b = top.get_data("_binding_shadow");
        if (b != null) {
            b.unbind();
        }
        if (this.toplevel_top == top) {
            this.toplevel_top = null;
        } else if (this.toplevel_bottom == top) {
            this.toplevel_bottom = null;
        }
    }

    /**
     * Update our geometry based on other panels in the neighbourhood, and the screen we
     * need to be on */
    public void update_geometry(Gdk.Rectangle rect, Budgie.Toplevel? top, Budgie.Toplevel? bottom)
    {
        int width = required_size;

        int x = (rect.x+rect.width)-width;
        int y = rect.y;
        int height = rect.height;

        this.old_rect = rect;

        if (top != this.toplevel_top) {
            unbind_panel_shadow(this.toplevel_top);
        }
        if (bottom != this.toplevel_bottom) {
            unbind_panel_shadow(this.toplevel_bottom);
        }

        if (top != null) {
            int size = top.intended_size - top.shadow_depth;
            height -= size;
            y += size;

            if (this.toplevel_top != top) {
                this.toplevel_top = top;
                this.bind_panel_shadow(top);
            }
        }

        if (bottom != null) {
            height -= bottom.intended_size;
            height += bottom.shadow_depth;

            if (this.toplevel_bottom != bottom) {
                this.toplevel_bottom = bottom;
                this.bind_panel_shadow(bottom);
            }
        }

        move(x,y);

        our_height = height;
        our_width = width;
        our_x = x;
        our_y = y;

        if (!get_visible()) {
            queue_resize();
        }
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = our_height;
        n = our_height;
    }

    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = our_height;
        n = our_height;
    }

    public override bool draw(Cairo.Context cr)
    {
        if (nscale == 0.0 || nscale == 1.0) {
            return base.draw(cr);
        }

        Gtk.Allocation alloc;
        get_allocation(out alloc);
        var buffer = new Cairo.ImageSurface(Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr2 = new Cairo.Context(buffer);

        propagate_draw(get_child(), cr2);
        var width = alloc.width * nscale;

        cr.set_source_surface(buffer, alloc.width-width, 0);
        cr.paint();

        return Gdk.EVENT_STOP;
    }

    /**
     * Slide Raven in or out of view
     */
    public void set_expanded(bool exp)
    {
        if (exp == this.expanded) {
            return;
        }
        double old_op, new_op;
        if (exp) {
            this.update_geometry(this.old_rect, this.toplevel_top, this.toplevel_bottom);
            old_op = 0.0;
            new_op = 1.0;
        } else {
            old_op = 1.0;
            new_op = 0.0;
        }
        nscale = old_op;

        if (exp) {
            /* Until we're told otherwise */
            outside_win = true;
            show_all();
        }

        this.expanded = exp;
        this.iface.ExpansionChanged(this.expanded);

        var anim = new Budgie.Animation();
        anim.widget = this;
        anim.length = 170 * Budgie.MSECOND;
        anim.tween = Budgie.sine_ease_in_out;
        anim.changes = new Budgie.PropChange[] {
            Budgie.PropChange() {
                property = "nscale",
                old = old_op,
                @new = new_op
            }
        };

        anim.start((a)=> {
            if ((a.widget as Budgie.Raven).nscale == 0.0) {
                a.widget.hide();
            } else {
                (a.widget as Gtk.Window).present();
                (a.widget as Gtk.Window).grab_focus();
                steal_focus();
            }
        });
    }

    public bool get_expanded() {
        return this.expanded;
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

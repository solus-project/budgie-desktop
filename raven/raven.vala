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

public static const string RAVEN_DBUS_NAME        = "com.solus_project.arc.Raven";
public static const string RAVEN_DBUS_OBJECT_PATH = "/com/solus_project/arc/Raven";

[DBus (name = "com.solus_project.arc.Raven")]
public class RavenIface
{

    private Raven? parent = null;

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

    public void SetExpanded(bool b) {
        this.is_expanded = b;
    }

    public string get_version()
    {
        return "1";
    }
}

public class Raven : Gtk.Window
{

    /* Use 15% of screen estate */
    private double intended_size = 0.15;

    int our_width = 0;
    int our_height = 0;

    private Arc.ShadowBlock? shadow;
    private RavenIface? iface = null;
    bool expanded = false;

    private double scale = 0.0;

    public int required_size { public get ; protected set; }

    private PowerStrip? strip = null;

    unowned Arc.Toplevel? toplevel_top = null;
    unowned Arc.Toplevel? toplevel_bottom = null;

    private Arc.MainView? main_view = null;
    private Gtk.Stack? main_stack;

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

    private void on_bus_acquired(DBusConnection conn)
    {
        try {
            iface = new RavenIface(this);
            conn.register_object(Arc.RAVEN_DBUS_OBJECT_PATH, iface);
        } catch (Error e) {
            stderr.printf("Error registering Raven: %s\n", e.message);
            Process.exit(1);
        }
    }

    public Raven()
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK, gravity : Gdk.Gravity.EAST);
        get_style_context().add_class("arc-container");

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("No RGBA functionality");
        } else {
            set_visual(vis);
        }

        /* Set up our main layout */
        var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(layout);

        shadow = new Arc.ShadowBlock(PanelPosition.RIGHT);
        layout.pack_start(shadow, false, false, 0);
        /* For now Raven is always on the right */
        this.get_style_context().add_class(Arc.position_class_name(PanelPosition.RIGHT));

        var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context().add_class("raven");
        layout.pack_start(main_box, true, true, 0);

        /* "Main" switcher */
        main_stack = new Gtk.Stack();
        main_box.pack_start(main_stack, true, true, 0);

        /* Applets */
        main_view = new Arc.MainView();
        main_stack.add_named(main_view, "applets");

        strip = new PowerStrip(this);
        main_box.pack_end(strip, false, false, 0);

        resizable = true;
        skip_taskbar_hint = true;
        skip_pager_hint = true;
        set_keep_above(true);
        set_decorated(false);

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
    }

    public override void size_allocate(Gtk.Allocation rect)
    {
        int w = 0;

        base.size_allocate(rect);
        if ((w = get_allocated_width()) != this.required_size) {
            this.required_size = w;
        }
    }

    public void setup_dbus()
    {
        Bus.own_name(BusType.SESSION, Arc.RAVEN_DBUS_NAME, BusNameOwnerFlags.ALLOW_REPLACEMENT|BusNameOwnerFlags.REPLACE,
            on_bus_acquired, ()=> {}, ()=> { warning("Raven could not take dbus!"); });
    }

    void bind_panel_shadow(Arc.Toplevel? toplevel)
    {
        weak Binding? b = bind_property("required-size", toplevel, "shadow-width", BindingFlags.DEFAULT, (b,v, ref v2)=> {
            var d = v.get_int()-5;
            v2 = Value(typeof(int));
            v2.set_int(d);
            return true;
        });
        toplevel.set_data("_binding_shadow", b);
        toplevel.destroy.connect(()=> {
            this.unbind_panel_shadow(toplevel);
        });
    }

    void unbind_panel_shadow(Arc.Toplevel? top)
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
    public void update_geometry(Gdk.Rectangle rect, Arc.Toplevel? top, Arc.Toplevel? bottom)
    {
        int n, m;
        /* In future we'll actually probe all applets */
        main_view.get_preferred_width(out m, out n);
        int width = n;

        int x = (rect.x+rect.width)-width;
        int y = rect.y;
        int height = rect.height;


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

            this.toplevel_top = top;
            this.bind_panel_shadow(top);
        }

        if (bottom != null) {
            height -= bottom.intended_size;
            height += bottom.shadow_depth;

            this.toplevel_bottom = bottom;
            this.bind_panel_shadow(bottom);
        }

        our_height = height;
        our_width = width;
        move(x, y);
        queue_resize();
    }

    public override void get_preferred_width(out int m, out int n)
    {
        m = our_width;
        n = our_width;
    }

    public override void get_preferred_width_for_height(int h, out int m, out int n)
    {
        m = our_width;
        n = our_width;
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
            old_op = 0.0;
            new_op = 1.0;
        } else {
            old_op = 1.0;
            new_op = 0.0;
        }
        nscale = old_op;

        if (exp) {
            show_all();
        }

        this.expanded = exp;

        var anim = new Arc.Animation();
        anim.widget = this;
        anim.length = 270 * Arc.MSECOND;
        anim.tween = Arc.sine_ease_in;
        anim.changes = new Arc.PropChange[] {
            Arc.PropChange() {
                property = "nscale",
                old = old_op,
                @new = new_op
            },
            Arc.PropChange() {
                property = "opacity",
                old = old_op,
                @new = new_op
            }
        };

        anim.start((a)=> {
            if ((a.widget as Arc.Raven).nscale == 0.0) {
                a.widget.hide();
            } else {
                (a.widget as Gtk.Window).present();
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

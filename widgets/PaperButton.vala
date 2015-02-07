/*
 * PaperButton.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
static double deg_to_rad(double deg)
{
    return (deg * Math.PI / 180.0);
}

/**
 * Need to use Object not struct because:
 *
 * 1) Vala loves to alloc structs. We need unique references.
 * 2) We then opted for GObject property usage for the animations
 */
public class Ripple : GLib.Object {
    public double x { public set; public get; }
    public double y { public set; public get; }
    public double radius { public set; public get; }
    public double opacity { public set; public get; }
    public Budgie.Animation anim { public set; public get; }

    public Ripple(double x, double y, double radius, double opacity)
    {
        this.x = x;
        this.y = y;
        this.radius = radius;
        this.opacity = opacity;
    }
}

public class PaperButton : Gtk.ToggleButton
{
    List<Ripple?> ripples;

    Ripple? last = null;

    public bool anim_above_content { public set; public get; }

    /**
     * If we're usable, left mouse click, send off a ripple
     */
    public override bool button_press_event(Gdk.EventButton btn)
    {
        if (btn.button != 1) {
            return base.button_press_event(btn);
        }
        if (btn.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
            return base.button_press_event(btn);
        }
        if (btn.type == Gdk.EventType.TRIPLE_BUTTON_PRESS) {
            return base.button_press_event(btn);
        }

        var radius =(double) get_allocated_width();
        radius += (radius-btn.x);

        /* Simple ripple, or more to the point a circle, going outwards
         * from x,y increasing its radius and opacity. Upon mouse release
         * the opacity then begins an inversion to fade it out again, giving
         * the effect of ripples
         */
        var ripple = new Ripple(btn.x, btn.y, 10, 0.4);
        ripple.anim = new Budgie.Animation();
        ripple.anim.tween = null;
        ripple.anim.length = 1200 * Budgie.MSECOND;
        ripple.anim.widget = this;
        ripple.anim.object = ripple;
        ripple.anim.changes = new Budgie.PropChange[] {
            Budgie.PropChange() {
                property = "radius",
                old = ripple.radius,
                @new = (double)radius
            },
            Budgie.PropChange() {
                property = "opacity",
                old = ripple.opacity,
                @new = 0.8
            }
        };
        ripple.anim.start(null);
        queue_draw();
        ripples.append(ripple);
        last = ripple;
        return base.button_press_event(btn);
    }

    /**
     * Again, if usable, but this time begin ripple-decay
     */
    public override bool button_release_event(Gdk.EventButton btn)
    {
        if (last != null) {
            last.anim.stop();
            /* Convert animation to fading opacity */
            last.anim.changes[0].old = last.radius;
            last.anim.changes[1].@new = 0.0;
            last.anim.changes[1].old = last.opacity;
            last.anim.start((a)=> {
                ripples.remove(a.object as Ripple);
                queue_draw();
            });
            this.last = null;

        }
        queue_draw();
        return base.button_release_event(btn);
    }

    /**
     * We put ripples in between the background and the content
     */
    public override bool draw(Cairo.Context cr)
    {
        Gtk.Allocation alloc;
        get_allocation(out alloc);
        var st = get_style_context();

        alloc.x = 0;
        alloc.y = 0;
        alloc.width = get_allocated_width();
        alloc.height = get_allocated_height();

        st.render_frame(cr, alloc.x, alloc.y, alloc.width, alloc.height);
        st.render_background(cr, alloc.x, alloc.y, alloc.width, alloc.height);

        if (anim_above_content) {
            if (get_child() != null) {
                propagate_draw(get_child(), cr);
            }
        }

        cr.save();
        cr.rectangle(alloc.x, alloc.y, alloc.width, alloc.height);
        cr.clip();
        var sa = deg_to_rad(0.0);
        var ea = deg_to_rad(360.0);

        Gdk.RGBA r = {};
        /* Make configurable. :P */
        r.parse("white");

        foreach (var ripple in ripples) {
            cr.set_source_rgba(r.red, r.green, r.blue, ripple.opacity);
            cr.arc(ripple.x, ripple.y, ripple.radius, sa, ea);
            cr.fill();
        }

        cr.restore();
        if (!anim_above_content) {
            if (get_child() != null) {
                propagate_draw(get_child(), cr);
            }
        }
        return Gdk.EVENT_STOP;
    }

    public PaperButton()
    {
        this.with_label(null);
    }

    public PaperButton.with_label(string? lab)
    {
        Object(label: lab);
        anim_above_content = false;
        get_style_context().remove_class("button");
        get_style_context().add_class("budgie-button");
        if (lab != null) {
            (get_child() as Gtk.Label).use_markup = true;
        }
        ripples = new List<Ripple?>();
    }
}

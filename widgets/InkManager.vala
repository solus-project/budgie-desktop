/*
 * InkManager.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */


/**
 * Need to use Object not struct because:
 *
 * 1) Vala loves to alloc structs. We need unique references.
 * 2) We then opted for GObject property usage for the animations
 */
class Ripple : GLib.Object {
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

public class InkManager : GLib.Object
{
    List<Ripple?> ripples;

    Ripple? last = null;
    unowned Gtk.Widget? widget;

    static const double DEFAULT_RADIUS = 10.0;

    public InkManager(Gtk.Widget? widget)
    {
        this.widget = widget;
    }

    double deg_to_rad(double deg)
    {
        return (deg * Math.PI / 180.0);
    }

    public void add_ripple(double x, double y)
    {
        var radius =(double) widget.get_allocated_width();
        radius += (radius-x);

        var ripple = new Ripple(x, y, DEFAULT_RADIUS, 0.4);
        ripple.anim = new Budgie.Animation();
        ripple.anim.tween = null;
        ripple.anim.length = 1200 * Budgie.MSECOND;
        ripple.anim.widget = this.widget;
        ripple.anim.object = ripple;
        ripple.anim.changes = new Budgie.PropChange[] {
            Budgie.PropChange() {
                property = "radius",
                old = ripple.radius,
                @new = radius
            },
            Budgie.PropChange() {
                property = "opacity",
                old = ripple.opacity,
                @new = 0.8
            }
        };
        ripple.anim.start(null);
        widget.queue_draw();
        ripples.append(ripple);
        last = ripple;
    }

    /**
     * Decay the last ripple
     */
    public void remove_ripple()
    {
        if (last != null) {
            last.anim.stop();
            /* Convert animation to fading opacity */
            last.anim.changes[0].old = last.radius;
            last.anim.changes[1].@new = 0.0;
            last.anim.changes[1].old = last.opacity;
            last.anim.start((a)=> {
                ripples.remove(a.object as Ripple);
                widget.queue_draw();
            });
            this.last = null;
        }
    }

    /**
     * Remove all of the ripples
     */
    public void clear_ripples()
    {
        ripples = new List<Ripple?>();
        widget.queue_draw();
    }


    /**
     * Render the ripples clipped to the rectangle bounds specified
     *
     * @param x start x
     * @param y start y
     * @param width total width
     * @param height total height
     */
    public void render(Cairo.Context cr, double x, double y, double width, double height)
    {
        cr.save();
        cr.rectangle(x, y, width, height);
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
    }
}

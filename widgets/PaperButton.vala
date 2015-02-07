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

public class PaperButton : Gtk.ToggleButton
{
    public bool anim_above_content { public set; public get; }

    InkManager? ink;

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
        ink.add_ripple(btn.x, btn.y);
        return base.button_press_event(btn);
    }

    /**
     * Again, if usable, but this time begin ripple-decay
     */
    public override bool button_release_event(Gdk.EventButton btn)
    {
        ink.remove_ripple();
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

        ink.render(cr, alloc.x, alloc.y, alloc.width, alloc.height);

        if (!anim_above_content) {
            if (get_child() != null) {
                propagate_draw(get_child(), cr);
            }
        }
        return Gdk.EVENT_STOP;
    }

    construct {
        anim_above_content = false;
        get_style_context().remove_class("button");
        get_style_context().add_class("budgie-button");
        ink = new InkManager(this);
    }
}

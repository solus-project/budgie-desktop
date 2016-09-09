/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2016 Fernando Mussel <fernandomussel91@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

/**
 * Maximum number of full flash cycles for urgency before giving up. Note
 * that the background colour will remain fully opaque until the calling
 * application then resets whatever caused the urgency/attention demand
 */
const int MAX_CYCLE = 12;

/**
 * Default opacity when beginning urgency cycles in the launcher
 */
const double DEFAULT_OPACITY = 0.1;
const double INCREMENT = 0.01;

class UrgencyAnimation
{

    public static const int INFINITE_CYCLE_NUM = -1;
    private bool should_fade_in = true;

    private double opacity = 0.0;
    private int current_cycle = 0;
    private int max_cycle_num = MAX_CYCLE;

    private weak Gtk.Widget owner;
    private uint source_id = 0;
    private ulong owner_draw_cb = 0;

    public UrgencyAnimation(Gtk.Widget owner, int max_cycle_num = MAX_CYCLE)
    {
        this.owner = owner;
        this.max_cycle_num = max_cycle_num;
        reset();
    }

    public void begin_animation()
    {
        if (!is_animation_in_progress()) {
            // intercept the draw signal of the owner widget
            owner_draw_cb = this.owner.draw.connect(draw);
        }

        if (source_id == 0) {
            // no tick callback registered. Register new one.
            source_id = owner.add_tick_callback(update);
        }
        reset();
    }

    public void end_animation()
    {
        if (is_animation_in_progress()) {
            this.owner.disconnect(owner_draw_cb);
            owner_draw_cb = 0;
        }

        stop_animation_update();
        owner.queue_draw();
    }

    public bool is_animation_in_progress()
    {
        return owner_draw_cb > 0;
    }

    public double get_opacity()
    {
        return opacity;
    }

    private void stop_animation_update()
    {
        if (source_id > 0) {
            owner.remove_tick_callback(source_id);
        }
        source_id = 0;
    }

    private bool update(Gtk.Widget widget, Gdk.FrameClock clock)
    {

        if (should_fade_in) {
            opacity += INCREMENT;
        } else {
            opacity -= INCREMENT;
        }

        if (opacity >= 1.0) {
            should_fade_in = false;
            opacity = 1.0;
            current_cycle += 1;
        } else if (opacity <= 0.0) {
            should_fade_in = true;
            opacity = 0.0;
        }

        // prompt widget draw
        owner.queue_draw();

        if (max_cycle_num != INFINITE_CYCLE_NUM && current_cycle >= max_cycle_num
            && opacity >= 1.0) {

            stop_animation_update();
            return false;
        }

        return true;
    }

    private bool draw(Cairo.Context cr)
    {
        if (!is_animation_in_progress()) {
            message ("Intercepting draw signal but animation is not in progress");
            return false;
        }

        Gtk.Allocation alloc;
        owner.get_allocation(out alloc);

        Gdk.RGBA col = {};
        /* FIXME: I'M ON DRUGS */
        col.parse("#36689E");
        cr.set_source_rgba(col.red, col.green, col.blue, get_opacity());
        cr.rectangle(alloc.x, alloc.y, alloc.width, alloc.height);
        cr.paint();
        return false;
    }

    private void reset()
    {
        should_fade_in = true;
        current_cycle = 0;
        opacity = DEFAULT_OPACITY;
    }


}

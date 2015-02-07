/*
 * Animation.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

/** Apply tween to animation completion factor (0.0-1.0) */
public delegate double TweenFunc(double factor);

/** Callback for animation completion */
public delegate void AnimCompletionFunc();

/** Animate a GObject property */
public struct PropChange {
    string property; /**<GObject property name */
    Value old;       /**<Value pre-animation */
    Value @new;      /**<Target value for end of animation */
}

/**
 * Utility to struct to enable easier animations
 * Inspired by Clutter. Not using Clutter as we use a Gtk desktop :p
 */
public struct Animation {
    int64 start_time;           /**<Start time (microseconds) of animation */
    int64 length;               /**<Length of animation in microseconds */
    unowned TweenFunc tween;    /**<Tween function to use for property changes */
    PropChange[] changes;      /**<Group of properties to change in this animation */
    unowned Gtk.Widget widget;/**<Rendering widget that owns the Gdk.FrameClock */
    uint id;                    /**<Idle source ID */

    /**
     * Syntatical abuse of Vala. Calls start_anim
     */
    public void start(AnimCompletionFunc compl) {
        start_anim(this, compl);
    }

    /**
     * Further syntatical abuse of Vala. Calls stop anim
     */
    public void stop() {
        stop_anim(this);
    }
}

/**
 * Start the given animation. Note that currently all animatable properties
 * must be of type gdouble, otherwise things will explode rather rapidly.
 *
 * @param anim Animation information
 * @param compl A callback to execute when the animation is complete
 */
public static void start_anim(Animation anim, AnimCompletionFunc compl)
{
        anim.start_time = get_monotonic_time();
        anim.id = anim.widget.add_tick_callback((widget, frame)=> {
            int64 time = frame.get_frame_time();
            float factor = 0.0f;
            var elapsed = time - anim.start_time;

            /* Bail out of the animation, set it to its maximum */
            if (elapsed >= anim.length || anim.id == 0) {
                foreach (var p in anim.changes) {
                    widget.set_property(p.property, p.@new);
                }
                anim.id = 0;
                compl();
                widget.queue_draw();
                return false;
            }

            factor = ((float)elapsed / anim.length).clamp(0, 1.0f);
            foreach (var c in anim.changes) {
                var old = c.old.get_double();
                var @new = c.@new.get_double();

                if (anim.tween != null) {
                    /* Drop precision here, start with double we loose it exponentially. */
                    factor = (float)anim.tween((double)factor);
                }

                var delta = (@new-old) * factor;
                var nprop = (double)(old + delta);
                widget.set_property(c.property, nprop);
            }

            widget.queue_draw();
            return true;
        });
}

/**
 * Stop a running animation
 *
 * @param anim A running animation
 */
public static void stop_anim(Animation anim)
{
    if (anim.id == 0) {
        return;
    }
    anim.widget.remove_tick_callback(anim.id);
    anim.id = 0;
}

/* These easing functions originally came from
 * https://github.com/warrenm/AHEasing/blob/master/AHEasing/easing.c
 * and are available under the terms of the WTFPL
 */

public static double sine_ease_in_out(double p)
{
    return 0.5 * (1 - Math.cos(p * Math.PI));
}

public static double sine_ease_in(double p)
{
    return Math.sin((p - 1) * Math.PI_2) + 1;
}

public static double sine_ease_out(double p)
{
    return Math.sin(p * Math.PI_2);
}

public static double elastic_ease_in(double p)
{
    return Math.sin(13 * Math.PI_2 * p) * Math.pow(2, 10 * (p - 1));
}

public static double elastic_ease_out(double p)
{
    return Math.sin(-13 * Math.PI_2 * (p + 1)) * Math.pow(2, -10 * p) + 1;
}

public static double back_ease_in(double p)
{
    return p * p * p - p * Math.sin(p * Math.PI);
}

public static double expo_ease_in(double p)
{
    return (p == 0.0) ? p : Math.pow(2, 10 * (p - 1));
}

public static double expo_ease_out(double p)
{
    return (p == 1.0) ? p : 1 - Math.pow(2, -10 * p);
}

public static double quad_ease_in(double p)
{
    return p * p;
}

public static double quad_ease_out(double p)
{
    return -(p * (p - 2));
}

public static double quad_ease_in_out(double p)
{
    return p < 0.5 ? (2 * p * p) : (-2 * p * p) + (4 * p) - 1;
}

public static const int64 MSECOND = 1000;

} /* End namespace */

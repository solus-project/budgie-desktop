/*
 * PanelMover.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public struct AnimationInfo {
    int orig_x;
    int orig_y;
    int target_x;
    int target_y;
    int height;
    int width;
    int64 start_time;
}

/**
 * This class handles automatic hiding/showing of the panel dependant
 * on the settings, and will hide when not being used.
 *
 * In future we will also have intellihide.
 */
public class PanelMover : Object
{

    /* Readability purposes, half second animation */
    public static const int ANIMATION_TIME = 1000000 / 2;

    AnimationInfo cur_info;

    protected unowned Budgie.Panel? panel;

    /* Stock signals */
    public signal void animation_begin();
    public signal void animation_end();
    public signal void visibility_changed(bool visible);

    protected bool animating = false;
    protected bool hiding;
    protected bool shown;
    protected bool horizontal = false;

    protected bool auto_hide = false;

    protected Settings settings;
    private Gdk.Rectangle primary_monitor_rect;

    public bool bounce { public set; public get; }

    // Track open windows, overlaps, etc.
    Wnck.Screen wnck_screen;

    public PanelMover(Budgie.Panel? panel) {
        this.panel = panel;

        var primary_monitor = panel.screen.get_primary_monitor();
        panel.screen.get_monitor_geometry(primary_monitor, out primary_monitor_rect);

        // set up wnck
        Wnck.set_client_type(Wnck.ClientType.PAGER);
        wnck_screen = Wnck.Screen.get_default();
        wnck_screen.window_opened.connect(on_window_opened);
        wnck_screen.window_closed.connect(on_window_closed);
        wnck_screen.active_window_changed.connect(on_active_window_changed);

        panel.enter_notify_event.connect(on_panel_enter);
        panel.leave_notify_event.connect(on_panel_leave);

        settings = new Settings("com.evolve-os.budgie.panel");
        settings.bind("bounce-animation", this, "bounce", SettingsBindFlags.DEFAULT);
        settings.changed.connect(on_settings_change);

        if (settings.get_string("hide-policy") == "automatic") {
            auto_hide = true;
        }
    }

    protected void on_settings_change(string key)
    {
        if (key != "hide-policy") {
            return;
        }
        /* We don't *yet* do intellihide */
        if (settings.get_string(key) == "automatic") {
            auto_hide = true;
            hide();
        } else {
            auto_hide = false;
            show();
        }
    }

    protected bool on_panel_enter(Gdk.EventCrossing event)
    {
        if (!auto_hide) {
            return false;
        }
        if (!animating && !shown) {
            show();
        }
        return false;
    }

    protected bool inside_panel(Gdk.EventCrossing event)
    {
        Gtk.Allocation alloc;
        panel.get_allocation(out alloc);

        if (event.x >= alloc.x && event.x <= alloc.width &&
            event.y >= alloc.y && event.y <= alloc.y+alloc.height) {
                return true;
        }
        return false;
    }

    protected bool on_panel_leave(Gdk.EventCrossing event)
    {
        if (!auto_hide) {
            return false;
        }
        if (!animating && shown) {
            /* Bounds check.. */
            if (!inside_panel(event)) {
                hide();
            }
        }
        return false;
    }

    protected void init_info(ref AnimationInfo ainfo)
    {
        Gtk.Allocation alloc;
        panel.get_allocation(out alloc);

        ainfo.orig_x = alloc.x;
        ainfo.orig_y = primary_monitor_rect.height-alloc.height;
        ainfo.height = alloc.height;
        ainfo.width = alloc.width;
        ainfo.start_time = get_monotonic_time();
    }

    protected bool on_tick(Gtk.Widget widget, Gdk.FrameClock frame)
    {
        int64 time = frame.get_frame_time();
        float factor = 0.0f;
        var elapsed = time - cur_info.start_time;

        if (elapsed >= ANIMATION_TIME) {
            /* Bail */
            widget.get_window().move(cur_info.target_x, cur_info.target_y);
            animation_end();
            visibility_changed(!hiding);
            if (hiding) {
                shown = false;
            } else {
                shown = true;
            }
            animating = false;
            return false;
        }
    
        factor = ((float)elapsed / ANIMATION_TIME).clamp(0, 1.0f);

        /* Moving **down** */
        double trouble;
        if (hiding) {
            if (bounce) {
                trouble = back_ease_in(factor);
            } else {
                trouble = expo_ease_in(factor);
            }
        } else {
            if (bounce) {
                trouble = elastic_ease_out(factor);
            } else {
                trouble = expo_ease_out(factor);
            }
        }
        double delta;
        int x, y;

        if (horizontal) {
            delta = (cur_info.target_x - cur_info.orig_x) * trouble;
            x = (int) (cur_info.orig_x + delta);
            y = cur_info.orig_y;
        } else {
            delta = (cur_info.target_y - cur_info.orig_y) * trouble;
            y = (int) (cur_info.orig_y + delta);
            x = cur_info.orig_x;
        }

        widget.get_window().move(x, y);

        return true;
    }

    public void hide()
    {
        init_info(ref cur_info);

        horizontal = false;

        // Leave a peeker
        switch (panel.position) {
            case PanelPosition.BOTTOM:
                cur_info.target_x = cur_info.orig_x;
                cur_info.target_y = (cur_info.orig_y + cur_info.height)-1;
                break;
            case PanelPosition.TOP:
                cur_info.orig_x = primary_monitor_rect.x;
                cur_info.orig_y = primary_monitor_rect.y;
                cur_info.target_y = (cur_info.orig_y-cur_info.height)+1;
                cur_info.target_x = cur_info.orig_x;
                break;
            case PanelPosition.LEFT:
                cur_info.orig_x = primary_monitor_rect.x;
                cur_info.orig_y = primary_monitor_rect.y;
                cur_info.target_x = (cur_info.orig_x-cur_info.width)+1;
                cur_info.target_y = cur_info.orig_y;
                horizontal = true;
                break;
            case PanelPosition.RIGHT:
                cur_info.orig_x = primary_monitor_rect.width-cur_info.width;
                cur_info.orig_y = primary_monitor_rect.y;
                cur_info.target_x = (cur_info.orig_x+cur_info.width)-1;
                cur_info.target_y = cur_info.orig_y;
                horizontal = true;
                break;
            default:
                return;
        }

        animation_begin();
        hiding = true;
        if (panel.get_visible()) {
            shown = true;
        }
        animating = true;
        panel.add_tick_callback(on_tick);
    }

    public void show()
    {
        init_info(ref cur_info);
        horizontal = false;
        // Leave a peeker
        switch (panel.position) {
            case PanelPosition.BOTTOM:
                cur_info.target_x = cur_info.orig_x;
                cur_info.target_y = primary_monitor_rect.height-cur_info.height;
                cur_info.orig_y = (primary_monitor_rect.height)-1;
                break;
            case PanelPosition.TOP:
                cur_info.orig_y = (primary_monitor_rect.y-cur_info.height)+1;
                cur_info.orig_x = primary_monitor_rect.x;
                cur_info.target_x = cur_info.orig_x;
                cur_info.target_y = primary_monitor_rect.y;
                break;
            case PanelPosition.LEFT:
                cur_info.orig_y = primary_monitor_rect.y;
                cur_info.target_y = cur_info.orig_y;
                cur_info.orig_x = (primary_monitor_rect.x-cur_info.width)+1;
                cur_info.target_x = primary_monitor_rect.x;
                horizontal = true;
                break;
            case PanelPosition.RIGHT:
                cur_info.orig_y = primary_monitor_rect.y;
                cur_info.target_y = cur_info.orig_y;
                cur_info.orig_x = (primary_monitor_rect.width+cur_info.width)-1;
                cur_info.target_x = primary_monitor_rect.width-cur_info.width;
                horizontal = true;
                break;
            default:
                return;
        }


        animation_begin();
        animating = true;
        if (!panel.get_visible()) {
            shown = false;
        }
        hiding = false;
        panel.add_tick_callback(on_tick);
    }

    /* These easing functions originally came from
     * https://github.com/warrenm/AHEasing/blob/master/AHEasing/easing.c
     * and are available under the terms of the WTFPL
     */
    protected double elastic_ease_out(double p)
    {
        return Math.sin(-13 * Math.PI_2 * (p + 1)) * Math.pow(2, -10 * p) + 1;
    }

    protected double back_ease_in(double p)
    {
        return p * p * p - p * Math.sin(p * Math.PI);
    }

    protected double expo_ease_in(double p)
    {
        return (p == 0.0) ? p : Math.pow(2, 10 * (p - 1));
    }

    protected double expo_ease_out(double p)
    {
        return (p == 1.0) ? p : 1 - Math.pow(2, -10 * p);
    }

    /*
     * WNCK stuff follows, simply to update the panel background
     */
    protected void on_window_opened(Wnck.Window window)
    {
        ulong id = window.state_changed.connect(on_window_state_changed);
        window.set_data("__bid", id);
        update_panel_state();
    }

    protected void on_window_closed(Wnck.Window window)
    {
        // quicker than waiting on GC.
        ulong id = window.get_data("__bid");
        window.disconnect(id);
        update_panel_state();
    }

    protected void on_active_window_changed(Wnck.Window? prev_window)
    {
        update_panel_state();
    }

    protected void on_window_state_changed(Wnck.WindowState mask, Wnck.WindowState new_state)
    {
        update_panel_state();
    }

    protected void update_panel_state()
    {
        int wx, wy, ww, wh; // wnck out vars

        bool havemax = false;
        // Might not have a workspace. Shrug. Revisit if/when it becomes a problem
        Wnck.Workspace? workspace = wnck_screen.get_active_workspace();
        foreach (var window in wnck_screen.get_windows()) {
            bool subvis = false;

            window.get_client_window_geometry(out wx, out wy, out ww, out wh);

            if (workspace != null) {
                subvis = window.is_visible_on_workspace(workspace);
            } else {
                if (!window.is_minimized() && !window.is_shaded()) {
                    subvis = true;
                }
            }
            if (window.is_maximized_vertically() && subvis &&
                // ensure that the window is fully contained within the
                // primary monitor as maximizing a window on other
                // monitors should not affect the shading of the bar
                wx >= primary_monitor_rect.x &&
                wx <= primary_monitor_rect.x + primary_monitor_rect.width &&
                wy >= primary_monitor_rect.y &&
                wy <= primary_monitor_rect.y + primary_monitor_rect.height
            ) {
                havemax = true;
                break;
            }
        }
        // Set the max-budgie-panel style, i.e. a darker panel :)
        if (havemax) {
            panel.get_style_context().add_class("max-budgie-panel");
        } else {
            panel.get_style_context().remove_class("max-budgie-panel");
        }
    }

} // End PanelMover

} // End Budgie namespace

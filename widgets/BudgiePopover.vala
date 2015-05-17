/*
 * BudgiePopover.vala
 *
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public class Popover : Gtk.Window
{

    protected bool bottom_tail { protected set;  protected get; }

    private static int tail_height = 12;
    private static int tail_width = 24;

    private int our_width;
    private int our_height;
    private int our_x;
    private int our_y;
    private int widg_x;
    private int their_width;
    private bool should_regrab = false;
    public bool passive = false;

    private int w_x;
    private int w_y;
    private int w_width;
    private int w_height;

    /* Simply ensures we retain some gap from the screen edge */
    private int screen_gap = 5;

    /* We simply steal the popovers stylecontext to trick css theming */
    private Gtk.Widget render_st;

    public Gtk.Widget? relative_to { construct set; public get; }

    construct {

        set_visual(get_screen().get_rgba_visual());

        /* For CSS */
        render_st = new Gtk.Popover(this);
        set_border_width(2);
        resizable = false;
        decorated = false;
        notify.connect((s,p) => {
            if (p.name != "bottom-tail") {
                return;
            }

            if (get_child() == null) {
                return;
            }
            if (bottom_tail) {
                get_child().set_property("margin-top", 1);
                get_child().set_property("margin-bottom", tail_height);
            } else {
                get_child().set_property("margin-top", tail_height);
                get_child().set_property("margin-bottom", 1);
            }
        });


        // Must die on Escape
        key_press_event.connect((k) => {
            if (k.keyval == Gdk.Key.Escape || k.keyval == Gdk.Key.Super_L) {
                hide();
                return true;
            }
            return false;
        });

        bottom_tail = true;

        // we dont want to appear in menus
        skip_taskbar_hint = true;
        skip_pager_hint = true;
        app_paintable = true;
        set_keep_above(true);

        our_width = -1;
        our_height = -1;

        size_allocate.connect((r)=> {
            bool place = false;
            if (our_width != r.width || our_height != r.height) {
                place = true;
            }
            our_width = r.width;
            our_height = r.height;
            if (place && get_realized()) {
                do_placement();
            }
        });

        relative_to.size_allocate.connect((r)=> {
            bool place = false;
            if (w_width != r.width || w_height != r.height || w_x != r.x || w_y != r.y) {
                place = true;
            }
            w_width = r.width;
            w_height = r.height;
            w_x = r.x;
            w_y = r.y;
            if (place && get_realized()) {
                do_placement();
            }
        });

        type = Gtk.WindowType.TOPLEVEL;
        set_type_hint(Gdk.WindowTypeHint.MENU);
    }

    public Popover(Gtk.Widget? relative_to, bool is_passive = false)
    {
        Object(relative_to: relative_to);
        passive = false;
    }

    public override bool draw(Cairo.Context ctx)
    {
        ctx.set_operator(Cairo.Operator.SOURCE);
        ctx.set_source_rgba(1.0, 1.0, 1.0, 0.0);
        ctx.paint();
        Gtk.Allocation alloc;
        get_allocation(out alloc);

        ctx.set_operator(Cairo.Operator.OVER);
        ctx.set_antialias(Cairo.Antialias.SUBPIXEL);

        var st = render_st.get_style_context();

        // Currently reserved, in case we ever decide on more complex
        // borders, or whatnot.
        var vis_padding = 0;

        int x, y, width, height;
        Gtk.PositionType gap_pos;

        // Ensure sizing/positioning are correct to acccount for our tail
        if (this.bottom_tail) {
            x = 0 + vis_padding;
            y = 0 + vis_padding;
            width = (alloc.width - vis_padding) - (vis_padding*2);
            height = (alloc.height - tail_height) - (vis_padding*2);
            gap_pos = Gtk.PositionType.BOTTOM;
        } else {
            x = 0 + vis_padding;
            y = 0 + vis_padding + tail_height;
            width = (alloc.width - vis_padding) - (vis_padding*2);
            height = (alloc.height - tail_height) - (vis_padding*2);
            gap_pos = Gtk.PositionType.TOP;
        }

        int gap_start;
        int gap_end;

        gap_start = widg_x;
        gap_end = gap_start+tail_width;

        // First render pass
        st.render_background(ctx, x, y, width, height);
        st.render_frame_gap(ctx, x, y, width, height, gap_pos, gap_start, gap_end);


        {
            // Clip and paint our tail region
            ctx.save();
            if (bottom_tail) {
                do_tail(ctx, gap_start+vis_padding, (height+vis_padding)-1);
            } else {
                do_tail(ctx, gap_start+vis_padding, (vis_padding+1));
            }
            ctx.clip();

            height += tail_height;
            if (bottom_tail) {
                st.render_background(ctx, x, y, width, height);
            } else {
                st.render_background(ctx, x, y-tail_height, width, height);
            }
            ctx.restore();
        }

        {
            // border time
            // TODO: Obtain line width from somewhere sensible
            ctx.set_line_width(1);
            var border_color = st.get_border_color(get_state_flags());

            ctx.set_source_rgba(border_color.red, border_color.green, border_color.blue, border_color.alpha);
            height -= tail_height;
            if (bottom_tail) {
                do_tail(ctx, gap_start+vis_padding, (height+vis_padding)-1);
            } else {
                do_tail(ctx, gap_start+vis_padding, (vis_padding+1));
            }
            ctx.stroke();
        }

        return base.draw(ctx);
    }

    protected void do_tail(Cairo.Context ctx, int x, int y)
    {
        /* Draw a triangle, basically */
        int end_y, end_x, tip_y, tip_x;

        // We only handle top or bottom, not attempting corner drawing.
        if (bottom_tail) {
            end_y = y;
            end_x = x + tail_width;
            tip_x = x+(tail_width/2);
            tip_y = y + tail_height;
        } else {
            y += tail_height;
            end_y = y;
            end_x = x + tail_width;
            tip_x = x+(tail_width/2);
            tip_y = y - tail_height;
        }

        ctx.move_to(x, y);

        ctx.line_to(tip_x, tip_y);
        ctx.line_to(end_x, end_y);
    }

    public void do_placement()
    {
        Gtk.Widget parent = relative_to;
        var toplevel = relative_to.get_toplevel() as Gtk.Window;
        int win_x, win_y;
        int trans_x, trans_y;

        our_x = 0;
        our_y = 0;

        get_child().show();
        set_attached_to(toplevel);
        queue_resize_no_redraw();

        toplevel.get_window().get_position(out win_x, out win_y);
        set_transient_for(toplevel);

        // find out where the widget is
        Gtk.Allocation widget_alloc;
        parent.get_allocation(out widget_alloc);

        // transform these into absolute coordinates
        parent.translate_coordinates(toplevel, win_x, win_y,
            out trans_x, out trans_y);

        // trans_x and and trans_y are EXACTLY where the widget is.
        our_x = trans_x;
        our_y = trans_y;

        // Should we go with top or bottom ?
        var screen = parent.get_screen();
        if (trans_y >= (screen.get_height() / 2)) {
            bottom_tail = true;
            our_y -= our_height;
        } else {
            bottom_tail = false;
            our_y += widget_alloc.height;
        }

        // Ensure we always center ourselves
        our_x += widget_alloc.width/2;
        our_x -= our_width/2;
        their_width = widget_alloc.width;


        // get the max width of the current monitor
        Gdk.Rectangle geometry;
        int monitor = screen.get_monitor_at_window(toplevel.get_window());
        screen.get_monitor_geometry(monitor, out geometry);
        int max_width = geometry.width;

        if (our_x <= 0) {
            our_x = screen_gap;
        } else if (our_x+our_width >= max_width) {
            our_x = (max_width - our_width)-screen_gap;
        }
        widg_x = (trans_x - our_x);

        // Center the tail itself.
        widg_x += ((their_width/2)-(tail_width/2));

        // And now we go and position ourselves
        move(our_x, our_y);
        queue_draw();
    }

    public override bool button_press_event(Gdk.EventButton event)
    {
        // Direct port from old budgie-popover.c
        int x, y;

        get_position(out x, out y);

        if ((event.x_root < x || event.x_root > x+our_width) ||
            (event.y_root < y || event.y_root > y+our_height)) {
            // Outside of our zone, off we go.
            hide();
            return Gdk.EVENT_STOP;
        }
        return Gdk.EVENT_PROPAGATE;
    }

    protected void do_grab()
    {
        if (passive) {
            return;
        }
        // Let's get grabbing
        Gdk.EventMask mask = 
            Gdk.EventMask.SMOOTH_SCROLL_MASK | Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK;
        Gdk.EventMask kmask = Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.KEY_RELEASE_MASK;
        Gdk.GrabStatus pst, kst;
        kst = pst = Gdk.GrabStatus.SUCCESS;
        var manager = get_screen().get_display().get_device_manager();
        var pointer = manager.get_client_pointer();
        if (pointer.associated_device != null) {
            kst = pointer.associated_device.grab(get_window(), Gdk.GrabOwnership.NONE, true, kmask, null, Gdk.CURRENT_TIME);
        }

        this.grab_focus();
        this.present();
        pst = pointer.grab(get_window(), Gdk.GrabOwnership.NONE, true, mask, null, Gdk.CURRENT_TIME);
        if (pst != Gdk.GrabStatus.SUCCESS) {
            Timeout.add(150,()=> {
                do_grab();
                return false;
            });
        } else {
            Gtk.device_grab_add(this, pointer, false);
        }
    }

    protected void do_ungrab()
    {
        if (passive) {
            return;
        }
        var manager = get_screen().get_display().get_device_manager();
        var pointer = manager.get_client_pointer();
        Gtk.device_grab_remove(this, pointer);
        pointer.ungrab(Gdk.CURRENT_TIME);
        should_regrab = false;
    }

    public override void realize() {
        base.realize();
        get_window().set_focus_on_map(true);
    }

    public override void show()
    {
        if (!get_realized()) {
            realize();
        }
        do_placement();
        base.show();
    }

    protected override bool map_event(Gdk.EventAny event)
    {
        do_grab();
        show();
        return base.map_event(event);
    }

    protected override void hide()
    {
        // Remove grabs - we done now
        do_ungrab();
        base.hide();
    }

    protected override bool grab_broken_event(Gdk.EventGrabBroken event)
    {
        should_regrab = true;
        return false;
    }

    protected override bool focus_in_event(Gdk.EventFocus focus)
    {
        /* If we've been focused again, then likely a popup menu on an
         * entry or such made us lose it - so we take it back */
        if (should_regrab) {
            do_ungrab();
            do_grab();
        }
        return base.focus_in_event(focus);
    }

    /* Override the widget path, tricking GtkThemingEngine into believing
     * we're a GtkPopover. Ensures children widgets are correctly themed */
    protected override Gtk.WidgetPath get_path_for_child(Gtk.Widget child)
    {
        Gtk.WidgetPath path = base.get_path_for_child(child);
        path.iter_set_object_type(0, this.render_st.get_type());

        return path;
    }

} // end Popover class

} // End Budgie namespace

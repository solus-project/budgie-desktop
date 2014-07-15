namespace Budgie {

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

    /* Simply ensures we retain some gap from the screen edge */
    private int screen_gap = 5;

    /* Hacky integration for C */
    private bool has_init = false;

    public Popover()
    {
    }

    protected void do_init()
    {
        if (has_init) {
            return;
        }
        destroy.connect(Gtk.main_quit);

        set_visual(get_screen().get_rgba_visual());

        set_decorated(false);
        set_border_width(2);

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

        size_allocate.connect((s) => {
            our_width = s.width;
            our_height = s.height;
        });

        // Must die on Escape
        key_press_event.connect((k) => {
            if (k.keyval == Gdk.Key.Escape) {
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

        has_init = true;
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
        var st = get_style_context();

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
        int screen_width = get_screen().get_width();

        // Normally we'll go with the centered approach
        gap_start = (our_width/2)-(tail_width/2);

        if (widg_x <= our_width/2) {
            // stuck on left hand side
            gap_start = widg_x;
            if (gap_start <= 0) {
                gap_start = 3;
            }
        } else if (widg_x >= screen_width - (our_width/2)) {
            // right hand side handling
            int tgap_start = screen_width - widg_x;
            gap_start = our_width - tgap_start;
        }
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

    public new void present(Gtk.Widget? parent = null)
    {
        var toplevel = parent.get_toplevel();
        int win_x, win_y;
        int trans_x, trans_y;

        if (!has_init) {
            do_init();
        }
        our_x = 0;
        our_y = 0;

        toplevel.get_window().get_position(out win_x, out win_y);

        // find out where the widget is
        Gtk.Allocation widget_alloc;
        parent.get_allocation(out widget_alloc);

        // transform these into absolute coordinates
        parent.translate_coordinates(toplevel, win_x, win_y,
            out trans_x, out trans_y);


        // trans_x and and trans_y are EXACTLY where the widget is.
        our_x = trans_x;
        our_y = trans_y;

        // Ensure we always have valid sizing data
        if (our_height <= 0 || our_width <= 0) {
            if (!get_realized()) {
                realize();
            }
            Gtk.Allocation our_alloc;
            get_allocation(out our_alloc);
            our_height = our_alloc.height;
            our_width = our_alloc.width;
        }

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

        // maintain a small distance from the edge of the screen, looks bad
        if (our_x <= 0) {
            our_x = screen_gap;
        } else if (our_x+our_width > get_screen().get_width()) {
            our_x = (get_screen().get_width() - our_width)-screen_gap;
        }

        their_width = widget_alloc.width;
        widg_x = trans_x;

        // And now we go and position ourselves.
        move(our_x, our_y);

        show_all();
    }

    public override bool button_press_event(Gdk.EventButton event)
    {
        // Direct port from old budgie-popover.c
        int x, y;

        get_position(out x, out y);

        if ((event.x_root < x || event.x_root > x+our_width) ||
            (event.y_root < y || event.y_root > y+our_height)) {
            // Outside of our zone, off we go.
            return base.button_press_event(event);
        }
        return true;
    }

    public override bool button_release_event(Gdk.EventButton event)
    {
        int x, y;

        get_position(out x, out y);

        if ((event.x_root < x || event.x_root > x+our_width) ||
            (event.y_root < y || event.y_root > y+our_height)) {
                    hide();
                    return false;
        }
        return true;
    }

    protected void do_grab()
    {
        // Let's get grabbing
        var manager = get_screen().get_display().get_device_manager();
        var pointer = manager.get_client_pointer();
        Gdk.EventMask mask = Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.KEY_RELEASE_MASK |
            Gdk.EventMask.SMOOTH_SCROLL_MASK | Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK;
        pointer.grab(get_window(), Gdk.GrabOwnership.NONE, true, mask, null, Gdk.CURRENT_TIME);
        Gtk.device_grab_add(this, pointer, false);
    }

    protected void do_ungrab()
    {
        var manager = get_screen().get_display().get_device_manager();
        var pointer = manager.get_client_pointer();
        Gtk.device_grab_remove(this, pointer);
        pointer.ungrab(Gdk.CURRENT_TIME);
        should_regrab = false;
    }

    protected override bool map_event(Gdk.EventAny event)
    {
        base.map();
        do_grab();
        return false;
    }

    protected override void hide()
    {
        base.hide();

        // Remove grabs - we done now
        do_ungrab();
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
            do_grab();
        }
        return base.focus_in_event(focus);
    }

} // end Popover class

} // End Budgie namespace

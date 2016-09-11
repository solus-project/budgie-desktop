/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2014-2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const string BUDGIE_STYLE_CLASS_BUTTON = "launcher";

public class ButtonWrapper : Gtk.Revealer
{
    unowned IconButton? button;

    public ButtonWrapper(IconButton? button)
    {
        this.button = button;

        this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);

        this.add(button);
        this.set_reveal_child(false);
        this.show_all();
    }

    public void gracefully_die()
    {
        if (!get_settings().gtk_enable_animations) {
            this.destroy();
            return;
        }

        this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_LEFT);
        this.notify["child-revealed"].connect_after(()=> {
            this.destroy();
        });
        this.set_reveal_child(false);
    }
}

public class IconButton : Gtk.ToggleButton
{


    private unowned AppSystem? helper = null;
    protected unowned ButtonManager? btn_manager_ = null;
    protected unowned WindowManager? window_manager = null;
    protected weak Application? application = null;

    public new Gtk.Image image;

    public int icon_size;

    protected Gtk.Allocation our_alloc;
    protected bool is_allocated = false;
    private UrgencyAnimation urgency_animation;
    // last absolute coordinates assigned to this button
    private int last_absx = -1;
    private int last_absy = -1;

    unowned Settings? settings;

    public int panel_size = 10;
    private ulong size_allocate_cb = 0;
    private ulong btn_release_cb = 0;
    private ulong btn_toggle_cb = 0;

    public IconButton(Settings? settings, int size, AppSystem? helper, int panel_size, ButtonManager btn_manager, WindowManager? window_manager)
    {
        this.settings = settings;
        this.helper = helper;
        this.btn_manager_ = btn_manager;
        this.window_manager = window_manager;

        image = new Gtk.Image();
        image.pixel_size = size;
        icon_size = size;
        this.panel_size = panel_size;
        add(image);

        relief = Gtk.ReliefStyle.NONE;
        urgency_animation = new UrgencyAnimation(this);


        // Replace styling with our own
        var st = get_style_context();
        st.remove_class(Gtk.STYLE_CLASS_BUTTON);
        st.add_class(BUDGIE_STYLE_CLASS_BUTTON);
        size_allocate_cb = size_allocate.connect(on_size_allocate);


        // Handle clicking, etc.
        btn_release_cb = button_release_event.connect(on_button_release);
        btn_toggle_cb = this.toggled.connect_after(on_toggle);
        set_can_focus(false);
    }

    public void set_button_as_running()
    {
        this.get_style_context().add_class("running");
    }

    public void set_button_as_not_running()
    {
        this.get_style_context().remove_class("running");
        set_active(false);
    }

    /**
     * This function should be called when the first application window is opened
     * to perform the initial configuration of the button.
     */
    public virtual void configure_button(ApplicationWindow appwin)
    {
        Wnck.Window window = appwin.get_window();

        // mark button as running
        set_button_as_running();
        // setup application icon
        update_icon(window);
    }

    public void begin_attention_request()
    {
        // one of the windows requested attention
        urgency_animation.begin_animation();
    }

    public void end_attention_request()
    {
        // no window is requesting attention anymore
        urgency_animation.end_animation();
    }

    public void on_toggle()
    {
        if (get_active()) {
            // Only become active if we have permission to do so
            if (!btn_manager_.can_become_active(this)) {
                set_active(false);
            }
        }
    }

    /**
     * Enforce a 1:1.1 aspect ratio
     */
    public override void get_preferred_width(out int min, out int nat)
    {
        Gtk.Allocation alloc;
        int norm = (int) ((double)panel_size * 1.1);
        min = norm;
        nat = norm;
    }

    public Wnck.Window? get_active_window()
    {
        return application.get_active_window();
    }

    public Gtk.Allocation get_allocation()
    {
        return our_alloc;
    }

    /**
     * Return the absolute coordinates of this button
     */
    public void get_coordinates(out int x, out int y)
    {
        if (!is_allocated) {
            // button has not been allocated yet. Return (0,0) coordinate
            x = 0;
            y = 0;
            return;
        }
        var toplevel = get_toplevel();
        translate_coordinates(toplevel, 0, 0, out x, out y);
        toplevel.get_window().get_root_coords(x, y, out x, out y);
    }

    /**
     * Button's size allocation changed.
     */
    protected void on_size_allocate(Gtk.Allocation alloc)
    {
        is_allocated = true;
        our_alloc = alloc;

        int new_absx, new_absy;
        get_coordinates(out new_absx, out new_absy);
        // check if the button has changed position
        if (new_absx != last_absx || new_absy != last_absy) {
            last_absx = new_absx;
            last_absy = new_absy;

            // forward the allocation change to the application object
            application.button_allocation_updated();
        }
    }

    /**
     * Update the icon
     */
    public virtual void update_icon(Wnck.Window? window)
    {
        assert(window != null);

        unowned GLib.Icon? aicon = null;
        if (application.get_info() != null) {
            aicon = application.get_info().get_icon();
        }

        if (this.helper.has_derpy_icon(window) && aicon != null) {
            image.set_from_gicon(aicon, Gtk.IconSize.INVALID);
        } else {
            if (window.get_icon_is_fallback()) {
                if (application.get_info() != null && application.get_info().get_icon() != null) {
                    image.set_from_gicon(application.get_info().get_icon(), Gtk.IconSize.INVALID);
                } else {
                    image.set_from_pixbuf(window.get_icon());
                }
            } else {
                image.set_from_pixbuf(window.get_icon());
            }
        }
        image.pixel_size = icon_size;
        // invalidates button for redraw
        queue_resize();
    }

    public virtual void update_icon_size(int new_size)
    {
        icon_size = new_size;
        image.pixel_size = icon_size;
        queue_resize();
    }

    /**
     * Either show the actions menu, toogle our window or show the window list
     * if there are more than 1 application windows opened
     */
    public virtual bool on_button_release(Gdk.EventButton event)
    {
        // Right click, i.e. actions menu
        if (event.button == 3) {
            var timestamp = Gtk.get_current_event_time();
            application.show_active_window_menu(event.button, timestamp);
            return true;
        }

        if (!application.has_window_opened()) {
            // no window. Do nothing
            return base.button_release_event(event);
        } else {
            var active_window = application.get_active_window();
            if (application.get_window_num() == 1) {
                // only one window. Toggle it
                window_manager.toggle_window(active_window);
            } else if (active_window.is_active()) {
                // multiple windows and the active one is showing. Toggle
                // window list
                window_manager.toggle_window_list(this, application.get_window_list_popover());
            } else {
                // multiple windows but the app's active one is not showing.
                // Toggle it
                window_manager.toggle_window(active_window);
            }
        }

        return base.button_release_event(event);
    }

    public virtual void set_application(Application app)
    {
        application = app;
    }

    public virtual void reset()
    {
        set_button_as_not_running();
    }

    public void reset_callbacks()
    {
        disconnect (size_allocate_cb);
        disconnect (btn_release_cb);
        disconnect (btn_toggle_cb);
        // just in case
        urgency_animation.end_animation();
    }

}

public class PinnedIconButton : IconButton
{
    protected unowned Gdk.AppLaunchContext? context;
    public string? id = null;
    private Gtk.Menu alt_menu;
    private Gtk.MenuItem unpin_item;

    unowned Settings? settings;

    public PinnedIconButton(Settings settings, int size, ref Gdk.AppLaunchContext context, AppSystem? helper, int panel_size, ButtonManager btn_manager, WindowManager window_manager)
    {
        base(settings, size, helper, panel_size, btn_manager, window_manager);
        this.settings = settings;
        this.context = context;

        // Configure Unpin menu
        alt_menu = new Gtk.Menu();
        unpin_item = new Gtk.MenuItem.with_label(_("Unpin from panel"));
        alt_menu.add(unpin_item);
        unpin_item.show_all();

        set_can_focus(false);

        // Drag and drop
        Gtk.drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, DesktopHelper.targets, Gdk.DragAction.MOVE);

        drag_begin.connect((context)=> {
            // hide window list popover if its visible
            var popover = application.get_window_list_popover();
            if (popover.get_visible()) {
                popover.hide();
            }

            if(application.get_info() != null) {
                Gtk.drag_set_icon_gicon(context, application.get_info().get_icon(), 0, 0);
            } else {
                Gtk.drag_set_icon_default(context);
            }
        });

        drag_data_get.connect((widget, context, selection_data, info, time)=> {
            selection_data.set(selection_data.get_target(), 8, (uchar []) application.get_info().get_id().to_utf8());
        });
    }

    ~PinnedIconButton()
    {
        alt_menu.destroy();
    }

    public override void set_application(Application app)
    {
        base.set_application(app);

        reset_icon();
        // Configure the unpin action using the application's app_info
        unpin_item.activate.connect(()=> {
            var app_info = application.get_info();
            if (app_info != null) {
                DesktopHelper.set_pinned(settings, app_info, false);
            }
        });
    }

    protected override bool on_button_release(Gdk.EventButton event)
    {
        if (!application.has_window_opened()) {
            if (event.button == 3) {
                // Expose our own unpin option
                alt_menu.popup(null, null, null, event.button, Gtk.get_current_event_time());
                return true;
            }
            if (event.button != 1) {
                return true;
            }
            /* Launch ourselves. */
            try {
                var app_info = application.get_info();
                context.set_screen(get_screen());
                context.set_timestamp(event.time);
                var id = context.get_startup_notify_id(app_info, null);
                this.id = id;
                app_info.launch(null, this.context);
            } catch (Error e) {
                /* Animate a UFAILED image? */
                message(e.message);
            }
            return base.on_button_release(event);
        } else {
            return base.on_button_release(event);
        }
    }

    public override void reset()
    {
        base.reset();
        string launch_text = _("Launch");

        set_tooltip_text("%s %s".printf(launch_text, application.get_info().get_display_name()));
        id = null;
        reset_icon();
    }

    private void reset_icon()
    {
        // setup the button's icon
        image.set_from_gicon(application.get_info().get_icon(), Gtk.IconSize.INVALID);
        update_icon_size(icon_size);
    }

    /**
     * This function should be called when the first application window is opened
     * to perform the initial configuration of the button.
     */
    public override void configure_button(ApplicationWindow appwin)
    {
        base.configure_button(appwin);
        set_tooltip_text("");
    }
}

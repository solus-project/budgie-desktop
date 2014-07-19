/*
 * IconTasklistApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

// So, this needs to become configurable :P
const int ICON_SIZE = 32;

const string BUDGIE_STYLE_CLASS_BUTTON = "launcher";

public class IconButton : Gtk.ToggleButton
{

    protected new Gtk.Image image;
    protected unowned Wnck.Window window;
    protected Wnck.ActionMenu menu;

    public IconButton(Wnck.Window window)
    {
        image = new Gtk.Image();
        add(image);

        this.window = window;
        set_tooltip_text(window.get_name());
        relief = Gtk.ReliefStyle.NONE;
        update_icon();
        set_active(window.is_active());

        // Replace styling with our own
        var st = get_style_context();
        st.remove_class(Gtk.STYLE_CLASS_BUTTON);
        st.add_class(BUDGIE_STYLE_CLASS_BUTTON);
        size_allocate.connect(on_size_allocate);

        // Things we can happily handle ourselves
        window.icon_changed.connect(update_icon);
        window.name_changed.connect(()=> {
            set_tooltip_text(window.get_name());
        });

        // Handle clicking, etc.
        button_release_event.connect(on_button_release);

        // Actions menu
        menu = new Wnck.ActionMenu(window);
    }

    /**
     * This is for minimize animations, etc.
     */
    protected void on_size_allocate(Gtk.Allocation alloc)
    {
        int x, y;
        var toplevel = get_toplevel();
        translate_coordinates(toplevel, 0, 0, out x, out y);
        toplevel.get_window().get_root_coords(x, y, out x, out y);
        window.set_icon_geometry(x, y, alloc.width, alloc.height);
    }

    /**
     * Update the icon
     */
    protected void update_icon()
    {
        // Prefer icon theme
        if (window.has_icon_name() && window.get_icon_name() != window.get_name()) {
            image.set_from_icon_name(window.get_icon_name(), Gtk.IconSize.INVALID);
        } else {
            image.set_from_pixbuf(window.get_icon());
        }
        image.pixel_size = ICON_SIZE;
    }

    /**
     * Either show the actions menu, or activate our window
     */
    protected bool on_button_release(Gdk.EventButton event)
    {
        var timestamp = Gtk.get_current_event_time();

        // Right click, i.e. actions menu
        if (event.button == 3) {
            menu.popup(null, null, null, event.button, timestamp);
            return true;
        }

        // Normal left click, go handle the window
        if (window.is_minimized()) {
            window.unminimize(timestamp);
            window.activate(timestamp);
        } else {
            if (window.is_active()) {
                window.minimize();
            } else {
                window.activate(timestamp);
            }
        }

        return true;
    }
            
}

public class IconTasklistApplet : Budgie.Plugin, Peas.ExtensionBase
{

    protected Gtk.Box widget;
    protected Wnck.Screen screen;
    protected Gee.HashMap<Wnck.Window,IconButton> buttons;

    construct {
        init_ui();
    }

    protected void window_opened(Wnck.Window window)
    {
        // doesn't go on our list
        if (window.is_skip_tasklist()) {
            return;
        }
        var btn = new IconButton(window);
        buttons[window] = btn;
        widget.pack_start(btn, false, false, 0);
        btn.show_all();
    }

    protected void window_closed(Wnck.Window window)
    {
        IconButton? btn = null;
        if (!buttons.has_key(window)) {
            warning("Invalid window discovered!!");
            return;
        }
        btn = buttons[window];
        btn.destroy();
    }

    /**
     * Just update the active state on the buttons
     */
    protected void active_window_changed(Wnck.Window? previous_window)
    {
        IconButton? btn;
        Wnck.Window? new_active;
        if (previous_window != null)
        {
            // Update old active button
            if (buttons.has_key(previous_window)) {
                btn = buttons[previous_window];
                btn.set_active(false);
            } 
        }
        new_active = screen.get_active_window();
        if (new_active == null) {
            return;
        }
        if (!buttons.has_key(new_active)) {
            return;
        }
        btn = buttons[new_active];
        btn.set_active(true);
    }

    protected void init_ui()
    {
        // Init wnck
        Wnck.set_client_type(Wnck.ClientType.PAGER);
        screen = Wnck.Screen.get_default();
        screen.window_opened.connect(window_opened);
        screen.window_closed.connect(window_closed);
        screen.active_window_changed.connect(active_window_changed);

        // Easy mapping :)
        buttons = new Gee.HashMap<Wnck.Window,IconButton>(null,null,null);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        /* Update orientation when parent panel does
         * TODO: Have support for left/right hand side launchers, etc
         * with the position_changed signal */

        orientation_changed.connect((o)=> {
            widget.set_orientation(o);
        });
    }
        
    public Gtk.Widget get_panel_widget()
    {
        return widget;
    }

} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(IconTasklistApplet));
}

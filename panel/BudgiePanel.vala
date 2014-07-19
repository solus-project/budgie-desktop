/*
 * BudgiePanel.vala
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

public class Panel : Gtk.Window
{

    private int intended_height = 40;
    private PanelPosition position;
    private Gtk.Box master_layout;
    private Gtk.Box widgets_area;

    Peas.Engine engine;
    // Must keep in scope otherwise they garbage collect and die
    Budgie.Plugin tasklist;
    Budgie.Plugin clock;
    Settings settings;

    /* Totally temporary - we'll extend to user plugins in the end and
     * ensure these directories are correct at compile time */
    static string module_directory = "/usr/lib/budgie-desktop";
    static string module_data_directory = "/usr/share/budgie-panel/plugins";

    public Panel()
    {
        /* Set an RGBA visual whenever we can */
        Gdk.Visual? vis = screen.get_rgba_visual();
        if (vis != null) {
            set_visual(vis);
        } else {
            message("No RGBA visual available");
        }
        app_paintable = true;
        resizable = false;

        /* Ensure to initialise styles */
        try {
            File ruri = File.new_for_uri("resource://com/evolve-os/budgie/panel/style.css");
            var prov = new Gtk.CssProvider();
            prov.load_from_file(ruri);
            Gtk.StyleContext.add_provider_for_screen(screen, prov, Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);

            ruri = File.new_for_uri("resource://com/evolve-os/budgie/panel/app.css");
            prov = new Gtk.CssProvider();
            prov.load_from_file(ruri);
            Gtk.StyleContext.add_provider_for_screen(screen, prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            stderr.printf("Unable to load styles: %s\n", e.message);
        }

        // Base styling
        get_style_context().remove_class("background");
        get_style_context().add_class("budgie-panel");

        // simple layout
        master_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(master_layout);

        set_decorated(false);
        type_hint = Gdk.WindowTypeHint.DOCK;
        set_keep_above(true);

        size_allocate.connect((s) => {
            update_position();
            set_struts();
        });

        // Initialize plugins engine
        engine = Peas.Engine.get_default();
        engine.add_search_path(module_directory, module_data_directory);
        // Home directory
        var dirm = "%s/budgie-panel".printf(Environment.get_user_data_dir());
        engine.add_search_path(dirm, null);
        var extset = new Peas.ExtensionSet(engine, typeof(Budgie.Plugin));

        // Get an update from GSettings where we should be (position set
        // for error fallback)
        position = PanelPosition.BOTTOM;
        settings = new Settings("com.evolve-os.budgie.panel");
        settings.changed.connect(on_settings_change);
        on_settings_change("location");

        // where the clock, etc, live
        var widgets_wrap = new Gtk.EventBox();
        widgets_wrap.get_style_context().add_class("message-area");
        widgets_wrap.margin = 3;
        widgets_area = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        widgets_area.margin = 2;
        widgets_wrap.add(widgets_area);
        master_layout.pack_end(widgets_wrap, false, false, 0);

        // Right now our plugins are kinda locked in where they go. Sorry
        extset.extension_added.connect((i,p) => {
            var plugin = p as Budgie.Plugin;
            var widget = plugin.get_panel_widget();

            if (i.get_name() == "Clock Applet") {
                widgets_area.pack_end(widget, false, false, 0);
                clock = plugin;
            } else if (i.get_name() == "Icon Tasklist") {
                tasklist = plugin;
                master_layout.pack_start(widget, true, true, 0);
            }
        });

        load_plugin("Clock Applet");
        load_plugin("Icon Tasklist");

        show_all();

        set_struts();
    }

    protected void on_settings_change(string key)
    {
        if (key == "location") {
            var val = settings.get_string(key);
            switch (val) {
                case "top":
                    position = PanelPosition.TOP;
                    break;
                case "left":
                    position = PanelPosition.LEFT;
                    break;
                case "right":
                    position = PanelPosition.RIGHT;
                    break;
                default:
                    position = PanelPosition.BOTTOM;
                    break;
            }
            update_position();
            set_struts();
        }
    }

    protected void load_plugin(string plugin_name)
    {
        foreach (var plugin in engine.get_plugin_list()) {
            if (plugin.get_name() == plugin_name) {
                engine.try_load_plugin(plugin);
                return;
            }
        }
        stdout.printf("Unable to load %s\n", plugin_name);
    }

    /* Struts on X11 are used to reserve screen-estate, i.e. for guys like us.
     * woo.
     */
    protected void set_struts()
    {
        Gdk.Atom atom;
        long struts[4];

        if (!get_realized()) {
            return;
        }

        // Struts dependent on position
        switch (position) {
            case PanelPosition.TOP:
                struts = { 0, 0, intended_height, 0};
                break;
            case PanelPosition.LEFT:
                struts = { intended_height, 0, 0, 0 };
                break;
            case PanelPosition.RIGHT:
                struts = { 0, intended_height, 0, 0};
                break;
            case PanelPosition.BOTTOM:
            default:
                struts = { 0, 0, 0, intended_height };
                break;
        }

        atom = Gdk.Atom.intern("_NET_WM_STRUT", false);
        Gdk.property_change(get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
            32, Gdk.PropMode.REPLACE, (uint8[])struts, 4);
    }

    protected void update_position()
    {
        int height = get_allocated_height();
        int width = get_allocated_width();
        int x = 0, y = 0;
        // temp
        Budgie.Plugin[] applets = {tasklist, clock};

        string[] classes =  {
            "top",
            "bottom",
            "left",
            "right"
        };
        string newclass;
        switch (position) {
            case PanelPosition.TOP:
                newclass = "top";
                y = 0;
                break;
            case PanelPosition.LEFT:
                newclass = "left";
                y = 0;
                break;
            case PanelPosition.RIGHT:
                newclass = "right";
                x = get_screen().get_width()-width;
                break;
            case PanelPosition.BOTTOM:
            default:
                newclass = "";
                y = get_screen().get_height()-height;
                break;
        }
        var st = get_style_context();
        foreach (var tclass in classes) {
            if (newclass != tclass) {
                st.remove_class(tclass);
            }
        }
        if (newclass != "") {
            st.add_class(newclass);
        }

        Gtk.Orientation orientation;

        if (position == PanelPosition.LEFT || position == PanelPosition.RIGHT) {
            // Effectively we're now vertical. deal with it.
            orientation = Gtk.Orientation.VERTICAL;
        } else {
            orientation = Gtk.Orientation.HORIZONTAL;
        }

        master_layout.set_orientation(orientation);
        // Eventually foreach the loaded applets
        foreach (var applet in applets) {
            if (applet != null) {
                applet.orientation_changed(orientation);
                applet.position_changed(position);
            }
        };

        move(x,y);

        queue_draw();
    }

    /**
     * Ensure our CSS theming is followed. In future we'll enable much more
     * in the way of customisations (background image anyone?)
     */
    public override bool draw(Cairo.Context cr)
    {
        var st = get_style_context();

        st.render_background(cr, 0, 0, get_allocated_width(), get_allocated_height());
        st.render_frame(cr, 0, 0, get_allocated_width(), get_allocated_height());

        return base.draw(cr);
    }


    /* The next methods are all designed to force a specific size only! */
    public override void get_preferred_width(out int min, out int natural)
    {
        var width = screen.get_width();
        if (position == PanelPosition.LEFT || position == PanelPosition.RIGHT) {
            width = intended_height;
        }
        min = width;
        natural = width;
    }

    public override void get_preferred_height(out int min, out int natural)
    {
        if (position == PanelPosition.LEFT || position == PanelPosition.RIGHT) {
            min = screen.get_height();
            natural = min;
        } else {
            min = intended_height;
            natural = intended_height;
        }
    }

    public override void get_preferred_height_for_width(int width, out int min, out int natural)
    {
        if (position == PanelPosition.LEFT || position == PanelPosition.RIGHT) {
            min = screen.get_height();
            natural = min;
        } else {
            min = intended_height;
            natural = intended_height;
        }
    }

    public override void get_preferred_width_for_height(int height, out int min, out int natural)
    {
        var width = screen.get_width();
        if (position == PanelPosition.LEFT || position == PanelPosition.RIGHT) {
            width = intended_height;
        }
        min = width;
        natural = width;
    }

} // End Panel class

} // End Budgie namespace

public static int main(string[] args)
{
    Gtk.init(ref args);
    Budgie.Panel panel;

    panel = new Budgie.Panel();
    Gtk.main();

    // TODO: Convert to an application
    panel = null;

    return 0;
}

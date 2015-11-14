/*
 * This file is part of arc-desktop
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Arc
{

/**
 * The main panel area - i.e. the bit that's rendered
 */
public class MainPanel : Gtk.Box
{
    public int intended_size;

    public MainPanel(int size)
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL);
        this.intended_size = size;
        get_style_context().add_class("arc-panel");
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = intended_size;
        n = intended_size;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = intended_size;
        n = intended_size;
    }
}

/**
 * The toplevel window for a panel
 */
public class Panel : Gtk.Window
{

    Gdk.Rectangle scr;
    int intended_height = 42 + 5;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;
    Gtk.Box main_layout;

    public Arc.PanelPosition? position;

    public Settings settings { construct set ; public get; }
    public string uuid { construct set ; public get; }

    PopoverManager manager;
    bool expanded = true;

    Arc.ShadowBlock shadow;

    construct {
        position = PanelPosition.NONE;
    }

    /**
     * Force update the geometry
     */
    public void update_geometry(Gdk.Rectangle screen, PanelPosition position)
    {
        Gdk.Rectangle small = screen;

        switch (position) {
            case PanelPosition.TOP:
            case PanelPosition.BOTTOM:
                small.height = intended_height;
                break;
            default:
                small.width = intended_height;
                break;
        }
        if (position != this.position) {
            this.settings.set_enum(Arc.PANEL_KEY_POSITION, position);
        }
        this.position = position;
        this.small_scr = small;
        this.orig_scr = screen;

        if (this.expanded) {
            this.scr = this.orig_scr;
        } else {
            this.scr = this.small_scr;
        }
        shadow.required_size = orig_scr.width;
        this.shadow.position = position;
        queue_resize();
        placement();
    }

    public Panel(string? uuid, Settings? settings)
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK, settings: settings, uuid: uuid);


        load_css();

        manager = new PopoverManager(this);

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("Compositing not available, things will Look Bad (TM)");
        } else {
            set_visual(vis);
        }
        resizable = false;
        app_paintable = true;
        get_style_context().add_class("arc-container");

        main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(main_layout);


        layout = new MainPanel(intended_height - 5);
        layout.vexpand = false;
        vexpand = false;
        main_layout.pack_start(layout, false, false, 0);
        main_layout.valign = Gtk.Align.START;

        /* Shadow.. */
        shadow = new Arc.ShadowBlock(this.position);
        shadow.hexpand = false;
        shadow.halign = Gtk.Align.START;
        shadow.show_all();
        main_layout.pack_start(shadow, false, false, 0);

        get_child().show_all();
        set_expanded(false);
    }

    public override void map()
    {
        base.map();
        placement();
    }

    void load_css()
    {
        try {
            var f = File.new_for_uri("resource://com/solus-project/arc/panel/default.css");
            var css = new Gtk.CssProvider();
            css.load_from_file(f);
            Gtk.StyleContext.add_provider_for_screen(screen, css, Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);

            var f2 = File.new_for_uri("resource://com/solus-project/arc/panel/style.css");
            var css2 = new Gtk.CssProvider();
            css2.load_from_file(f2);
            Gtk.StyleContext.add_provider_for_screen(screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning("CSS Missing: %s", e.message);
        }
    }

    public override void get_preferred_width(out int m, out int n)
    {
        m = scr.width;
        n = scr.width;
    }
    public override void get_preferred_width_for_height(int h, out int m, out int n)
    {
        m = scr.width;
        n = scr.width;
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = scr.height;
        n = scr.height;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = scr.height;
        n = scr.height;
    }

    public void set_expanded(bool expanded)
    {
        if (this.expanded == expanded) {
            return;
        }
        this.expanded = expanded;
        if (!expanded) {
            scr = small_scr;
        } else {
            scr = orig_scr;
        }
        queue_resize();
        if (expanded) {
            present();
        }
    }

    void placement()
    {
        Arc.set_struts(this, position, intended_height - 5);
        switch (position) {
            case Arc.PanelPosition.TOP:
                move(orig_scr.x, orig_scr.y);
                break;
            default:
                main_layout.valign = Gtk.Align.END;
                move(orig_scr.x, orig_scr.y+(orig_scr.height-intended_height));
                main_layout.reorder_child(shadow, 0);
                shadow.get_style_context().add_class("bottom");
                set_gravity(Gdk.Gravity.SOUTH);
                break;
        }
    }
}

} // End namespace

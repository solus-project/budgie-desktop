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

public class PopoverManager : Object {
    HashTable<Gtk.Widget?,Gtk.Popover?> widgets;

    unowned Arc.Panel? owner;
    unowned Gtk.Popover? visible_popover = null;

    bool grabbed = false;
    bool mousing = false;


    public PopoverManager(Arc.Panel? owner)
    {
        this.owner = owner;
        widgets = new HashTable<Gtk.Widget?,Gtk.Popover?>(direct_hash, direct_equal);

        owner.focus_out_event.connect(()=>{
            if (mousing) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (visible_popover != null) {
                visible_popover.hide();
                make_modal(visible_popover, false);
                visible_popover = null;
            }
            return Gdk.EVENT_PROPAGATE;
        });
        owner.button_press_event.connect((w,e)=> {
            if (!grabbed) {
                return Gdk.EVENT_PROPAGATE;
            }
            Gtk.Allocation alloc;
            visible_popover.get_allocation(out alloc);

            if (owner.position == PanelPosition.BOTTOM) {
                /* GTK is on serious amounts of crack, Y is always 0. */
                Gtk.Allocation parent;
                owner.get_allocation(out parent);
                alloc.y = parent.height - alloc.height;
            }
            if ((e.x < alloc.x || e.x > alloc.x+alloc.width) ||
                (e.y < alloc.y || e.y > alloc.y+alloc.height)) {
                    visible_popover.hide();
                    make_modal(visible_popover, false);
                    visible_popover = null;
            }
            return Gdk.EVENT_STOP;

        });
        owner.add_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.BUTTON_PRESS_MASK);
    }

    void make_modal(Gtk.Popover? pop, bool modal = true)
    {
        if (pop == null || pop.get_window() == null || mousing) {
            return;
        }
        if (modal) {
            if (grabbed) {
                return;
            }
            Gtk.grab_add(owner);
            owner.set_focus(null);
            pop.grab_focus();
            grabbed = true;
        } else {
            if (!grabbed) {
                return;
            }
            Gtk.grab_remove(owner);
            owner.grab_focus();
            grabbed = false;
        }
    }

    public void unregister_popover(Gtk.Widget? widg)
    {
        if (!widgets.contains(widg)) {
            return;
        }
        widgets.remove(widg);
    }

    public void register_popover(Gtk.Widget? widg, Gtk.Popover? popover)
    {
        if (widgets.contains(widg)) {
            return;
        }
        if (widg is Gtk.MenuButton) {
            (widg as Gtk.MenuButton).can_focus = false;
        } 
        popover.map.connect((p)=> {
            owner.set_expanded(true);
            this.visible_popover = p as Gtk.Popover;
            make_modal(this.visible_popover);
        });
        popover.closed.connect((p)=> {
            if (!mousing && grabbed) {
                make_modal(p, false);
                visible_popover = null;
            }
        });
        widg.enter_notify_event.connect((w,e)=> {
            if (mousing) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (grabbed) {
                if (widgets.contains(w)) {
                    if (visible_popover != widgets[w] && visible_popover != null) {
                        /* Hide current popover, re-open next */
                        mousing = true;
                        visible_popover.hide();
                        visible_popover = widgets[w];
                        visible_popover.show_all();
                        owner.set_focus(null);
                        visible_popover.grab_focus();
                        mousing = false;
                    }
                }
                return Gdk.EVENT_STOP;
            }
            return Gdk.EVENT_PROPAGATE;
        });
        popover.notify["visible"].connect(()=> {
            if (mousing || grabbed) {
                return;
            }
            if (!popover.get_visible()) {
                make_modal(visible_popover, false);
                visible_popover = null;
                owner.set_expanded(false);
            }
        });
        popover.destroy.connect((w)=> {
            widgets.remove(w);
        });
        popover.modal = false;
        widgets.insert(widg, popover);
    }
}

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

public class Panel : Gtk.Window
{

    Gdk.Rectangle scr;
    int intended_height = 42 + 5;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;
    Gtk.Box main_layout;

    public Arc.PanelPosition? position;

    PopoverManager manager;
    bool expanded = true;

    Arc.HShadowBlock shadow;

    construct {
        position = PanelPosition.BOTTOM;
    }

    public Panel()
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK);


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

        // TODO: Track
        var mon = screen.get_primary_monitor();
        screen.get_monitor_geometry(mon, out orig_scr);

        /* Smaller.. */
        small_scr = orig_scr;
        small_scr.height = intended_height;

        scr = small_scr;

        main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(main_layout);


        layout = new MainPanel(intended_height - 5);
        layout.vexpand = false;
        vexpand = false;
        main_layout.pack_start(layout, false, false, 0);
        main_layout.valign = Gtk.Align.START;

        /* Shadow.. */
        shadow = new Arc.HShadowBlock();
        shadow.hexpand = false;
        shadow.halign = Gtk.Align.START;
        shadow.show_all();
        shadow.required_size = orig_scr.width;
        main_layout.pack_start(shadow, false, false, 0);

        realize();
        placement();
        get_child().show_all();
        set_expanded(false);
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

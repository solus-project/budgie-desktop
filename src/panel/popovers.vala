/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Budgie
{

public class PopoverManagerImpl : PopoverManager, GLib.Object
{
    HashTable<Gtk.Widget?,Gtk.Popover?> widgets;

    unowned Budgie.Panel? owner;
    unowned Gtk.Popover? visible_popover = null;

    bool grabbed = false;
    bool mousing = false;


    public PopoverManagerImpl(Budgie.Panel? owner)
    {
        this.owner = owner;
        widgets = new HashTable<Gtk.Widget?,Gtk.Popover?>(direct_hash, direct_equal);

        owner.focus_out_event.connect(()=>{
            if (mousing) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (visible_popover != null) {
                visible_popover.popdown();
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
                    visible_popover.popdown();
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

    public void show_popover(Gtk.Widget? parent) {
        unowned Gtk.Popover? pop = widgets.lookup(parent);
        if (pop == null) {
            return;
        }

        pop.set_modal(false);
        owner.set_expanded(true);
        Idle.add(()=> {
            Gtk.Widget? relative_to = pop.get_relative_to();
            if (owner.get_window() != null) {
                owner.get_window().focus(Gdk.CURRENT_TIME);
            }
            owner.present();
            pop.set_relative_to(null);
            pop.set_relative_to(relative_to);
            pop.queue_resize();
            while (Gtk.events_pending()) {
                Gtk.main_iteration();
            }
            Idle.add(()=>{
                if (!pop.get_visible()) {
                    pop.popup();
                }
                return false;
            });
            return false;
        });
    }

    void on_widget_mapped(Gtk.Widget? p)
    {
        owner.set_expanded(true);
        this.visible_popover = p as Gtk.Popover;
        make_modal(this.visible_popover);
    }

    void on_popover_closed(Gtk.Popover? p)
    {
        if (!mousing && grabbed) {
            make_modal(p, false);
            visible_popover = null;
        }
    }

    bool enter_notify_event(Gtk.Widget? w, Gdk.Event? e)
    {
        if (mousing) {
            return Gdk.EVENT_PROPAGATE;
        }
        if (grabbed) {
            if (widgets.contains(w) && w.get_visible()) {
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
    }

    void notify_visible(Object? o, ParamSpec spec)
    {
        Gtk.Popover? popover = o as Gtk.Popover;

        if (mousing || grabbed) {
            return;
        }
        if (!popover.get_visible()) {
            make_modal(visible_popover, false);
            visible_popover = null;
            owner.set_expanded(false);
        }
    }

    public void register_popover(Gtk.Widget? widg, Gtk.Popover? popover)
    {
        if (widgets.contains(widg)) {
            return;
        }
        if (widg is Gtk.MenuButton) {
            (widg as Gtk.MenuButton).can_focus = false;
        } 
        popover.map.connect(on_widget_mapped);
        popover.closed.connect(on_popover_closed);

        widg.enter_notify_event.connect(enter_notify_event);
        popover.notify["visible"].connect_after(notify_visible);
        popover.destroy.connect((w)=> {
            widgets.remove(w);
        });
        popover.modal = false;
        widgets.insert(widg, popover);
    }
}
} // End namespace

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */

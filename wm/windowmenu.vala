/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

public class WindowMenu : Gtk.Menu
{

    private new unowned Meta.Window? window = null;

    public unowned Meta.Window? meta_window {
        public set {
            this.window = value;
            update_menus();
        }
        public get {
            return this.window;
        }
    }

    public bool can_show() {
        return this.window != null;
    }

    void update_menus()
    {
        if (window == null) {
            return;
        }

        minimize.sensitive = this.window.can_minimize();
        maximize.sensitive = this.window.can_maximize();
        close.sensitive = this.window.can_close();
        move.sensitive = this.window.allows_move();
        resize.sensitive = this.window.allows_resize();

        bool is_max = this.window.get_maximized() != 0;
        unmaximize.set_visible(is_max);
        maximize.set_visible(!is_max);
        minimize.set_visible(this.window.can_minimize());
    }

    void minimize_cb()
    {
        if (this.window == null) {
            return;
        }
        this.window.minimize();
    }

    void unmaximize_cb()
    {
        if (this.window == null) {
            return;
        }
        this.window.unmaximize(Meta.MaximizeFlags.BOTH);
    }

    void maximize_cb()
    {
        if (this.window == null) {
            return;
        }
        this.window.maximize(Meta.MaximizeFlags.BOTH);
    }

    void close_cb()
    {
        if (this.window == null) {
            return;
        }
        this.window.delete(Clutter.CURRENT_TIME);
    }

    void move_cb()
    {
        if (this.window == null) {
            return;
        }
        this.window.begin_grab_op(Meta.GrabOp.KEYBOARD_MOVING, true, Clutter.CURRENT_TIME);
    }

    void resize_cb()
    {
        if (this.window == null) {
            return;
        }
        this.window.begin_grab_op(Meta.GrabOp.KEYBOARD_RESIZING_UNKNOWN, true, Clutter.CURRENT_TIME);
    }

    void always_on_top_cb()
    {
        if (this.window == null) {
            return;
        }
        always_on_top.freeze_notify();
        if (this.window.is_above()) {
            this.window.unmake_above();
        } else {
            this.window.make_above();
        }
        always_on_top.thaw_notify();
    }

    new Gtk.MenuItem? minimize = null;
    new Gtk.MenuItem? maximize = null;
    new Gtk.MenuItem? unmaximize = null;
    new Gtk.MenuItem? move = null;
    new Gtk.MenuItem? resize = null;
    new Gtk.MenuItem? always_on_top = null;
    new Gtk.MenuItem? close = null;

    construct {
        Gtk.MenuItem? item = null;

        minimize = new Gtk.MenuItem.with_label(_("Minimize"));
        minimize.activate.connect(minimize_cb);
        add(minimize);
        minimize.show_all();

        unmaximize = new Gtk.MenuItem.with_label(_("Unmaximize"));
        maximize.activate.connect(unmaximize_cb);
        add(unmaximize);
        unmaximize.show_all();

        maximize = new Gtk.MenuItem.with_label(_("Maximize"));
        maximize.activate.connect(maximize_cb);
        add(maximize);
        maximize.show_all();

        move = new Gtk.MenuItem.with_label(_("Move"));
        move.activate.connect(move_cb);
        add(move);
        move.show_all();

        resize = new Gtk.MenuItem.with_label(_("Resize"));
        resize.activate.connect(resize_cb);
        add(resize);
        resize.show_all();

        always_on_top = new Gtk.MenuItem.with_label(_("Always On Top"));
        always_on_top.activate.connect(always_on_top_cb);
        add(always_on_top);
        always_on_top.show_all();

        close = new Gtk.MenuItem.with_label(_("Close"));
        close.activate.connect(close_cb);
        add(close);
        close.show_all();
    }
}

} /* End namespace */
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

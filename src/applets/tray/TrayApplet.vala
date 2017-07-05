/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class TrayPlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new TrayApplet();
    }
}

public class TrayApplet : Budgie.Applet
{
    protected Na.Tray? tray = null;
    /* Fix this. Please. */
    protected int icon_size = 22;
    Gtk.EventBox box;

    int width;
    int height;

    Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;

    public TrayApplet()
    {
        box = new Gtk.EventBox();
        add(box);

        valign = Gtk.Align.CENTER;
        box.valign = Gtk.Align.CENTER;
        box.vexpand = false;
        vexpand = false;

        map.connect_after(()=> {
            maybe_integrate_tray();
        });


        show_all();
        panel_size_changed.connect((p,i,s)=> {
            this.icon_size = s;
            if (tray != null) {
                tray.set_icon_size(icon_size);
                queue_resize();
                tray.queue_resize();
            }
        });

        size_allocate.connect(on_size_allocate);
    }

    public override void panel_position_changed(Budgie.PanelPosition position)
    {
        if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
            this.orient = Gtk.Orientation.VERTICAL;
        } else {
            this.orient = Gtk.Orientation.HORIZONTAL;
        }

        if (tray == null) {
            return;
        }

        this.box.remove(this.tray);
        this.tray = null;
        this.maybe_integrate_tray();
        this.show_all();
    }

    void on_size_allocate(Gtk.Allocation alloc)
    {
        if (!get_realized() || get_parent() == null) {
            return;
        }
        if (this.width != alloc.width || this.height != alloc.height) {
            this.width = alloc.width;
            this.height = alloc.height;
            this.get_parent().queue_resize();
            this.get_toplevel().queue_resize();
        }
    }


    public override void get_preferred_height(out int m, out int n)
    {
        if (this.orient == Gtk.Orientation.HORIZONTAL) {
            m = icon_size;
            n = icon_size;
            return;
        }
        int om, on;
        base.get_preferred_height(out om, out on);
        m = om;
        n = on;
    }

    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        if (this.orient == Gtk.Orientation.HORIZONTAL) {
            m = icon_size;
            n = icon_size;
            return;
        }
        int om, on;
        base.get_preferred_height_for_width(w, out om, out on);
        m = om;
        n = on;
    }

    public override void get_preferred_width(out int m, out int n)
    {
        if (this.orient == Gtk.Orientation.VERTICAL) {
            m = icon_size;
            n = icon_size;
            return;
        }
        int om, on;
        base.get_preferred_width(out om, out on);
        m = om;
        n = on;
    }

    public override void get_preferred_width_for_height(int h, out int m, out int n)
    {
        if (this.orient == Gtk.Orientation.VERTICAL) {
            m = icon_size;
            n = icon_size;
            return;
        }
        int om, on;
        base.get_preferred_width_for_height(h, out om, out on);
        m = om;
        n = on;
    }

    protected void maybe_integrate_tray()
    {
        if (tray != null) {
            return;
        }

        switch (this.orient) {
        case Gtk.Orientation.HORIZONTAL:
            valign = Gtk.Align.CENTER;
            box.valign = Gtk.Align.CENTER;
            box.halign = Gtk.Align.START;
            halign = Gtk.Align.START;
            box.vexpand = false;
            vexpand = false;
            break;
        case Gtk.Orientation.VERTICAL:
            valign = Gtk.Align.START;
            box.valign = Gtk.Align.START;
            box.halign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;
            box.vexpand = false;
            vexpand = false;
            break;
        }

        tray = new Na.Tray.for_screen(this.orient);
        if (tray == null) {
            var label = new Gtk.Label("Tray unavailable");
            add(label);
            label.show_all();
            return;
        }
        tray.set_icon_size(icon_size);
        tray.set_size_request(-1, -1);

        Gdk.RGBA fg = {};
        Gdk.RGBA warning = {};
        Gdk.RGBA error = {};
        Gdk.RGBA success = {};

        fg.parse("white");
        warning.parse("red");
        error.parse("orange");
        success.parse("white");

        tray.set_colors(fg, error, warning, success);
        box.add(tray);
        show_all();

        var win = this.get_toplevel();
        if (win == null) {
            return;
        }
        win.queue_draw();
        this.queue_resize();
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(TrayPlugin));
}

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

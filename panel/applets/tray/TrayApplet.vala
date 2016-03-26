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

    public TrayApplet()
    {
        margin = 1;
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
                tray.force_redraw();
            }
        });

        size_allocate.connect(on_size_allocate);
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
        m = icon_size;
        n = icon_size;
    }

    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = icon_size;
        n = icon_size;
    }

    protected void maybe_integrate_tray()
    {
        if (tray != null) {
            return;
        }

        tray = new Na.Tray.for_screen(get_screen(), Gtk.Orientation.HORIZONTAL);
        if (tray == null) {
            var label = new Gtk.Label("Tray unavailable");
            add(label);
            label.show_all();
            return;
        }
        tray.set_icon_size(icon_size);

        Gdk.Color fg;
        Gdk.Color warning;
        Gdk.Color error;
        Gdk.Color success;

        Gdk.Color.parse("white", out fg);
        Gdk.Color.parse("red", out error);
        Gdk.Color.parse("orange", out warning);
        Gdk.Color.parse("white", out success);

        tray.set_colors(fg, error, warning, success);
        box.add(tray);
        show_all();

        var win = this.get_toplevel();
        if (win == null) {
            return;
        }
        win.queue_draw();
        tray.force_redraw();
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

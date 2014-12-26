/*
 * StatusApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
public class StatusApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new StatusAppletImpl();
    }
}

public class StatusAppletImpl : Budgie.Applet
{

    protected Gtk.Box widget;
    protected SoundIndicator sound;
    protected PowerIndicator power;
    protected Budgie.Popover popover;
    protected MprisWidget mpris;
    protected AccountsUser? user;
    protected Gtk.Image user_img;

    public StatusAppletImpl()
    {
        var wrap = new Gtk.EventBox();
        add(wrap);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrap.add(widget);
        wrap.margin_left = 4;
        wrap.margin_right = 2;

        power = new PowerIndicator();
        widget.pack_start(power, false, false, 0);

        sound = new SoundIndicator();
        widget.pack_start(sound, false, false, 0);

        var image = new Gtk.Image.from_icon_name("system-shutdown-symbolic", Gtk.IconSize.INVALID);
        image.margin = 2;
        widget.pack_start(image, false, false, 0);


        create_popover();
        setup_user();

        orientation_changed.connect((o)=> {
            widget.set_orientation(o);
        });

        wrap.button_release_event.connect((e) => {
            if (e.button == 1) {
                show_popover();
            }
            return false;
        });

        icon_size_changed.connect((i,s)=> {
            image.pixel_size = (int)s;
            power.widget.pixel_size = (int)s;
            sound.widget.pixel_size = (int)s;
        });
        show_all();
    }

    /**
     * Note: This is not dynamic.. We don't get a properties changed event for iconfile
     */
    protected void setup_user()
    {
        try {
            AccountsService proxy = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.Accounts", "/org/freedesktop/Accounts");
            var path = proxy.FindUserById(Posix.getuid());
            user = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.Accounts", path);
        } catch (Error e) {
            message("AccountsService query failed: %s", e.message);
        }
        if (user != null) {
            try {
                var pbuf = new Gdk.Pixbuf.from_file_at_size(user.icon_file, 22, 22);
                user_img.set_from_pixbuf(pbuf);
            } catch (Error e) {
                message("Unable to update user image: %s", e.message);
            }
        }
    }

    protected void create_popover()
    {
        popover = new Budgie.Popover();

        var grid = new Gtk.Grid();
        grid.set_border_width(6);
        grid.set_halign(Gtk.Align.FILL);
        grid.column_spacing = 10;
        grid.row_spacing = 10;
        popover.add(grid);
        int row = 0;
        const int width = 3;

        /* mpris widget */
        mpris = new MprisWidget();
        grid.attach(mpris, 0, row, width, 1);
        row += 1;

        /* sound row */
        grid.attach(sound.status_image, 0, row, 1, 1);
        /* Add sound widget */
        grid.attach(sound.status_widget, 1, row, width-1, 1);
        sound.status_widget.hexpand = true;
        sound.status_widget.halign = Gtk.Align.FILL;
        sound.status_widget.valign = Gtk.Align.END;
        sound.status_image.valign = Gtk.Align.CENTER;
        sound.status_image.margin_top = 6; /* Due to mark */
        sound.status_widget.margin_left = 2; /* Due to button for settings */

        var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        row += 1;
        grid.attach(sep, 0, row, width, 1);
        row += 1;

        /* Settings */
        var img = new Gtk.Image.from_icon_name("preferences-system-symbolic", Gtk.IconSize.INVALID);
        grid.attach(img, 0, row, 1, 1);
        img.pixel_size = 22;
        var label = new Gtk.Button.with_label("Settings");
        label.set_relief(Gtk.ReliefStyle.NONE);
        label.set_property("margin-left", 1);
        label.get_child().set_halign(Gtk.Align.START);
        label.clicked.connect(()=>{
            popover.hide();
            try {
                Process.spawn_command_line_async("gnome-control-center");
            } catch (Error e) {
                message("Error invoking gnome-control-center: %s", e.message);
            }
        });
        label.halign = Gtk.Align.FILL;
        label.hexpand = true;
        grid.attach(label, 1, row, width-1, 1);

        /* Separator */
        sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        row += 1;
        grid.attach(sep, 0, row, width, 1);
        row += 1;

        /* Session controls */
        user_img = new Gtk.Image.from_icon_name("user-info-symbolic", Gtk.IconSize.INVALID);
        user_img.pixel_size = 22;
        grid.attach(user_img, 0, row, 1, 1);

        /* clickable username.. change account options */
        label = new Gtk.Button.with_label(Environment.get_user_name());
        label.clicked.connect(()=> {
            popover.hide();
            try {
                Process.spawn_command_line_async("gnome-control-center user-accounts");
            } catch (Error e) {
                message("Error invoking gnome-control-center user-accounts: %s", e.message);
            }
        });
        label.halign = Gtk.Align.FILL;
        label.hexpand = true;
        label.set_relief(Gtk.ReliefStyle.NONE);
        label.set_property("margin-left", 1);
        label.get_child().set_halign(Gtk.Align.START);
        grid.attach(label, 1, row, 1, 1);

        var end_session = new Gtk.Button.from_icon_name("system-shutdown-symbolic", Gtk.IconSize.BUTTON);
        end_session.clicked.connect(()=> {
            popover.hide();
            try {
                Process.spawn_command_line_async("budgie-session-dialog");
            } catch (Error e) {
                message("Error invoking end session dialog: %s", e.message);
            }
        });
        end_session.vexpand = true;
        end_session.set_relief(Gtk.ReliefStyle.NONE);
        grid.attach(end_session, 2, row, 1, 1);
        end_session.valign = Gtk.Align.END;
        end_session.halign = Gtk.Align.END;
    }

    protected void show_popover()
    {
        popover.set_size_request(200, 150);
        popover.present(this);
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(StatusApplet));
}

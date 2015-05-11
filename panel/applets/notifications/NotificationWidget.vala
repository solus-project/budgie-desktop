/*
 * NotificationWidget.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */


/**
 * Position of icon on the MixinImage
 */
public enum MixinImagePosition {
    MAIN, /**<Large image (main area) */
    SUB /**"Sub image" or overlay icon */
}

/**
 * Utility to handle simple lightweight composition of two
 * Gtk images, to enable the overlay of an app icon over say,
 * the album art, provided by a notification
 */
public class MixinImage : Gtk.Overlay
{
    Gtk.Image main;
    Gtk.Image? sub;

    public MixinImage()
    {
        main = new Gtk.Image();
        add(main);
    }

    /**
     * Set the image specified by pos using an icon name
     *
     * @param pos Which icon position to set
     * @param icon The new icon name
     */
    public void set_from_icon_name(MixinImagePosition pos, string icon)
    {
        if (pos == MixinImagePosition.MAIN) {
            main.set_from_icon_name(icon, Gtk.IconSize.DIALOG);
            main.pixel_size = 48;
            return;
        }
        if (sub == null) {
            sub = new Gtk.Image();
            add_overlay(sub);

            sub.halign = Gtk.Align.END;
            sub.valign = Gtk.Align.END;
            sub.margin_end = 1;
            sub.margin_bottom = 1;
        }
        sub.show_all();
        sub.set_from_icon_name(icon, Gtk.IconSize.MENU);
    }

    /**
     * Set the image specified by pos using a GdkPixbuf
     *
     * @param pos Which icon position to set
     * @param pbuf The new GdkPixbuf
     */
    public void set_from_pixbuf(MixinImagePosition pos, Gdk.Pixbuf pbuf)
    {
        if (pos == MixinImagePosition.MAIN) {
            main.set_from_pixbuf(pbuf);
            return;
        }
        sub.show_all();
        sub.set_from_pixbuf(pbuf);
    }

    /**
     * Hide the secondary (sub) image overlay
     */
    public void hide_secondary()
    {
        if (sub != null) {
            sub.hide();
        }
    }
}

/**
 * Gtk representation of a freedesktop notification
 *
 * Currently supports title, body, app_icon as well as image-path attributes.
 * If the notification requests, we can optionally support actions, as well
 * as rendering them as icons.
 *
 * @note Where possible the implementation will attempt to use the symbolic
 * icons in the theme for greater consistency.
 */
public class NotificationWidget : Gtk.Grid
{
    public uint32 id;

    MixinImage image;
    Gtk.Label title;
    Gtk.Label body;
    Gtk.ButtonBox abox;
    string app_icon;
    string? image_path = null;
    Gtk.Separator sep;

    private uint32 _timeout;
    private uint con_id;

    private NotificationServer nserver;

    /**
     * We manage our own lifecycle in terms of timeouts
     */
    public uint32 timeout {
        public set {
            this._timeout = value;
            if (this.con_id > 0) {
                Source.remove(this.con_id);
                this.con_id = 0;
            }
            this.con_id = Timeout.add(_timeout, ()=> { this.dismiss(); return false; });
        }
        public get {
            return _timeout;
        }
    }

    /**
     * Either we timed out or the user hit the close button
     */
    public signal void dismiss();

    private void update_actions(Notif notif)
    {
        if (notif.actions.length > 1) {
            sep.show_all();
        } else {
            sep.hide();
        }
        if (abox != null) {
            remove(abox);
        }
        if (notif.actions.length == 0) {
            return;
        }
        /* action box.. */
        abox = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
        for (int i = 0; i < notif.actions.length; i++) {
            var a = notif.actions[i];
            var local = notif.actions[++i];
            Gtk.Button btn;
            var icon = a;
            if (notif.icons) {
                var itheme = Gtk.IconTheme.get_default();
                if (itheme.has_icon(a + "-symbolic")) {
                    icon += "-symbolic";
                }
                btn = new Gtk.Button.from_icon_name(icon, Gtk.IconSize.MENU);
            } else {
                btn = new Gtk.Button.with_label(local);
            }
            btn.set_data("__nserverid", a);
            btn.clicked.connect(click_handler);
            btn.relief = Gtk.ReliefStyle.NONE;
            abox.add(btn);
        }
        abox.show_all();
        attach(abox, 1, 3, 1, 1);
    }

    private void update_icons(Notif notif)
    {
        if (notif.app_icon == "") {
            notif.app_icon = "dialog-information-symbolic";
        }

        /* May need to workaround Rhythmbox in future, which removes and sets the icon.. */
        if (notif.image_path != null) {
            try {
                var pbuf = new Gdk.Pixbuf.from_file_at_size(notif.image_path, 48, 48);
                image.set_from_pixbuf(MixinImagePosition.MAIN, pbuf);
            } catch (Error e) {
                message("Image not found: %s", notif.image_path);
                image.set_from_icon_name(MixinImagePosition.MAIN, "dialog-information-symbolic");
            }
            image.set_from_icon_name(MixinImagePosition.SUB, app_icon);
            this.image_path = notif.image_path;
        } else {
            image.set_from_icon_name(MixinImagePosition.MAIN, app_icon);
            image.show_all();
            image.hide_secondary();
            this.image_path = null;
        }
        this.app_icon = notif.app_icon;
    }

    public void update(Notif notif)
    {
        this.id = notif.id;

        title.set_markup("<big>%s</big>".printf(notif.summary.replace("&", "&amp;")));
        body.set_markup(notif.body.replace("&", "&amp;"));

        update_actions(notif);
        update_icons(notif);
    }

    /**
     * Trivial, we just emit the action that was selected..
     */
    private void click_handler(Gtk.Button button)
    {
        string id = button.get_data("__nserverid");
        nserver.action_invoked(this.id, id);
    }

    public NotificationWidget(NotificationServer nserver, Notif notif)
    {
        this.id = notif.id;
        this.app_icon = notif.app_icon;
        this.nserver = nserver;

        /* Allows overlay images */
        image = new MixinImage();
        image.valign = Gtk.Align.START;
        image.margin = 6;
        image.show_all();
        update_icons(notif);

        /* Summary */
        title = new Gtk.Label("<big>%s</big>".printf(notif.summary.replace("&", "&amp;")));
        title.get_style_context().add_class("notif-title");
        title.margin_top = 6;
        title.margin_end = 6;
        title.valign = Gtk.Align.START;
        title.use_markup = true;
        title.halign = Gtk.Align.START;
        title.set_line_wrap(true);

        /* Body */
        body = new Gtk.Label(notif.body.replace("&", "&amp;"));
        body.set_line_wrap_mode(Pango.WrapMode.CHAR);
        body.use_markup = true;
        body.margin_end = 6;
        body.margin_bottom = 6;
        body.valign = Gtk.Align.START;
        body.set_line_wrap(true);
        body.get_style_context().add_class("dim-label");
        body.halign = Gtk.Align.START;

        /* Simple dismiss button */
        var close = new Gtk.Button.from_icon_name("window-close-symbolic", Gtk.IconSize.MENU);
        close.relief = Gtk.ReliefStyle.NONE;
        close.hexpand = true;
        close.halign = Gtk.Align.END;
        close.get_style_context().add_class("image-button");
        close.set_can_focus(false);
        close.clicked.connect(()=> {
            this.dismiss();
        });

        column_spacing = 5;
        int col = 0;
        int row = 0;

        attach(image, col, row, 1, 2);
        attach(title, col+1, row, 1, 1);
        attach(close, col+2, row, 1, 1);
        attach(body, col+1, ++row, 1, 1);

        /* Only visible if actions are visible .. */
        sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        sep.hexpand = true;
        attach(sep, col+1, ++row, 2, 1);

        show_all();
        sep.no_show_all = true;
        update_actions(notif);
    }

    /**
     * We're big.
     */
    public override void get_preferred_width(out int min, out int max)
    {
        min = 400;
        max = 400;
    }
}

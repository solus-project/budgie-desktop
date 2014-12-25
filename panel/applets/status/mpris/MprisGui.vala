/*
 * MprisGui.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const int BACKGROUND_SIZE = 250;

/**
 * A fancier Gtk.Image, which forces a fade-effect across the bottom of the image
 * making it easier to use/see the overlayed playback controls within the ClientWidget
 */
public class ClientImage : Gtk.Image
{
    public ClientImage.from_pixbuf(Gdk.Pixbuf pbuf)
    {
        Object(pixbuf: pbuf);
    }

    public ClientImage.from_icon_name(string icon_name, Gtk.IconSize size)
    {
        Object(icon_name : icon_name, icon_size: size);
    }

    public override bool draw(Cairo.Context cr)
    {
        Gtk.Allocation alloc;
        get_allocation(out alloc);

        /* Render to new surface.. */
        var surf = new Cairo.ImageSurface(Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr2 = new Cairo.Context(surf);
        base.draw(cr2);

        var alpha = 1.0;
        /* Just makes sure we fade out the bottom part of the image where we overlay
         * controls. Inspiration: http://zetcode.com/gfx/pycairo/transparency/
         *
         * craqmonkies follow.
         */

        var start = (int)(alloc.height*0.40);
        var step = ((1.0 / (alloc.height-start)))*1.35;

        cr.rectangle(0, 0, alloc.width, start);
        cr.save();
        cr.clip();
        cr.set_source_surface(surf, 0, 0);
        cr.paint();
        cr.restore();

        for (int i = start; i < alloc.height; i++) {
            cr.rectangle(0, i, alloc.width, 1);
            cr.save();
            cr.clip();
            cr.set_source_surface(surf, 0, 0);
            cr.paint_with_alpha(alpha);
            cr.restore();

            alpha -= step;
        }

        return true;
    }
}

/**
 * A ClientWidget is simply used to control and display information in a two-way
 * fashion with an underlying MPRIS provider (MediaPlayer2)
 * It is "designed" to be self contained and added to a large UI, enabling multiple
 * MPRIS clients to be controlled with multiple widgets
 */
public class ClientWidget : Gtk.Box
{
    Gtk.Image background;
    MprisClient client;
    Gtk.Label title_label;
    Gtk.Label artist_label;
    Gtk.Label album_label;
    Gtk.Button prev_btn;
    Gtk.Button play_btn;
    Gtk.Button next_btn;

    /**
     * Create a new ClientWidget
     *
     * @param client The underlying MprisClient instance to use
     */
    public ClientWidget(MprisClient client)
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 3);

        this.client = client;


        Gtk.Widget? row = null;;
        string icon_name = "emblem-music-symbolic";

        if (client.player.desktop_entry != "") {
            var ainfo = new DesktopAppInfo(client.player.desktop_entry + ".desktop");
            if (ainfo != null) {
                var icon = ainfo.get_icon();
                row = create_row(ainfo.get_display_name(), null, icon);
            }
        }
        if (row == null) {
            row = create_row(client.player.identity, icon_name);
        }
        row.margin_bottom = 3;
        pack_start(row, false, false, 0);

        if (client.player.can_quit) {
            var qbtn = new Gtk.Button.from_icon_name("window-close-symbolic", Gtk.IconSize.MENU);
            qbtn.clicked.connect(()=> {
                Idle.add(()=>{
                    try {
                        client.player.quit();
                    } catch (Error e) {
                        warning("Could not quit player: %s", e.message);
                    }
                    return false;
                });
            });
            qbtn.set_relief(Gtk.ReliefStyle.NONE);
            (row as Gtk.Box).pack_end(qbtn, false, false, 0);
        }

        background = new ClientImage.from_icon_name("emblem-music-symbolic", Gtk.IconSize.INVALID);
        background.pixel_size = BACKGROUND_SIZE;

        var layout = new Gtk.Overlay();
        pack_start(layout, true, true, 0);

        layout.add(background);


        /* normal info */
        row = create_row("Unknown Artist", "user-info-symbolic");
        artist_label = row.get_data("label_item");
        pack_start(row, false, false, 0);
        row = create_row("Unknown Title", "emblem-music-symbolic");
        title_label = row.get_data("label_item");
        pack_start(row, false, false, 0);
        row = create_row("Unknown Album", "media-optical-symbolic");
        album_label = row.get_data("label_item");
        pack_start(row, false, false, 0);

        var controls = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        var btn = new Gtk.Button.from_icon_name("media-skip-backward-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        btn.set_sensitive(false);
        btn.set_can_focus(false);
        prev_btn = btn;
        btn.clicked.connect(()=> {
            Idle.add(()=> {
                if (client.player.can_go_previous) {
                    try { 
                        client.player.previous();
                    } catch (Error e) {
                        warning("Could not go to previous track: %s", e.message);
                    }
                }
                return false;
            });
        });
        btn.set_relief(Gtk.ReliefStyle.NONE);
        controls.pack_start(btn, false, false, 0);

        btn = new Gtk.Button.from_icon_name("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        play_btn = btn;
        btn.set_can_focus(false);
        btn.clicked.connect(()=> {
            Idle.add(()=> {
                try {
                    client.player.play_pause();
                } catch (Error e) {
                    warning("Could not play/pause: %s", e.message);
                }
                return false;
            });
        });
        btn.set_relief(Gtk.ReliefStyle.NONE);
        controls.pack_start(btn, false, false, 0);

        btn = new Gtk.Button.from_icon_name("media-skip-forward-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        btn.set_sensitive(false);
        btn.set_can_focus(false);
        next_btn = btn;
        btn.clicked.connect(()=> {
            Idle.add(()=> {
                if (client.player.can_go_next) {
                    try { 
                        client.player.next();
                    } catch (Error e) {
                        warning("Could not go to next track: %s", e.message);
                    }
                }
                return false;
            });
        });
        btn.set_relief(Gtk.ReliefStyle.NONE);
        controls.pack_start(btn, false, false, 0);

        controls.set_halign(Gtk.Align.CENTER);
        controls.set_valign(Gtk.Align.END);
        controls.margin_bottom = (int) (200*0.10);

        layout.add_overlay(controls);

        update_from_meta();
        update_play_status();
        update_controls();

        client.prop.properties_changed.connect((i,p,inv)=> {
            if (i == "org.mpris.MediaPlayer2.Player") {
                /* Handle mediaplayer2 iface */
                p.foreach((k,v)=> {
                    if (k == "Metadata") {
                        Idle.add(()=> {
                            update_from_meta();
                            return false;
                        });
                    } else if (k == "PlaybackStatus") {
                        Idle.add(()=> {
                            update_play_status();
                            return false;
                        });
                    } else if (k == "CanGoNext" || k == "CanGoPrevious") {
                        Idle.add(()=> {
                            update_controls();
                            return false;
                        });
                    }
                });
            }
        });
    }

    /**
     * Update play status based on player requirements
     */
    void update_play_status()
    {
        switch (client.player.playback_status) {
            case "Playing":
                (play_btn.get_image() as Gtk.Image).set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                break;
            default:
                /* Stopped, Paused */
                (play_btn.get_image() as Gtk.Image).set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                break;
        }
    }

    /**
     * Update prev/next sensitivity based on player requirements
     */
    void update_controls()
    {
        prev_btn.set_sensitive(client.player.can_go_previous);
        next_btn.set_sensitive(client.player.can_go_next);
    }

    /**
     * Utility, handle updating the album art
     */
    void update_art(string uri)
    {
        if (!uri.has_prefix("file://")) {
            background.set_from_icon_name("emblem-music-symbolic", Gtk.IconSize.INVALID);
            background.pixel_size = BACKGROUND_SIZE;
            return;
        }
        string fname = uri.split("file://")[1];
        try {
            var pbuf = new Gdk.Pixbuf.from_file_at_size(fname, BACKGROUND_SIZE, BACKGROUND_SIZE);
            background.set_from_pixbuf(pbuf);
        } catch (Error e) {
            background.set_from_icon_name("emblem-music-symbolic", Gtk.IconSize.INVALID);
            background.pixel_size = BACKGROUND_SIZE;
        }
    }

    /**
     * Update display info such as artist, the background image, etc.
     */
    protected void update_from_meta()
    {

        if ("mpris:artUrl" in client.player.metadata) {
            var url = client.player.metadata["mpris:artUrl"].get_string();
            update_art(url);
        } else {
            background.pixel_size = BACKGROUND_SIZE;
            background.set_from_icon_name("emblem-music-symbolic", Gtk.IconSize.INVALID);
        }

        if ("xesam:title" in client.player.metadata) {
            title_label.set_text(client.player.metadata["xesam:title"].get_string());
        } else {
            title_label.set_text("Unknown Title");
        }

        if ("xesam:artist" in client.player.metadata) {
            /* get_strv causes a segfault from multiple free's on vala's side. */
            string[] artists = client.player.metadata["xesam:artist"].dup_strv();
            artist_label.set_text(string.joinv(", ", artists));
        } else {
            artist_label.set_text("Unknown Artist");
        }

        if ("xesam:album" in client.player.metadata) {
            album_label.set_text(client.player.metadata["xesam:album"].get_string());
        } else {
            album_label.set_text("Unknown Album");
        }
    }
}

/**
 * Boring utility function, create an image/label row
 *
 * @param name Label to appear on row
 * @param icon Icon name to use, or NULL if using gicon
 * @param gicon A gicon to use, if not using icon
 *
 * @return A Gtk.Box with the boilerplate cruft out of the way
 */
public static Gtk.Widget create_row(string name, string? icon, Icon? gicon = null)
{
    var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    Gtk.Image img;

    if (icon == null && gicon != null) {
        img = new Gtk.Image.from_gicon(gicon, Gtk.IconSize.MENU);
    } else {
        img = new Gtk.Image.from_icon_name(icon, Gtk.IconSize.MENU);
    }

    img.margin_right = 8;
    img.margin_left = 3;
    box.pack_start(img, false, false, 0);
    var label = new Gtk.Label(name);
    label.halign = Gtk.Align.START;
    box.pack_start(label, true, true, 0);

    box.set_data("label_item", label);

    return box;
}

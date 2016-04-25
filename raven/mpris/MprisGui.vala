/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
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
}

/**
 * A ClientWidget is simply used to control and display information in a two-way
 * fashion with an underlying MPRIS provider (MediaPlayer2)
 * It is "designed" to be self contained and added to a large UI, enabling multiple
 * MPRIS clients to be controlled with multiple widgets
 */
public class ClientWidget : Gtk.Box
{
    Gtk.Revealer player_revealer;
    Gtk.Image background;
    MprisClient client;
    Gtk.Label title_label;
    Gtk.Label artist_label;
    Gtk.Label album_label;
    Gtk.Button prev_btn;
    Gtk.Button play_btn;
    Gtk.Button next_btn;
    string filename = "";

    int our_width = BACKGROUND_SIZE;

    public bool expanded {
        public set {
            this.player_revealer.set_reveal_child(value);
        }
        public get {
            return this.player_revealer.get_reveal_child();
        }
        default = true;
    }

    Budgie.HeaderWidget? header = null;

    /**
     * Create a new ClientWidget
     *
     * @param client The underlying MprisClient instance to use
     */
    public ClientWidget(MprisClient client, int width)
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
        Gtk.Widget? row = null;

        our_width = width;

        this.client = client;

        player_revealer = new Gtk.Revealer ();
        player_revealer.reveal_child = true;
        var player_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        get_style_context().add_class("raven-background");

        player_revealer.notify["child-revealed"].connect_after(()=> {
            this.get_toplevel().queue_draw();
        });
        header = new Budgie.HeaderWidget(client.player.identity, "media-playback-pause-symbolic", false);
        header.closed.connect(()=> {
            try {
                if (client.player.can_quit) {
                    client.player.quit.begin();
                }
            } catch (Error e) {
                warning("Error closing %s: %s", client.player.identity, e.message);
            }
        });
        pack_start(header, false, false, 0);

        header.bind_property("expanded", this, "expanded");
        header.can_close = client.player.can_quit;
        if (!header.can_close) {
            expanded = false;
        } else {
            expanded = true;
        }

        background = new ClientImage.from_icon_name("emblem-music-symbolic", Gtk.IconSize.INVALID);
        background.pixel_size = our_width;

        var layout = new Gtk.Overlay();
        player_box.pack_start(layout, true, true, 0);

        layout.add(background);

        /* normal info */
        var top_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        top_box.valign = Gtk.Align.END;
        top_box.get_style_context().add_class("raven-mpris");

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);
        box.margin = 6;
        box.margin_top =12;
        top_box.pack_start(box, true, true, 0);


        var controls = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        row = create_row("Unknown Artist", "user-info-symbolic");
        artist_label = row.get_data("label_item");
        box.pack_start(row, false, false, 0);
        row = create_row("Unknown Title", "emblem-music-symbolic");
        title_label = row.get_data("label_item");
        box.pack_start(row, false, false, 0);
        row = create_row("Unknown Album", "media-optical-symbolic");
        album_label = row.get_data("label_item");
        box.pack_start(row, false, false, 0);

        box.pack_start(controls, false, false, 0);


        var btn = new Gtk.Button.from_icon_name("media-skip-backward-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        btn.set_sensitive(false);
        btn.set_can_focus(false);
        prev_btn = btn;
        btn.clicked.connect(()=> {
            if (client.player.can_go_previous) {
                try { 
                    client.player.previous.begin();
                } catch (Error e) {
                    warning("Could not go to previous track: %s", e.message);
                }
            }
        });
        btn.get_style_context().add_class("flat");
        controls.pack_start(btn, false, false, 0);

        btn = new Gtk.Button.from_icon_name("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        play_btn = btn;
        btn.set_can_focus(false);
        btn.clicked.connect(()=> {
            try {
                client.player.play_pause.begin();
            } catch (Error e) {
                warning("Could not play/pause: %s", e.message);
            }
        });
        btn.get_style_context().add_class("flat");
        controls.pack_start(btn, false, false, 0);

        btn = new Gtk.Button.from_icon_name("media-skip-forward-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        btn.set_sensitive(false);
        btn.set_can_focus(false);
        next_btn = btn;
        btn.clicked.connect(()=> {
            if (client.player.can_go_next) {
                try { 
                    client.player.next.begin();
                } catch (Error e) {
                    warning("Could not go to next track: %s", e.message);
                }
            }
        });
        btn.get_style_context().add_class("flat");
        controls.pack_start(btn, false, false, 0);


        controls.set_halign(Gtk.Align.CENTER);
        controls.set_valign(Gtk.Align.END);
        layout.add_overlay(top_box);

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

        player_revealer.add(player_box);
        pack_start(player_revealer);

        this.expanded = true;
    }

    /**
     * Update play status based on player requirements
     */
    void update_play_status()
    {
        switch (client.player.playback_status) {
            case "Playing":
                header.icon_name = "media-playback-start-symbolic";
                header.text = "%s - Playing".printf(client.player.identity);
                (play_btn.get_image() as Gtk.Image).set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                break;
            case "Paused":
                header.icon_name = "media-playback-pause-symbolic";
                header.text = "%s - Paused".printf(client.player.identity);
                (play_btn.get_image() as Gtk.Image).set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                break;
            default:
                header.text = client.player.identity;
                header.icon_name = "media-playback-stop-symbolic";
                (play_btn.get_image() as Gtk.Image).set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
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
            background.pixel_size = this.our_width;
            return;
        }
        string fname = uri.split("file://")[1];
        try {
            this.filename = fname;
            var pbuf = new Gdk.Pixbuf.from_file_at_size(fname, this.our_width, this.our_width);
            background.set_from_pixbuf(pbuf);
        } catch (Error e) {
            background.set_from_icon_name("emblem-music-symbolic", Gtk.IconSize.INVALID);
            background.pixel_size = BACKGROUND_SIZE;
        }
    }

    /* Work around Spotify, etc */
    string? get_meta_string(string key, string fallback)
    {
        if (key in client.player.metadata) {
            var label = client.player.metadata[key];
            string? lab = null;
            unowned VariantType type = label.get_type();

            /* Simple string */
            if (type.is_subtype_of(VariantType.STRING)) {
                lab = label.get_string();
            /* string[] */
            } else if (type.is_subtype_of(VariantType.STRING_ARRAY)) {
                string[] vals = label.dup_strv();
                lab = string.joinv(", ", vals);
            }
            /* Return if set */
            if (lab != null && lab != "") {
                return lab;
            }
        }
        /* Fallback to sanity */
        return fallback;
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

        title_label.set_text(get_meta_string("xesam:title", "Unknown Title"));
        album_label.set_text(get_meta_string("xesam:album", "Unknown Album"));
        artist_label.set_text(get_meta_string("xesam:artist", "Unknown Artist"));
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

    img.margin_start = 8;
    img.margin_end = 8;
    box.pack_start(img, false, false, 0);
    var label = new Gtk.Label(name);
    label.set_line_wrap(true);
    label.set_line_wrap_mode(Pango.WrapMode.WORD);
    label.halign = Gtk.Align.START;
    /* I truly don't care that this is deprecated, it's the only way
     * to actually fix the alignment on line wrap. */
    label.set_alignment(0.0f, 0.5f);
    box.pack_start(label, true, true, 0);

    box.set_data("label_item", label);
    box.set_data("image_item", img);

    return box;
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

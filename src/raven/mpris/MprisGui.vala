/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
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
public class ClientImage : Gtk.Image {
	public ClientImage.from_pixbuf(Gdk.Pixbuf pbuf) {
		Object(pixbuf: pbuf);
	}

	public ClientImage.from_icon_name(string icon_name, Gtk.IconSize size) {
		Object(icon_name : icon_name, icon_size: size);
	}
}

/**
 * A ClientWidget is simply used to control and display information in a two-way
 * fashion with an underlying MPRIS provider (MediaPlayer2)
 * It is "designed" to be self contained and added to a large UI, enabling multiple
 * MPRIS clients to be controlled with multiple widgets
 */
public class ClientWidget : Gtk.Box {
	Budgie.RavenExpander player_revealer;
	Gtk.Image background;
	Gtk.EventBox background_wrap;
	MprisClient client;
	Gtk.Label title_label;
	Gtk.Label artist_label;
	Gtk.Label album_label;
	Gtk.Button prev_btn;
	Gtk.Button play_btn;
	Gtk.Button next_btn;
	string filename = "";
	Cancellable? cancel;

	int our_width = BACKGROUND_SIZE;

	Budgie.HeaderWidget? header = null;

	/**
	 * Create a new ClientWidget
	 *
	 * @param client The underlying MprisClient instance to use
	 */
	public ClientWidget(MprisClient client, int width) {
		Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
		Gtk.Widget? row = null;
		cancel = new Cancellable();

		our_width = width;

		this.client = client;

		/* Set up our header widget */
		header = new Budgie.HeaderWidget(client.player.identity, "media-playback-pause-symbolic", false);
		header.closed.connect(() => {
			if (client.player.can_quit) {
				client.player.quit.begin((obj, res) => {
					try {
						try {
							client.player.quit.end(res);
						} catch (IOError e) {
							warning("Error closing %s: %s", client.player.identity, e.message);
						}
					} catch (DBusError e) {
						warning("Error closing %s: %s", client.player.identity, e.message);
					}
				});
			}
		});

		player_revealer = new Budgie.RavenExpander(header);
		player_revealer.expanded = true;
		var player_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

		header.can_close = client.player.can_quit;

		background = new ClientImage.from_icon_name("emblem-music-symbolic", Gtk.IconSize.INVALID);
		background.pixel_size = our_width;
		background_wrap = new Gtk.EventBox();
		background_wrap.add(background);
		background_wrap.button_release_event.connect(this.on_raise_player);

		var layout = new Gtk.Overlay();
		player_box.pack_start(layout, true, true, 0);

		layout.add(background_wrap);

		/* normal info */
		var top_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		top_box.valign = Gtk.Align.END;
		top_box.get_style_context().add_class("raven-mpris");

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);
		box.margin = 6;
		box.margin_top = 12;
		top_box.pack_start(box, true, true, 0);


		var controls = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		controls.get_style_context().add_class("raven-mpris-controls");

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
		btn.clicked.connect(() => {
			if (client.player.can_go_previous) {
				client.player.previous.begin((obj, res) => {
					try {
						try {
							client.player.previous.end(res);
						} catch (IOError e) {
							warning("Error going to the previous track %s: %s", client.player.identity, e.message);
						}
					} catch (DBusError e) {
						warning("Error going to the previous track %s: %s", client.player.identity, e.message);
					}
				});
			}
		});
		btn.get_style_context().add_class("flat");
		controls.pack_start(btn, false, false, 0);

		btn = new Gtk.Button.from_icon_name("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		play_btn = btn;
		btn.set_can_focus(false);
		btn.clicked.connect(() => {
			client.player.play_pause.begin((obj, res) => {
				try {
					try {
						client.player.play_pause.end(res);
					} catch (IOError e) {
						warning("Error toggling play state %s: %s", client.player.identity, e.message);
					}
				} catch (DBusError e) {
					warning("Error toggling the play state %s: %s", client.player.identity, e.message);
				}
			});
		});
		btn.get_style_context().add_class("flat");
		controls.pack_start(btn, false, false, 0);

		btn = new Gtk.Button.from_icon_name("media-skip-forward-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		btn.set_sensitive(false);
		btn.set_can_focus(false);
		next_btn = btn;
		btn.clicked.connect(() => {
			if (client.player.can_go_next) {
				client.player.next.begin((obj, res) => {
					try {
						try {
							client.player.next.end(res);
						} catch (IOError e) {
							warning("Error going to the next track %s: %s", client.player.identity, e.message);
						}
					} catch (DBusError e) {
						warning("Error going to the next track %s: %s", client.player.identity, e.message);
					}
				});
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

		client.prop.properties_changed.connect((i, p, inv) => {
			if (i == "org.mpris.MediaPlayer2.Player") {
				/* Handle mediaplayer2 iface */
				p.foreach((k, v) => {
					if (k == "Metadata") {
						update_from_meta();
					} else if (k == "PlaybackStatus") {
						update_play_status();
					} else if (k == "CanGoNext" || k == "CanGoPrevious") {
						update_controls();
					}
				});
			}
		});

		player_box.get_style_context().add_class("raven-background");

		/**
		 * Custom Player Styling
		 * We do this against the parent box itself so styling includes the header
		 */
		if ((client.player.desktop_entry != null) && (client.player.desktop_entry != "")) { // If a desktop entry is set
			get_style_context().add_class(client.player.desktop_entry); // Add our desktop entry, such as "spotify" to player_box
		} else { // If no desktop entry is set, use identity
			get_style_context().add_class(client.player.identity.down()); // Lowercase identity
		}

		get_style_context().add_class("mpris-widget");

		player_revealer.add(player_box);
		pack_start(player_revealer);
	}

	public void update_width(int new_width) {
		this.our_width = new_width;
		// force the reload of the current art
		update_art(filename, true);
	}

	/**
	 * You raise me up ...
	 */
	private bool on_raise_player() {
		if (client == null || !client.player.can_raise) {
			return Gdk.EVENT_PROPAGATE;
		}

		client.player.raise.begin((obj, res) => {
			try {
				try {
					client.player.raise.end(res);
				} catch (IOError e) {
					warning("Error raising the client for %s: %s", client.player.identity, e.message);
				}
			} catch (DBusError e) {
				warning("Error raising the client for %s: %s", client.player.identity, e.message);
			}
		});

		return Gdk.EVENT_STOP;
	}

	/**
	 * Update play status based on player requirements
	 */
	void update_play_status() {
		switch (client.player.playback_status) {
			case "Playing":
				header.icon_name = "media-playback-start-symbolic";
				header.text = "%s - Playing".printf(client.player.identity);
				((Gtk.Image) play_btn.get_image()).set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
				break;
			case "Paused":
				header.icon_name = "media-playback-pause-symbolic";
				header.text = "%s - Paused".printf(client.player.identity);
				((Gtk.Image) play_btn.get_image()).set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
				break;
			default:
				header.text = client.player.identity;
				header.icon_name = "media-playback-stop-symbolic";
				((Gtk.Image) play_btn.get_image()).set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
				break;
		}
	}

	/**
	 * Update prev/next sensitivity based on player requirements
	 */
	void update_controls() {
		prev_btn.set_sensitive(client.player.can_go_previous);
		next_btn.set_sensitive(client.player.can_go_next);
	}

	/**
	 * Utility, handle updating the album art
	 */
	void update_art(string uri, bool force_reload = false) {
		// Only load the same art again if a force reload was requested
		if (uri == this.filename && !force_reload) {
			return;
		}

		if (uri.has_prefix("http")) {
			// Cancel the previous fetch if necessary
			if (!this.cancel.is_cancelled()) {
				this.cancel.cancel();
			}
			this.cancel.reset();

			download_art.begin(uri);
		} else if (uri.has_prefix("file://")) {
			// local
			string fname = uri.split("file://")[1];
			try {
				var pbuf = new Gdk.Pixbuf.from_file_at_size(fname, this.our_width, this.our_width);
				background.set_from_pixbuf(pbuf);
				get_style_context().remove_class("no-album-art");
			} catch (Error e) {
				update_art_fallback();
			}
		} else {
			update_art_fallback();
		}

		// record the current uri
		this.filename = uri;
	}

	void update_art_fallback() {
		get_style_context().add_class("no-album-art");
		background.set_from_icon_name("emblem-music-symbolic", Gtk.IconSize.INVALID);
		background.pixel_size = this.our_width;
	}

	/**
	 * Fetch the cover art asynchronously and set it as the background image
	 */
	async void download_art(string uri) {
		// Spotify broke album artwork for open.spotify.com around time of this commit
		var proper_uri = uri.replace("https://open.spotify.com/image/", "https://i.scdn.co/image/");

		try {
			// open the stream
			var art_file = File.new_for_uri(proper_uri);
			// download the art
			var ins = yield art_file.read_async(Priority.DEFAULT, cancel);
			Gdk.Pixbuf? pbuf = yield new Gdk.Pixbuf.from_stream_at_scale_async(ins,
				this.our_width, this.our_width, true, cancel);
			background.set_from_pixbuf(pbuf);
			get_style_context().remove_class("no-album-art");
		} catch (Error e) {
			update_art_fallback();
		}
	}

	/* Work around Spotify, etc */
	string? get_meta_string(string key, string fallback) {
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
	protected void update_from_meta() {
		if ("mpris:artUrl" in client.player.metadata) {
			var url = client.player.metadata["mpris:artUrl"].get_string();
			update_art(url);
		} else {
			update_art_fallback();
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
public static Gtk.Widget create_row(string name, string? icon, Icon? gicon = null) {
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

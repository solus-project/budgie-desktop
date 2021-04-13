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


public class NotificationClone : Gtk.Box {
	public uint? id = null;
	private Gtk.Box? header = null;
	private Gtk.Button? dismiss_button = null;
	private Gtk.Label? label_title = null;
	private Gtk.Label? label_body = null;
	private Gtk.Label? label_timestamp = null;
	public signal void closed_individually();

	public NotificationClone(Budgie.NotificationWindow? target) {
		Object(orientation: Gtk.Orientation.VERTICAL, spacing: 10);
		get_style_context().add_class("notification-clone");

		id = target.id;
		expand = false;
		margin_bottom = 5;
		header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0); // Create our Notification header

		dismiss_button = new Gtk.Button.from_icon_name("window-close-symbolic", Gtk.IconSize.MENU);
		dismiss_button.get_style_context().add_class("flat");
		dismiss_button.get_style_context().add_class("image-button");

		label_title = new Gtk.Label("");
		label_title.set_markup(Budgie.safe_markup_string(target.title));
		label_title.ellipsize = Pango.EllipsizeMode.END;
		label_title.halign = Gtk.Align.START;
		label_title.justify = Gtk.Justification.LEFT;

		if (target.body != "") { // If there is body content
			label_body = new Gtk.Label("");
			label_body.halign = Gtk.Align.START;
			label_body.justify = Gtk.Justification.LEFT;
			label_body.set_markup(Budgie.safe_markup_string(target.body));
			label_body.width_chars = 30;
			label_body.wrap = true;
			label_body.wrap_mode = Pango.WrapMode.WORD_CHAR;
			label_body.xalign = 0;
		}

		var date = new DateTime.from_unix_local(target.timestamp);

		var gnome_settings = new Settings("org.gnome.desktop.interface");
		string clock_format = gnome_settings.get_string("clock-format");
		clock_format = (clock_format == "12h") ? date.format("%l:%M %p") : date.format("%H:%M");

		label_timestamp = new Gtk.Label(clock_format);
		label_timestamp.get_style_context().add_class("dim-label"); // Dim the label
		label_timestamp.halign = Gtk.Align.START;
		label_timestamp.justify = Gtk.Justification.LEFT;

		/**
		 * Start propagating our Notification box
		 */
		header.pack_start(label_title, false, false, 0); // Expand the label
		header.pack_end(dismiss_button, false, false, 0);

		pack_start(header); // Add our header
		pack_end(label_timestamp);

		if (label_body != null) {
			pack_end(label_body);
		}

		dismiss_button.clicked.connect(Dismiss);
	}

	/**
	 * Dismiss this notification
	 */
	public void Dismiss() {
		closed_individually(); // Trigger our signal so Raven NotificationsView knows
	}
}

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

namespace Budgie {
	/**
	 * NotificationGroup is a group of notifications.
	 */
	public class NotificationGroup : Gtk.Box {
		public int? count = 0;
		private HashTable<uint,NotificationClone>? notifications = null;
		private Gtk.ListBox? list = null;
		private Gtk.Box? header = null;
		private Gtk.Image? app_image = null;
		private Gtk.Label? app_label = null;
		private string? app_name;
		private Gtk.Button? dismiss_button = null;

		/**
		 * Signals
		 */
		public signal void dismissed_group(string app_name);
		public signal void dismissed_notification(uint id);

		public NotificationGroup(string c_app_icon, string c_app_name) {
			Object(orientation: Gtk.Orientation.VERTICAL, spacing: 10);
			can_focus = false; // Disable focus to prevent scroll on click
			focus_on_click = false;

			get_style_context().add_class("raven-notifications-group");

			// Intentially omit _end because it messes with alignment of dismiss buttons
			margin_start = 5;
			margin_top = 5;
			margin_bottom = 5;

			app_name = c_app_name;

			if (("budgie" in c_app_name) && ("caffeine" in c_app_icon)) { // Caffeine Notification
				app_name = _("Caffeine Mode");
			}

			notifications = new HashTable<uint,NotificationClone>(direct_hash, direct_equal);
			list = new Gtk.ListBox();
			list.can_focus = false; // Disable focus to prevent scroll on click
			list.focus_on_click = false;
			list.set_selection_mode(Gtk.SelectionMode.NONE);

			/**
			 * Header creation
			 */
			header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0); // Create our Notification header
			header.get_style_context().add_class("raven-notifications-group-header");

			app_image = new Gtk.Image.from_icon_name(c_app_icon, Gtk.IconSize.DND);
			app_image.halign = Gtk.Align.START;
			app_image.margin_end = 5;
			app_image.set_pixel_size(32); // Really ensure it's 32x32

			app_label = new Gtk.Label(app_name);
			app_label.ellipsize = Pango.EllipsizeMode.END;
			app_label.halign = Gtk.Align.START;
			app_label.justify = Gtk.Justification.LEFT;
			app_label.use_markup = true;

			dismiss_button = new Gtk.Button.from_icon_name("list-remove-all-symbolic", Gtk.IconSize.MENU);
			dismiss_button.get_style_context().add_class("flat");
			dismiss_button.get_style_context().add_class("image-button");
			dismiss_button.halign = Gtk.Align.END;

			dismiss_button.clicked.connect(dismiss_all);

			header.pack_start(app_image, false, false, 0);
			header.pack_start(app_label, false, false, 0);
			header.pack_end(dismiss_button, false, false, 0);

			pack_start(header);
			pack_start(list);
		}

		/**
		 * add_notification is responsible for adding a notification (if it doesn't exist) and updating our counter
		 */
		public void add_notification(uint id, NotificationClone notification) {
			if (notification == null) {
				return;
			}

			if (notifications.contains(id)) { // If this id already exists
				remove_notification(id); // Remove the current one first
			}

			notifications.insert(id, notification);
			list.prepend(notification); // Most recent should be at the top
			update_count();

			notification.closed_individually.connect(() => { // When this notification is closed
				uint n_id = (uint) notification.id;
				remove_notification(n_id);
				dismissed_notification(n_id);
			});
		}

		/**
		 * dismiss_all is responsible for dismissing all notifications
		 */
		public void dismiss_all() {
			notifications.foreach((id, notification) => { // For reach notification
				remove_notification(id); // Remove this notification
			});

			notifications.steal_all();
			update_count();
			dismissed_group(app_name);
		}

		/**
		 * remove_notification is responsible for removing a notification (if it exists) and updating our counter
		 */
		public void remove_notification(uint id) {
			var notification = notifications.lookup(id); // Get our notification

			if (notification != null) { // If this notification exists
				notifications.steal(id);
				list.remove(notification.get_parent());
				notification.destroy(); // Nuke the notification
				update_count(); // Update our counter
				dismissed_notification(id); // Notify anything listening

				if (count == 0) { // This was the last notification
					dismissed_group(app_name); // Dismiss the group
				}
			}
		}

		/**
		 * update_count updates our notifications count for this group
		 */
		public void update_count() {
			count = (int) notifications.length;
			app_label.set_markup("<b>%s (%i)</b>".printf(app_name, count));
		}
	}
}

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
	/* Currently unused by us */
	[DBus (name="org.gnome.SessionManager.Inhibitor")]
	public interface Inhibitor : GLib.Object {
		public abstract string GetAppId() throws Error;
		public abstract string GetReason() throws Error;
	}

	public enum DialogType {
		LOGOUT = 0,
		SHUTDOWN = 1,
		RESTART = 2,
		UPDATE_RESTART = 3
	}

	[GtkTemplate (ui="/com/solus-project/budgie/endsession/endsession.ui")]
	[DBus (name="org.budgie_desktop.Session.EndSessionDialog")]
	public class EndSessionDialog : Gtk.Window {
		public signal void ConfirmedLogout();
		public signal void ConfirmedReboot();
		public signal void ConfirmedShutdown();
		public signal void Canceled();
		public signal void Closed();
		public signal void Opened();

		[GtkChild]
		private Gtk.Button? button_cancel;

		[GtkChild]
		private Gtk.Button? button_logout;

		[GtkChild]
		private Gtk.Button? button_restart;

		[GtkChild]
		private Gtk.Button? button_shutdown;

		[GtkChild]
		private Gtk.Label? label_end_title;

		[GtkCallback]
		[DBus (visible=false)]
		void cancel_clicked() {
			Canceled();
			Closed();
			hide();
		}

		[GtkCallback]
		[DBus (visible=false)]
		void logout_clicked() {
			Closed();
			ConfirmedLogout();
		}

		[GtkCallback]
		[DBus (visible=false)]
		void restart_clicked() {
			Closed();
			ConfirmedReboot();
		}

		[GtkCallback]
		[DBus (visible=false)]
		void shutdown_clicked() {
			Closed();
			ConfirmedShutdown();
		}

		[DBus (visible=false)]
		void on_bus_acquired(DBusConnection conn) {
			try {
				conn.register_object("/org/budgie_desktop/Session/EndSessionDialog", this);
			} catch (Error e) {
				warning("Cannot register EndSessionDialog");
			}
			Budgie.setup = true;
		}

		/**
		* Attempt to set the RGBA visual
		*/
		[DBus (visible=false)]
		private void on_realized() {
			Gdk.Visual? visual = screen.get_rgba_visual();
			if (visual != null) {
				this.set_visual(visual);
			}
		}

		/**
		* Update the RGBA visual if its available when compositing changes
		* This is required as we may be constructed before the window manager
		* springs into life
		*/
		[DBus (visible=false)]
		private void on_composite_changed() {
			Gdk.Visual? visual = screen.get_rgba_visual();
			if (visual != null) {
				this.set_visual(visual);
			} else {
				this.set_visual(screen.get_system_visual());
			}
		}

		[DBus (visible=false)]
		public EndSessionDialog(bool replace) {
			var flags = BusNameOwnerFlags.ALLOW_REPLACEMENT;
			if (replace) {
				flags |= BusNameOwnerFlags.REPLACE;
			}
			Bus.own_name(BusType.SESSION, "org.budgie_desktop.Session.EndSessionDialog", flags,
				on_bus_acquired, () => {}, Budgie.DaemonNameLost);
			set_keep_above(true);
			set_resizable(false);

			realize.connect(on_realized);
			screen.composited_changed.connect(on_composite_changed);

			var header = new Gtk.EventBox();
			set_titlebar(header);
			header.get_style_context().remove_class("titlebar");

			delete_event.connect(() => {
				this.cancel_clicked();
				return Gdk.EVENT_STOP;
			});
		}

		public void Open(uint type, uint timestamp, uint open_length, ObjectPath[] inhibiters) throws DBusError, IOError {
			Opened(); // Indicate that we've opened the EndSession dialog
			/* Right now we ignore type, time and inhibitors. Shush */
			unowned Gtk.Widget? main_show = null;

			Gtk.Widget? all_widgets[] = {
				this.button_logout,
				this.button_restart,
				this.button_shutdown
			};

			string? title = null;

			switch (type) {
				case DialogType.LOGOUT:
					main_show = this.button_logout;
					title = _("Log out");
					break;
				case DialogType.RESTART:
				case DialogType.UPDATE_RESTART:
					title = _("Restart device");
					main_show = this.button_restart;
					break;
				case DialogType.SHUTDOWN:
					main_show = this.button_shutdown;
					break;
				default:
					main_show = null;
					break;
			}

			if (title == null) {
				title = _("Power Off");
			}

			/* Update the label */
			this.label_end_title.set_text(title);

			if (main_show != null) {
				/* We have a specific type.. */
				for (int i = 0; i < all_widgets.length; i++) {
					unowned Gtk.Widget? w = all_widgets[i];
					if (main_show == w) {
						continue;
					}
					w.hide();
				}
				main_show.show();
				((Gtk.Bin) main_show).get_child().show();
			} else {
				for (int i = 0; i < all_widgets.length; i++) {
					unowned Gtk.Widget? w = all_widgets[i];
					w.show();
					((Gtk.Bin) w).get_child().show();
				}
			}

			if (!get_realized()) {
				realize();
			}

			this.present();

			unowned Gdk.Window? win = get_window();
			if (win != null) {
				Gdk.Display? display = screen.get_display();

				if (display is Gdk.X11.Display) {
					win.focus(((Gdk.X11.Display) display).get_user_time());
				} else {
					win.focus(Gtk.get_current_event_time());
				}
			}
		}

		public void Close() throws DBusError, IOError {
			hide();
			Closed();
		}
	}
}

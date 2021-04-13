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

public class NotificationsPlugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new NotificationsApplet();
	}
}

private const string ALERT_SYMBOLIC = "notification-alert-symbolic";
private const string DND_SYMBOLIC = "notification-disabled-symbolic";
public const string RAVEN_DBUS_NAME = "org.budgie_desktop.Raven";
public const string RAVEN_DBUS_OBJECT_PATH = "/org/budgie_desktop/Raven";

[DBus (name="org.budgie_desktop.Raven")]
public interface RavenRemote : GLib.Object {
	public signal void DoNotDisturbChanged(bool active);
	public abstract async bool GetDoNotDisturbState() throws Error;
	public abstract async void ToggleNotificationsView() throws Error;
	public signal void NotificationsChanged();
	public abstract async uint GetNotificationCount() throws Error;
	public signal void UnreadNotifications();
	public signal void ReadNotifications();
}

public class NotificationsApplet : Budgie.Applet {
	Gtk.EventBox? widget;
	Gtk.Image? icon;
	Gdk.Pixbuf? dnd_pixbuf = null;
	RavenRemote? raven_proxy = null;

	public NotificationsApplet() {
		widget = new Gtk.EventBox();
		add(widget);

		icon = new Gtk.Image.from_icon_name(ALERT_SYMBOLIC, Gtk.IconSize.MENU);
		widget.add(icon);

		icon.halign = Gtk.Align.CENTER;
		icon.valign = Gtk.Align.CENTER;

		Bus.get_proxy.begin<RavenRemote>(BusType.SESSION, RAVEN_DBUS_NAME, RAVEN_DBUS_OBJECT_PATH, 0, null, on_raven_get);

		widget.button_release_event.connect(on_button_release);

		try {
			Gtk.IconTheme current_theme = Gtk.IconTheme.get_default();

			if ((current_theme != null) && current_theme.has_icon(DND_SYMBOLIC)) {
				dnd_pixbuf = current_theme.load_icon(DND_SYMBOLIC, 16, Gtk.IconLookupFlags.FORCE_SIZE); // Intentional scale down below normal
				dnd_pixbuf = dnd_pixbuf.scale_simple(14, 14, Gdk.InterpType.BILINEAR);
			}
		} catch (Error e) {
			warning("Failed to generate our DND pixbuf: %s", e.message);
		}

		show_all();
	}

	/* Hold onto our Raven proxy ref */
	void on_raven_get(Object? o, AsyncResult? res) {
		try {
			raven_proxy = Bus.get_proxy.end(res);
			raven_proxy.DoNotDisturbChanged.connect(on_dnd_changed);
			raven_proxy.NotificationsChanged.connect(on_notifications_changed);
			raven_proxy.UnreadNotifications.connect(on_notifications_unread);
			raven_proxy.ReadNotifications.connect(on_notifications_read);
			raven_proxy.GetNotificationCount.begin(on_get_count);
			raven_proxy.GetDoNotDisturbState.begin(on_get_dnd_state);
		} catch (Error e) {
			warning("Failed to gain Raven proxy: %s", e.message);
		}
	}

	void on_dnd_changed(bool active) {
		set_dnd_state(active);
	}

	void on_notifications_read() {
		this.icon.get_style_context().remove_class("alert");
	}

	void on_notifications_unread() {
		this.icon.get_style_context().add_class("alert");
	}

	void on_get_count(Object? o, AsyncResult? res) {
		uint count = 0;

		try {
			count = raven_proxy.GetNotificationCount.end(res);
		} catch (Error e) {
			warning("Error getting notifications: %s", e.message);
			return;
		}

		if (count > 1) {
			this.icon.set_tooltip_text(_("%u unread notifications").printf(count));
		} else if (count == 1) {
			this.icon.set_tooltip_text(_("1 unread notification"));
		} else {
			this.icon.set_tooltip_text(_("No unread notifications"));
		}
	}

	void on_get_dnd_state(Object? o, AsyncResult? res) {
		bool active = true; // Default to true

		try {
			active = raven_proxy.GetDoNotDisturbState.end(res);
		} catch (Error e) {
			warning("Failed to get Do Not Disturb state: %s", e.message);
			return;
		}

		set_dnd_state(active); // Set the DND state
	}

	void set_dnd_state(bool enabled) {
		if (enabled) { // DND enabled
			if (dnd_pixbuf != null) { // We have a pixbuf
				this.icon.set_from_pixbuf(dnd_pixbuf);
			} else { // Fallback to just an icon
				this.icon.set_from_icon_name(DND_SYMBOLIC, Gtk.IconSize.MENU);
			}
		} else { // DND not enabled
			this.icon.set_from_icon_name(ALERT_SYMBOLIC, Gtk.IconSize.MENU);
		}
	}

	void on_notifications_changed() {
		raven_proxy.GetNotificationCount.begin(on_get_count);
	}

	bool on_button_release(Gdk.EventButton? button) {
		if (raven_proxy == null) {
			return Gdk.EVENT_PROPAGATE;
		}

		if (button.button != 1) {
			return Gdk.EVENT_PROPAGATE;
		}

		try {
			raven_proxy.ToggleNotificationsView.begin();
		} catch (Error e) {
			message("Failed to toggle Raven: %s", e.message);
		}

		return Gdk.EVENT_STOP;
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(NotificationsPlugin));
}

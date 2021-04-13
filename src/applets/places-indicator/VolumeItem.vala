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

public class VolumeItem : ListItem {
	private MountHelper operation;
	private Gtk.Revealer? unlock_revealer = null;
	private Volume volume;
	private bool first_try = true;

	public VolumeItem(Volume volume) {
		item_class = volume.get_identifier("class");
		this.volume = volume;

		switch (item_class) {
			case "device":
				if (volume.can_eject()) {
					category_name = _("Removable devices");
				} else {
					category_name = _("Local volumes");
				}
				break;
			case "network":
				category_name = _("Network folders");
				break;
			case null:
				category_name = _("Other");
				break;
			default:
				break;
		}

		set_button(volume.get_name(), get_icon(volume.get_symbolic_icon()), true, volume.can_eject());
		name_button.set_tooltip_text(_("Mount and open \"%s\"").printf(volume.get_name()));

		operation = new MountHelper();

		operation.send_message.connect((message) => { send_message(message); });
		operation.password_asked.connect(on_password_asked);
		operation.request_mount.connect(do_mount);

		if (volume.can_eject()) {
			Gtk.Button eject_button = new Gtk.Button.from_icon_name("media-eject-symbolic", Gtk.IconSize.MENU);
			eject_button.get_style_context().add_class("unmount-button");
			eject_button.set_relief(Gtk.ReliefStyle.NONE);
			eject_button.set_can_focus(false);
			eject_button.set_halign(Gtk.Align.END);
			eject_button.set_tooltip_text(_("Eject"));
			overlay.add_overlay(eject_button);

			eject_button.clicked.connect(on_eject_button_clicked);
		}

		name_button.clicked.connect(on_name_button_clicked);
	}

	private void on_eject_button_clicked() {
		volume.eject_with_operation.begin(MountUnmountFlags.NONE, operation, null, on_eject);
	}

	private void on_name_button_clicked() {
		if (unlock_revealer == null) {
			do_mount();
		} else {
			if (!unlock_revealer.get_child_revealed()) {
				send_message(_("Enter the encryption passphrase to unlock this volume"));
			}
			unlock_revealer.set_reveal_child(!unlock_revealer.get_child_revealed());
			operation.get_password_entry().grab_focus();
		}
	}

	private void on_eject(Object? obj, AsyncResult res) {
		try {
			volume.eject_with_operation.end(res);
			string safe_remove = _("You can now safely remove");
			string device_name = volume.get_drive().get_name();
			send_message(@"$safe_remove \"$device_name\"");
		} catch (Error e) {
			send_message(e.message);
			warning(e.message);
		}
	}

	private void on_password_asked() {
		if (unlock_revealer == null) {
			unlock_revealer = operation.get_encryption_form();
			this.pack_start(unlock_revealer, true, true, 0);
		}
		unlock_revealer.set_reveal_child(true);
		operation.get_password_entry().grab_focus();
	}

	private void do_mount() {
		spin.start();
		volume.mount.begin(MountMountFlags.NONE, operation, null, on_mount);
	}

	private void on_mount(Object? obj, AsyncResult res) {
		try {
			volume.mount.end(res);
			open_directory(volume.get_mount().get_root());
		} catch (Error e) {
			if ("No key available with this passphrase" in e.message) {
				send_message(_("The password you entered is incorrect"));
			} else if (first_try && unlock_revealer != null) {
				send_message(_("Enter the encryption passphrase to unlock this volume"));
			} else {
				send_message(_("An unknown error occurred while attempting to mount this volume"));
			}
			message(e.message);
		}
		spin.stop();
		if (unlock_revealer != null) {
			unlock_revealer.set_sensitive(true);
			operation.get_password_entry().grab_focus();
		}
		first_try = false;
	}

	public override void cancel_operation() {
		if (unlock_revealer == null) {
			return;
		}

		Gtk.Entry entry = operation.get_password_entry();
		entry.set_text("");
		unlock_revealer.set_transition_type(Gtk.RevealerTransitionType.NONE);
		unlock_revealer.set_reveal_child(false);
		unlock_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
	}
}

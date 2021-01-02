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

public class MountItem : ListItem {
	private MountHelper operation;
	private Mount mount;

	public MountItem(Mount mount, string? class) {
		item_class = class;
		this.mount = mount;

		switch (item_class) {
			case "device":
				if (mount.can_eject()) {
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

		set_button(mount.get_name(), get_icon(mount.get_symbolic_icon()));

		operation = new MountHelper();

		Gtk.Button unmount_button = new Gtk.Button.from_icon_name("media-eject-symbolic", Gtk.IconSize.MENU);
		unmount_button.get_style_context().add_class("unmount-button");
		unmount_button.set_relief(Gtk.ReliefStyle.NONE);
		unmount_button.set_can_focus(false);
		unmount_button.set_halign(Gtk.Align.END);
		overlay.add_overlay(unmount_button);

		unmount_button.clicked.connect(() => {
			if (mount.can_eject()) {
				do_eject();
			} else {
				do_unmount();
			}
		});

		if (mount.can_eject()) {
			unmount_button.set_tooltip_text(_("Eject"));
		} else {
			unmount_button.set_tooltip_text(_("Unmount"));
		}

		name_button.set_tooltip_text(_("Open \"%s\"").printf(mount.get_name()));

		name_button.clicked.connect(() => {
			open_directory(mount.get_root());
		});
	}

	/*
	 * Ejects a mount
	 */
	private void do_eject() {
		mount.eject_with_operation.begin(MountUnmountFlags.NONE, operation, null, on_eject);
		string safe_remove = _("You can now safely remove");
		string device_name = mount.get_drive().get_name() ?? _("Unknown Device");
		send_message(@"$safe_remove \"$device_name\"");
	}

	private void on_eject(Object? obj, AsyncResult res) {
		try {
			mount.eject_with_operation.end(res);
		} catch (Error e) {
			send_message(_("Error while ejecting device"));
			warning(e.message);
		}
	}

	/*
	 * Unmounts a mount
	 */
	private void do_unmount() {
		mount.unmount_with_operation.begin(MountUnmountFlags.NONE, operation, null, on_unmount);
	}

	private void on_unmount(Object? obj, AsyncResult res) {
		try {
			mount.unmount_with_operation.end(res);
		} catch (Error e) {
			send_message(_("Error while unmounting volume"));
			warning(e.message);
		}
	}
}

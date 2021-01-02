/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {
	/**
	* RemovePanelDialog is used to confirm whether the panel should *really* be
	* removed
	*/
	public class RemovePanelDialog : Gtk.Dialog {
		Gtk.Label confirm_label;
		Gtk.Image confirm_image;

		public RemovePanelDialog(Gtk.Window parent) {
			Object(use_header_bar: 1,
				transient_for: parent,
				title: _("Confirm panel removal"),
				modal: true);

			unowned Gtk.Box? content = this.get_content_area() as Gtk.Box;

			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			confirm_image = new Gtk.Image.from_icon_name("edit-delete-symbolic", Gtk.IconSize.DIALOG);
			confirm_label = new Gtk.Label(_("Do you really want to remove this panel? This action cannot be undone."));
			confirm_label.set_line_wrap_mode(Pango.WrapMode.WORD);
			confirm_label.set_line_wrap(true);
			box.pack_start(confirm_image, false, false, 0);
			confirm_image.margin_end = 12;
			box.pack_start(confirm_label, false, false, 0);

			content.pack_start(box, false, false, 0);
			content.margin = 12;
			content.show_all();

			this.add_button(_("Remove panel"), Gtk.ResponseType.ACCEPT).get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
			this.add_button(_("Keep panel"), Gtk.ResponseType.CANCEL).get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		}

		/**
		* Simple wrapper to ensure dialog always does the right thing
		*/
		public new bool run() {
			return base.run() == Gtk.ResponseType.ACCEPT;
		}
	}

	/**
	* RemovePanelDialog is used to confirm whether the panel should *really* be
	* removed
	*/
	public class RemoveAppletDialog : Gtk.Dialog {
		Settings settings;
		Gtk.CheckButton check_confirm;
		Gtk.Label confirm_label;
		Gtk.Image confirm_image;

		public RemoveAppletDialog(Gtk.Window parent) {
			Object(use_header_bar: 1,
				transient_for: parent,
				title: _("Confirm applet removal"),
				modal: true);

			unowned Gtk.Box? content = this.get_content_area() as Gtk.Box;

			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			confirm_image = new Gtk.Image.from_icon_name("edit-delete-symbolic", Gtk.IconSize.DIALOG);
			confirm_label = new Gtk.Label(_("Do you really want to remove this applet? This action cannot be undone."));
			confirm_label.set_line_wrap_mode(Pango.WrapMode.WORD);
			confirm_label.set_line_wrap(true);
			box.pack_start(confirm_image, false, false, 0);
			confirm_image.margin_end = 12;
			box.pack_start(confirm_label, false, false, 0);

			content.pack_start(box, false, false, 0);
			content.margin = 12;

			var sep = new Gtk.Separator(Gtk.Orientation.VERTICAL);
			sep.margin_top = 6;
			sep.margin_bottom = 6;
			content.pack_start(sep, false, false, 0);

			check_confirm = new Gtk.CheckButton.with_label(_("Don't ask me again"));
			check_confirm.halign = Gtk.Align.START;
			settings = new Settings("com.solus-project.budgie-panel");
			settings.bind("confirm-remove-applet", check_confirm, "active", SettingsBindFlags.DEFAULT|SettingsBindFlags.INVERT_BOOLEAN);

			check_confirm.margin_bottom = 6;
			content.pack_end(check_confirm, false, false, 0);
			content.show_all();

			this.add_button(_("Remove applet"), Gtk.ResponseType.ACCEPT).get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
			this.add_button(_("Keep applet"), Gtk.ResponseType.CANCEL).get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		}

		/**
		* Simple wrapper to ensure dialog always does the right thing
		*/
		public new bool run() {
			if (!this.settings.get_boolean("confirm-remove-applet")) {
				return true;
			}
			return base.run() == Gtk.ResponseType.ACCEPT;
		}
	}
}

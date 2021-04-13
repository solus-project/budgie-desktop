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

public class MountHelper : MountOperation {
	private Gtk.Revealer revealer;
	private Gtk.Entry password_entry;
	private Gtk.Button unlock_button;

	public signal void send_message(string message);
	public signal void password_asked();
	public signal void request_mount();

	public MountHelper() {
		this.set_password_save(PasswordSave.FOR_SESSION);

		this.ask_password.connect(handle_password);
		this.show_processes.connect(handle_block);
		this.aborted.connect(handle_aborted);
	}

	private void handle_password(string message, string default_user, string default_domain, AskPasswordFlags flags) {
		password_asked();
		this.reply(MountOperationResult.HANDLED);
	}

	private void handle_block() {
		send_message(_("Volume is in use by other processes"));
		this.reply(MountOperationResult.HANDLED);
	}

	private void handle_aborted() {
		send_message(_("Operation aborted"));
		this.reply(MountOperationResult.HANDLED);
	}

	public Gtk.Revealer get_encryption_form() {
		revealer = new Gtk.Revealer();

		Gtk.Box unlock_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		unlock_box.get_style_context().add_class("unlock-area");
		revealer.add(unlock_box);
		password_entry = new Gtk.Entry();
		password_entry.set_placeholder_text(_("Type your password"));
		password_entry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		password_entry.set_visibility(false);
		unlock_box.pack_start(password_entry, true, true, 0);
		unlock_button = new Gtk.Button.from_icon_name("changes-allow-symbolic", Gtk.IconSize.MENU);
		unlock_button.set_sensitive(false);
		unlock_box.pack_end(unlock_button, false, false, 0);

		revealer.show_all();

		password_entry.changed.connect(on_entry_changed);

		password_entry.activate.connect(do_unlock);
		unlock_button.clicked.connect(do_unlock);

		return revealer;
	}

	private void on_entry_changed() {
		unlock_button.set_sensitive(password_entry.get_text().length > 0);
	}

	private void do_unlock() {
		if (password_entry.get_text() == "") {
			return;
		}

		revealer.set_sensitive(false);
		this.set_password(password_entry.get_text());
		request_mount();
	}

	public Gtk.Entry get_password_entry() {
		return password_entry;
	}
}

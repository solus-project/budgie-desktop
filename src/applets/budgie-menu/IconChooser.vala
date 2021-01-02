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

/**
 * IconChooser is a simple GtkFileChooserDialog wrapper. We tried simple
 * icon selection with IconView + TreeView, and whatever way you do it,
 * it's a complete CPU grinder.
 */
public class IconChooser : Gtk.FileChooserDialog {
	/**
	 * Construct a new modal IconChooser with the given parent
	 */
	public IconChooser(Gtk.Window parent) {
		Object(transient_for: parent,
			   use_header_bar: 1,
			   title: _("Set menu icon from file"),
			   action: Gtk.FileChooserAction.OPEN,
			   modal: true);

		this.set_select_multiple(false);
		this.set_show_hidden(false);

		/* We need gdk-pixbuf usable files */
		Gtk.FileFilter filter = new Gtk.FileFilter();
		filter.add_pixbuf_formats();
		filter.set_name(_("Image files"));
		this.add_filter(filter);

		/* Also need an Any filter to be a human about it */
		filter = new Gtk.FileFilter();
		filter.add_pattern("*");
		filter.set_name(_("Any file"));
		this.add_filter(filter);

		/* i.e. don't allow weird selections like Google Drive in gvfs and make Budgie hang */
		this.set_local_only(true);

		/* Prefer the users XDG pictures directory by default */
		string? picture_dir = Environment.get_user_special_dir(UserDirectory.PICTURES);
		if (picture_dir != null) {
			this.set_current_folder(picture_dir);
		}

		add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
		add_button(_("Set icon"), Gtk.ResponseType.ACCEPT).get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
	}

	/**
	 * Utility method to modally run the dialog and return a consumable response
	 */
	public new string? run() {
		base.show_all();
		int resp = base.run();

		if (resp == Gtk.ResponseType.ACCEPT) {
			return this.get_filename();
		}

		return null;
	}
}

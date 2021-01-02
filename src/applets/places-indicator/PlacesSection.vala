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

public class PlacesSection : Gtk.Box {
	private Gtk.Label alternative_header;
	private Gtk.Box header_box;
	private Gtk.ListBox listbox;
	private Gtk.Revealer revealer;
	private Gtk.Image toggle_image;

	public PlacesSection() {
		Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

		alternative_header = new Gtk.Label(_("Places"));
		alternative_header.set_no_show_all(true);
		alternative_header.set_visible(false);
		alternative_header.set_halign(Gtk.Align.START);
		alternative_header.get_style_context().add_class("dim-label");
		alternative_header.get_style_context().add_class("alternative-label");

		header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		header_box.get_style_context().add_class("places-section-header");

		Gtk.Button header_button = new Gtk.Button();
		header_button.set_relief(Gtk.ReliefStyle.NONE);
		header_button.set_can_focus(false);
		header_box.pack_start(header_button, true, true, 0);

		Gtk.Box header_content_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		header_button.add(header_content_box);

		Gtk.Image header_icon = new Gtk.Image.from_icon_name("folder-symbolic", Gtk.IconSize.MENU);
		header_icon.margin_start = 3;
		header_content_box.pack_start(header_icon, false, false, 0);

		Gtk.Label header_label = new Gtk.Label(_("Places"));
		header_label.set_halign(Gtk.Align.START);
		header_content_box.pack_start(header_label, true, true, 0);

		toggle_image = new Gtk.Image.from_icon_name("pan-down-symbolic", Gtk.IconSize.MENU);
		header_content_box.pack_start(toggle_image, false, false, 0);

		revealer = new Gtk.Revealer();

		listbox = new Gtk.ListBox();
		listbox.get_style_context().add_class("places-list");
		listbox.set_selection_mode(Gtk.SelectionMode.NONE);
		revealer.add(listbox);

		header_button.clicked.connect(toggle_revealer);

		pack_start(alternative_header, false, false, 0);
		pack_start(header_box, false, false, 0);
		pack_start(revealer, false, false, 0);

		show_all();
	}

	private void toggle_revealer() {
		revealer.set_transition_type(Gtk.RevealerTransitionType.NONE);
		if (!revealer.child_revealed) {
			expand_revealer();
		} else {
			contract_revealer();
		}
	}

	private void expand_revealer(bool animate=true) {
		if (!revealer.get_child_revealed()) {
			if (animate) {
				revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
			}
			revealer.set_reveal_child(true);
			toggle_image.set_from_icon_name("pan-up-symbolic", Gtk.IconSize.MENU);
		}
	}

	public void contract_revealer(bool animate=true) {
		if (revealer.get_child_revealed()) {
			if (animate) {
				revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
			}
			revealer.set_reveal_child(false);
			toggle_image.set_from_icon_name("pan-down-symbolic", Gtk.IconSize.MENU);
		}
	}

	/*
	 * Deletes all items from the list
	 * Used when refreshing the list contents
	 */
	public void clear() {
		foreach (Gtk.Widget item in listbox.get_children()) {
			item.destroy();
		}
	}

	/*
	 * Adds an item to the view
	 */
	public void add_item(PlaceItem item) {
		listbox.add(item);
		item.get_parent().set_can_focus(false);
	}

	/*
	 * Hides or reveals the revealer child
	 * Only used for automatic showing/hiding
	 */
	public void reveal(bool state) {
		revealer.set_transition_type(Gtk.RevealerTransitionType.NONE);
		if (state) {
			expand_revealer(false);
		} else {
			contract_revealer(false);
		}
	}

	public void show_alternative_header(bool state) {
		header_box.set_no_show_all(state);
		header_box.set_visible(!state);
		alternative_header.set_no_show_all(!state);
		alternative_header.set_visible(state);

		if (state) {
			listbox.get_style_context().add_class("always-expand");
		} else {
			listbox.get_style_context().remove_class("always-expand");
		}
	}

	public bool is_revealed() {
		return revealer.get_reveal_child();
	}
}

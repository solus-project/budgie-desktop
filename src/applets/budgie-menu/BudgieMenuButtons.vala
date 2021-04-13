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

/**
 * Factory widget to represent a category
 */
public class CategoryButton : Gtk.RadioButton {
	public new GMenu.TreeDirectory? group { public get ; protected set; }

	public CategoryButton(GMenu.TreeDirectory? parent) {
		Gtk.Label lab;

		if (parent != null) {
			lab = new Gtk.Label(parent.get_name());
		} else {
			// Special case, "All"
			lab = new Gtk.Label(_("All"));
		}
		lab.halign = Gtk.Align.START;
		lab.valign = Gtk.Align.CENTER;
		lab.margin_start = 10;
		lab.margin_end = 15;

		var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		layout.pack_start(lab, true, true, 0);
		add(layout);

		get_style_context().add_class("flat");
		get_style_context().add_class("category-button");
		// Makes us look like a normal button :)
		set_property("draw-indicator", false);
		set_can_focus(false);
		group = parent;
	}
}

/**
 * Factory widget to represent a menu item
 */
public class MenuButton : Gtk.Button {
	public DesktopAppInfo info { public get ; protected set ; }
	public GMenu.TreeDirectory parent_menu { public get ; protected set ; }

	public MenuButton(DesktopAppInfo parent, GMenu.TreeDirectory directory, int icon_size) {
		var img = new Gtk.Image.from_gicon(parent.get_icon(), Gtk.IconSize.INVALID);
		img.pixel_size = icon_size;
		img.margin_end = 7;
		var lab = new Gtk.Label(parent.get_display_name());
		lab.halign = Gtk.Align.START;
		lab.valign = Gtk.Align.CENTER;

		const Gtk.TargetEntry[] drag_targets = { {"text/uri-list", 0, 0 }, {"application/x-desktop", 0, 0 }
		};

		Gtk.drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, drag_targets, Gdk.DragAction.COPY);
		base.drag_begin.connect(this.drag_begin);
		base.drag_end.connect(this.drag_end);
		base.drag_data_get.connect(this.drag_data_get);

		var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		layout.pack_start(img, false, false, 0);
		layout.pack_start(lab, true, true, 0);
		add(layout);

		this.info = parent;
		this.parent_menu = directory;
		set_tooltip_text(parent.get_description());

		get_style_context().add_class("flat");
	}

	private bool hide_toplevel() {
		this.get_toplevel().hide();
		return false;
	}

	private new void drag_begin(Gdk.DragContext context) {
		Gtk.drag_set_icon_gicon(context, this.info.get_icon(), 0, 0);
	}

	private new void drag_end(Gdk.DragContext context) {
		Idle.add(this.hide_toplevel);
	}

	private new void drag_data_get(Gdk.DragContext context, Gtk.SelectionData data, uint info, uint timestamp) {
		try {
			string[] urls = { Filename.to_uri(this.info.get_filename()) };
			data.set_uris(urls);
		} catch (Error e) {
			warning("Failed to set copy data: %s", e.message);
		}
	}

	private string? vala_has_no_strstr(string a, string b) {
		int index = a.index_of(b);
		if (index < 0) {
			return null;
		}
		return a.substring(index);
	}

	/* Determine our score in relation to a given search term
	 * Totally stole this from Brisk (Which I wrote anyway so woo.)
	 */
	public int get_score(string term) {
		int score = 0;
		string name = searchable_string(info.get_name());
		if (name == term) {
			score += 100;
		} else if (name.has_prefix(term)) {
			score += 50;
		}

		var found = vala_has_no_strstr(name, term);
		if (found != null) {
			score += 20 + found.length;
		}
		score += strcmp(name, term);
		return score;
	}
}

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

const string APPS_ID = "gnome-applications.menu";
const string LOGOUT_BINARY = "budgie-session-dialog";

/**
 * Return a string suitable for working on.
 * This works around the issue of GNOME Control Center and others deciding to
 * use soft hyphens in their .desktop files.
 */
static string? searchable_string(string input) {
	/* Force dup in vala */
	string mod = "" + input;
	return mod.replace("\u00AD", "").ascii_down().strip();
}

public class BudgieMenuWindow : Budgie.Popover {
	protected Gtk.SearchEntry search_entry;
	protected Gtk.Box main_layout;
	protected Gtk.Box categories;
	protected Gtk.ListBox content;
	private GMenu.Tree tree;
	private GMenu.TreeDirectory other_tree;
	private bool attempted_other_search = false;
	protected Gtk.ScrolledWindow categories_scroll;
	protected Gtk.ScrolledWindow content_scroll;
	protected CategoryButton all_categories;

	// desktop_dir_overrides is a hashtable of dirs -> preferred dirs
	protected HashTable<string,string?> desktop_dir_overrides = null;

	// Mapped category name to item bool
	protected HashTable<string,bool?> category_has_items = null;

	// Mapped category name to the category button
	protected HashTable<string,CategoryButton?> category_buttons = null;

	// Mapped id to MenuButton
	protected HashTable<string,MenuButton?> menu_buttons = null;

	// The current group
	protected GMenu.TreeDirectory? group = null;
	protected bool compact_mode;
	protected bool headers_visible;

	/* Whether we allow rollover category switch */
	protected bool rollover_menus = true;

	// Current search term
	protected string search_term = "";

	protected int icon_size = 24;

	public Settings settings { public get; public set; }

	private bool reloading = false;

	public BudgieMenuWindow(Settings? settings, Gtk.Widget? leparent) {
		Object(settings: settings, relative_to: leparent);
		get_style_context().add_class("budgie-menu");

		main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		add(main_layout);

		category_buttons = new HashTable<string,CategoryButton?>(GLib.str_hash, GLib.str_equal);
		category_has_items = new HashTable<string,bool?>(GLib.str_hash, GLib.str_equal);
		menu_buttons = new HashTable<string,MenuButton?>(GLib.str_hash, GLib.str_equal);

		icon_size = settings.get_int("menu-icons-size");

		// search entry up north
		search_entry = new Gtk.SearchEntry();
		main_layout.pack_start(search_entry, false, false, 0);

		// middle holds the categories and applications
		var middle = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		main_layout.pack_start(middle, true, true, 0);

		// clickable categories
		categories = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		categories.margin_top = 3;
		categories.margin_bottom = 3;
		categories_scroll = new Gtk.ScrolledWindow(null, null);
		categories_scroll.set_overlay_scrolling(false);
		categories_scroll.set_shadow_type(Gtk.ShadowType.NONE); // Don't have an outline
		categories_scroll.get_style_context().add_class("categories");
		categories_scroll.get_style_context().add_class("sidebar");
		categories_scroll.add(categories);
		categories_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC); // Allow scrolling categories vertically if necessary
		middle.pack_start(categories_scroll, false, false, 0);

		// "All" button"
		all_categories = new CategoryButton(null);
		all_categories.enter_notify_event.connect(this.on_mouse_enter);
		all_categories.toggled.connect(()=> {
			update_category(all_categories);
		});
		categories.pack_start(all_categories, false, false, 0);

		var right_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		middle.pack_start(right_layout, true, true, 0);

		// holds all the applications
		content = new Gtk.ListBox();
		content.row_activated.connect(on_row_activate);
		content.set_selection_mode(Gtk.SelectionMode.NONE);
		content_scroll = new Gtk.ScrolledWindow(null, null);
		content_scroll.set_overlay_scrolling(true);
		content_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		content_scroll.add(content);
		right_layout.pack_start(content_scroll, true, true, 0);

		// placeholder in case of no results
		var placeholder = new Gtk.Label("<big>%s</big>".printf(_("Sorry, no items found")));
		placeholder.use_markup = true;
		placeholder.get_style_context().add_class("dim-label");
		placeholder.show();
		placeholder.margin = 6;
		content.valign = Gtk.Align.START;
		content.set_placeholder(placeholder);

		settings.changed.connect(on_settings_changed);
		on_settings_changed("menu-compact");
		on_settings_changed("menu-headers");
		on_settings_changed("menu-categories-hover");

		// management of our listbox
		content.set_filter_func(do_filter_list);
		content.set_sort_func(do_sort_list);

		// searching functionality :)
		search_entry.changed.connect(()=> {
			search_term = searchable_string(search_entry.text);
			content.invalidate_headers();
			content.invalidate_filter();
			content.invalidate_sort();
		});

		search_entry.grab_focus();

		// Enabling activation by search entry
		search_entry.activate.connect(on_entry_activate);
		// sensible vertical height
		set_size_request(300, 510);
		categories_scroll.min_content_height = 510; // Have a minimum height on the categories scroll that matches the menu size
		categories_scroll.propagate_natural_height = true;
		// load them in the background
		Idle.add(()=> {
			load_menus(null);
			content.invalidate_headers();
			content.invalidate_filter();
			content.invalidate_sort();
			queue_resize();
			if (!get_realized()) {
				realize();
			}
			return false;
		});
	}

	/* Reload menus, essentially. */
	public void refresh_tree() {
		lock (reloading) {
			if (reloading) {
				return;
			}
			reloading = true;
		}

		foreach (var child in content.get_children()) {
			child.destroy();
		}

		category_buttons.remove_all();
		category_has_items.remove_all();
		menu_buttons.remove_all();

		foreach (var child in categories.get_children()) {
			if (child != all_categories) {
				SignalHandler.disconnect_by_func(child, (void*)on_mouse_enter, this);
				child.destroy();
			}
		}

		SignalHandler.disconnect_by_func(tree, (void*)refresh_tree, this);
		this.tree = null;

		Idle.add(() => {
			load_menus(null);
			content.invalidate_headers();
			content.invalidate_filter();
			content.invalidate_sort();
			return false;
		});

		lock (reloading) {
			reloading = false;
		}
	}

	/**
	 * Permits "rolling" over categories
	 */
	private bool on_mouse_enter(Gtk.Widget source_widget, Gdk.EventCrossing e) {
		if (!this.rollover_menus) {
			return Gdk.EVENT_PROPAGATE;
		}
		/* If it's not valid, don't use it. */
		Gtk.ToggleButton? b = source_widget as Gtk.ToggleButton;
		if (!b.get_sensitive() || !b.get_visible()) {
			return Gdk.EVENT_PROPAGATE;
		}

		/* Activate the source_widget category */
		b.set_active(true);
		return Gdk.EVENT_PROPAGATE;
	}


	/**
	 * Load "menus" (.desktop's) recursively (ripped from our RunDialog)
	 *
	 * @param tree_root Initialised GMenu.TreeDirectory, or null
	 */
	private void load_menus(GMenu.TreeDirectory? tree_root = null) {
		GMenu.TreeDirectory root;
		bool is_top_level = false;

		// Load the tree for the first time
		if (tree == null) {
			is_top_level = true;
			tree = new GMenu.Tree(APPS_ID, GMenu.TreeFlags.SORT_DISPLAY_NAME);

			try {
				tree.load_sync();
			} catch (Error e) {
				stderr.printf("Error: %s\n", e.message);
				lock (reloading) {
					reloading = false;
				}
				return;
			}
			/* Think of deferred routines.. */
			Idle.add(() => {
				tree.changed.connect(refresh_tree);
				return false;
			});
		}

		if (tree_root == null) {
			root = tree.get_root_directory();
		} else {
			root = tree_root;
		}

		// This is almost certainly the least optimal way of doing this. However, couldn't get the TreeDirectory lookup for Other to work.
		if ((other_tree == null) && !attempted_other_search) {
			var it = root.iter();
			GMenu.TreeItemType? type;

			while ((type = it.next()) != GMenu.TreeItemType.INVALID) {
				if (type == GMenu.TreeItemType.DIRECTORY) {
					var dir = it.get_directory();

					if (dir.get_desktop_file_path().has_suffix("X-GNOME-Other.directory")) {
						other_tree = dir;
						break;
					}
				}
			}

			attempted_other_search = true;
		}

		var it = root.iter();
		GMenu.TreeItemType? type;

		while ((type = it.next()) != GMenu.TreeItemType.INVALID) {
			if (type == GMenu.TreeItemType.DIRECTORY) {
				var dir = it.get_directory();
				bool is_sundry = dir.get_desktop_file_path().has_suffix("X-GNOME-Sundry.directory");

				if (!is_sundry || (is_sundry && (other_tree == null))) { // Create a button if not Sundry or is Sundry and Other tree is null
					var btn = new CategoryButton(dir);
					btn.join_group(all_categories);
					btn.enter_notify_event.connect(this.on_mouse_enter);

					// Note: We're intentionally not adding the categories yet
					category_buttons.insert(dir.get_name(), btn); // Add the button for the desktop file path

					// Ensures we find the correct button
					btn.toggled.connect(() => {
						update_category(btn);
					});
				}

				load_menus(dir);
			} else if (type == GMenu.TreeItemType.ENTRY) {
				// store the entry by its command line (without path)
				var appinfo = it.get_entry().get_app_info();
				if (tree_root == null) {
					warning("%s has no parent directory, not adding to menu\n", appinfo.get_display_name());
				} else {
					var use_root = root;

					if (appinfo.get_is_hidden() || appinfo.get_nodisplay()) { // Hidden or shouldn't be displayed
						continue; // Skip this entry
					}

					string[]? not_show_in = appinfo.get_string_list("NotShowIn"); // Get any NotShowIn in the Desktop file
					bool not_show_in_budgie = false;

					if (not_show_in != null) { // If we got a NotShowIn list
						for (int i = 0; i < not_show_in.length; i++) { // For each item
							var item = not_show_in[i];

							not_show_in_budgie = item.contains("Budgie"); // Update not_show_in

							if (not_show_in_budgie) { // Has Budgie
								break;
							}
						}
					}

					if (not_show_in_budgie) { // Have NoShowIn and it contains Budgie
						continue; // Skip entry
					}

					var app_id = appinfo.get_id();

					if (root.get_desktop_file_path().has_suffix("X-GNOME-Sundry.directory")) { // If we're iterating over desktop entries in Sundry
						if (other_tree != null) {
							use_root = other_tree;
						}
					}

					if (!menu_buttons.contains(app_id)) { // If we haven't already added this button
						var btn = new MenuButton(appinfo, use_root, icon_size);

						btn.clicked.connect(() => {
							hide();
							launch_app(btn.info);
						});
						menu_buttons.insert(app_id, btn);
						btn.show_all();
						content.add(btn);

						string desktop_file_path = use_root.get_name(); // Get the name of the category of this root
						category_has_items.set(desktop_file_path, true); // Ensure we indicate the desktop file path as items
					}
				}
			}
		}

		if (is_top_level) { // If we're running load_menus at the top level in our tree
			List<string> category_names = new List<string>();
			category_has_items.foreach((name, has) => { // For each category
				if (has) {
					category_names.append(name); // Add the category name
				} else { // Don't have any items for this category
					category_buttons.remove(name); // Remove the button from the categories HashTable since we won't need it
				}
			});

			category_names.sort((cat_one, cat_two) => { // Sort the categories
				return cat_one.collate(cat_two);
			});

			category_names.foreach((category_name) => {
				CategoryButton? button = category_buttons.get(category_name); // Get the button for this category

				if (button != null) { // If the button exists
					categories.pack_start(button, false, false, 0); // Add the button
				}
			});
		}
	}

	protected void on_settings_changed(string key) {
		switch (key) {
			case "menu-compact":
				var vis = settings.get_boolean(key);
				categories_scroll.no_show_all = vis;
				categories_scroll.set_visible(vis);
				compact_mode = vis;
				content.invalidate_headers();
				content.invalidate_filter();
				content.invalidate_sort();
				break;
			case "menu-headers":
				var hed = settings.get_boolean(key);
				headers_visible = hed;
				if (hed) {
					content.set_header_func(do_list_header);
				} else {
					content.set_header_func(null);
				}
				content.invalidate_headers();
				content.invalidate_filter();
				content.invalidate_sort();
				break;
			case "menu-categories-hover":
				/* Category hover */
				this.rollover_menus = settings.get_boolean(key);
				break;
			default:
				// not interested
				break;
		}
	}


	protected void on_entry_activate() {
		Gtk.ListBoxRow? selected = null;

		var rows = content.get_selected_rows();
		if (rows != null) {
			selected = rows.data;
		} else {
			foreach (var child in content.get_children()) {
				if (child.get_visible() && child.get_child_visible()) {
					selected = child as Gtk.ListBoxRow;
					break;
				}
			}
		}
		if (selected == null) {
			return;
		}

		MenuButton btn = selected.get_child() as MenuButton;
		launch_app(btn.info);
	}

	protected void on_row_activate(Gtk.ListBoxRow? row) {
		if (row == null) {
			return;
		}
		/* Launch this item, i.e. keyboard access. */
		MenuButton btn = row.get_child() as MenuButton;
		launch_app(btn.info);
	}

	/**
	 * Provide category headers in the "All" category
	 */
	protected void do_list_header(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after) {
		MenuButton? child = null;
		string? prev = null;
		string? next = null;

		// In a category listing, kill headers
		if (group != null) {
			if (before != null) {
				before.set_header(null);
			}
			if (after != null) {
				after.set_header(null);
			}
			return;
		}

		// Just retrieve the category names
		if (before != null) {
			child = before.get_child() as MenuButton;
			prev = child.parent_menu.get_name();
		}

		if (after != null) {
			child = after.get_child() as MenuButton;
			next = child.parent_menu.get_name();
		}

		// Only add one if we need one!
		if (before == null || after == null || prev != next) {
			var label = new Gtk.Label(Markup.printf_escaped("<big>%s</big>", prev));
			label.get_style_context().add_class("dim-label");
			label.halign = Gtk.Align.START;
			label.use_markup = true;
			before.set_header(label);
			label.margin = 6;
		} else {
			before.set_header(null);
		}
	}

	/* Helper ported from Brisk */
	private bool array_contains(string?[] array, string term) {
		foreach (string? field in array) {
			if (field == null) {
				continue;
			}
			string ct = searchable_string(field);
			if (term.match_string(ct, true)) {
				return true;
			}
			if (term in ct) {
				return true;
			}
		}
		return false;
	}

	/* Helper ported from brisk */
	private bool info_matches_term(AppInfo? info, string term) {
		if (info == null) { // No valid AppInfo provided
			return false;
		}

		string?[] fields = {
			info.get_display_name(),
			info.get_description(),
			info.get_name(),
			info.get_executable()
		};

		if (array_contains(fields, term)) {
			return true;
		}

		var keywords = ((DesktopAppInfo) info).get_keywords();
		if (keywords == null || keywords.length < 1) {
			return false;
		}

		return array_contains(keywords, term);
	}

	private bool is_item_dupe(MenuButton? button) {
		MenuButton? compare_item = menu_buttons.lookup(button.info.get_id());
		if (compare_item != null && compare_item != button) {
			return true;
		}
		return false;
	}

	/**
	 * Filter out results in the list according to whatever the current filter is,
	 * i.e. group based or search based
	 */
	protected bool do_filter_list(Gtk.ListBoxRow row) {
		MenuButton child = row.get_child() as MenuButton;

		string term = search_term.strip();
		if (term.length > 0) {
			// "disable" categories while searching
			categories.sensitive = false;
			// Items must be unique across the search
			if (this.is_item_dupe(child)) {
				return false;
			}

			return info_matches_term(child.info, term);
		}

		// "enable" categories if not searching
		categories.sensitive = true;

		// No more filtering, show all
		if (group == null) {
			if (this.headers_visible) { // If we are going to be showing headers
				return true;
			} else { // Not showing headers
				return !this.is_item_dupe(child);
			}
		}

		// If the GMenu.TreeDirectory isn't the same as the current filter, hide it
		if (child.parent_menu != group) {
			return false;
		}
		return true;
	}

	protected int do_sort_list(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		MenuButton child1 = row1.get_child() as MenuButton;
		MenuButton child2 = row2.get_child() as MenuButton;

		string term = search_term.strip();

		if (term.length > 0) {
			int sc1 = child1.get_score(term);
			int sc2 = child2.get_score(term);
			/* Vala can't do this: return (sc1 > sc2) - (sc1 - sc2); */
			if (sc1 < sc2) {
				return 1;
			} else if (sc1 > sc2) {
				return -1;
			}
			return 0;
		}

		// Only perform category grouping if headers are visible
		string parentA = searchable_string(child1.parent_menu.get_name());
		string parentB = searchable_string(child2.parent_menu.get_name());
		if (child1.parent_menu != child2.parent_menu && this.headers_visible) {
			return parentA.collate(parentB);
		}

		string nameA = searchable_string(child1.info.get_display_name());
		string nameB = searchable_string(child2.info.get_display_name());
		return nameA.collate(nameB);
	}


	/**
	 * Change the current group/category
	 */
	protected void update_category(CategoryButton btn) {
		if (btn.active) {
			group = btn.group;
			content.invalidate_filter();
			content.invalidate_headers();
			content.invalidate_sort();
		}
	}

	/**
	 * Launch an application
	 */
	protected void launch_app(DesktopAppInfo info) {
		hide();
		// Do it on the idle thread to make sure we don't have focus wars
		Idle.add(() => {
			try {
				/*
				 appinfo.launch has difficulty running pkexec
				 based apps so lets spawn an async process instead
				 */
				var commandline = info.get_commandline();
				string[] spawn_args = {};
				const string checkstr = "pkexec";
				if (commandline.contains(checkstr)) {
					spawn_args = commandline.split(" ");
				}
				if (spawn_args.length >= 2 && spawn_args[0] == checkstr) {
					string[] spawn_env = Environ.get();
					Pid child_pid;
					Process.spawn_async("/",
						spawn_args,
						spawn_env,
						SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
						null, out child_pid);
					ChildWatch.add(child_pid, (pid, status) => {
						Process.close_pid(pid);
					});
				}
				else {
					info.launch(null, null);
				}
			} catch (Error e) {
				stdout.printf("Error launching application: %s\n", e.message);
			}
			return false;
		});
	}

	/**
	 * We need to make some changes to our display before we go showing ourselves
	 * again! :)
	 */
	public override void show() {
		search_term = "";
		search_entry.text = "";
		group = null;
		all_categories.set_active(true);
		content.select_row(null);
		content_scroll.get_vadjustment().set_value(0);
		categories_scroll.get_vadjustment().set_value(0);
		categories.sensitive = true;
		Idle.add(() => {
			/* grab focus when we're not busy, ensuring it works.. */
			search_entry.grab_focus();
			return false;
		});
		base.show();
		if (!compact_mode) {
			categories_scroll.show_all();
		} else {
			categories_scroll.hide();
		}
	}
}

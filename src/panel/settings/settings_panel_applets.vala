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
	/**
	* AppletSettingsFrame provides a UI wrapper for Applet Settings
	*/
	public class AppletSettingsFrame : Gtk.Box {
		public AppletSettingsFrame() {
			Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
			Gtk.Label lab = new Gtk.Label(_("Configure applet"));
			lab.set_use_markup(true);
			lab.halign = Gtk.Align.START;
			lab.margin_bottom = 6;
			valign = Gtk.Align.START;

			this.get_style_context().add_class("settings-frame");
			lab.get_style_context().add_class("settings-title");

			var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
			sep.margin_bottom = 6;
			this.pack_start(lab, false, false, 0);
			this.pack_start(sep, false, false, 0);
		}

		public override void add(Gtk.Widget widget) {
			this.pack_start(widget, false, false, 0);
		}
	}

	/**
	* AppletItem is used to represent a Budgie Applet in the list
	*/
	public class AppletItem : Gtk.Box {
		/**
		* We're bound to the info
		*/
		public unowned Budgie.AppletInfo? applet { public get ; construct set; }

		private Gtk.Image image;
		private Gtk.Label label;

		/**
		* Construct a new AppletItem for the given applet
		*/
		public AppletItem(Budgie.AppletInfo? info) {
			Object(applet: info);

			get_style_context().add_class("applet-item");

			margin_top = 4;
			margin_bottom = 4;

			image = new Gtk.Image();
			image.margin_start = 12;
			image.margin_end = 14;
			pack_start(image, false, false, 0);

			label = new Gtk.Label("");
			label.margin_end = 18;
			label.halign = Gtk.Align.START;
			pack_start(label, false, false, 0);

			this.applet.bind_property("name", this.label, "label", BindingFlags.DEFAULT|BindingFlags.SYNC_CREATE);
			this.applet.bind_property("icon", this.image, "icon-name", BindingFlags.DEFAULT|BindingFlags.SYNC_CREATE);
			this.image.icon_size = Gtk.IconSize.MENU;

			this.show_all();
		}
	}

	/**
	* AppletsPage contains the applets view for a given panel
	*/
	public class AppletsPage : Gtk.Box {
		unowned Budgie.Toplevel? toplevel;
		unowned Budgie.DesktopManager? manager = null;
		Gtk.Button button_add;
		Gtk.Button button_move_applet_up;
		Gtk.Button button_move_applet_down;
		Gtk.Button button_remove_applet;

		/* Used applet storage */
		Gtk.ListBox listbox_applets;
		HashTable<string,AppletItem?> items;

		/* Allow us to display settings when each item is selected */
		Gtk.Stack settings_stack;

		unowned Budgie.AppletInfo? current_info = null;

		public AppletsPage(Budgie.DesktopManager? manager, Budgie.Toplevel? toplevel) {
			Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 0);
			this.manager = manager;
			this.toplevel = toplevel;
			valign = Gtk.Align.FILL;
			vexpand = false;

			margin = 6;

			this.configure_list();
			this.configure_actions();

			this.update_action_buttons();

			/* Insert them now */
			foreach (var applet in this.toplevel.get_applets()) {
				this.applet_added(applet);
			}

			Idle.add(() => {
				this.settings_stack.set_visible_child_name("main");
				return false;
			});

			toplevel.applet_added.connect(this.applet_added);
			toplevel.applet_removed.connect(this.applet_removed);
			toplevel.applets_changed.connect(this.applets_changed);

			this.applets_changed();
		}

		/**
		* Something in the applet availability changed for this panel.
		*/
		void applets_changed() {
			this.listbox_applets.invalidate_sort();
			this.listbox_applets.invalidate_headers();
			this.update_action_buttons();
		}

		/**
		* Update the sensitivity of the action buttons based on the current
		* selection.
		*/
		void update_action_buttons() {
			unowned Gtk.ListBoxRow? row = this.listbox_applets.get_selected_row();
			Budgie.AppletInfo? info = null;

			if (row != null) {
				info = ((AppletItem) row.get_child()).applet;
			}

			/* Require applet info to be useful. */
			if (info == null) {
				current_info = null;
				button_remove_applet.set_sensitive(false);
				button_move_applet_up.set_sensitive(false);
				button_move_applet_down.set_sensitive(false);
				return;
			}

			current_info = info;

			button_remove_applet.set_sensitive(true);
			button_move_applet_up.set_sensitive(toplevel.can_move_applet_left(info));
			button_move_applet_down.set_sensitive(toplevel.can_move_applet_right(info));
		}

		/**
		* Configure the main display list used to show the currently used
		* applets for the panel
		*/
		void configure_list() {
			items = new HashTable<string,AppletItem?>(str_hash, str_equal);

			var frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

			/* Allow moving the applet */
			var move_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
			move_box.set_layout(Gtk.ButtonBoxStyle.START);
			move_box.get_style_context().add_class(Gtk.STYLE_CLASS_INLINE_TOOLBAR);
			button_move_applet_up = new Gtk.Button.from_icon_name("go-up-symbolic", Gtk.IconSize.MENU);
			button_move_applet_up.clicked.connect(move_applet_up);
			button_move_applet_down = new Gtk.Button.from_icon_name("go-down-symbolic", Gtk.IconSize.MENU);
			button_move_applet_down.clicked.connect(move_applet_down);
			move_box.add(button_move_applet_up);
			move_box.add(button_move_applet_down);

			button_remove_applet = new Gtk.Button.from_icon_name("edit-delete-symbolic", Gtk.IconSize.MENU);
			button_remove_applet.clicked.connect(remove_applet);
			move_box.add(button_remove_applet);

			frame_box.pack_start(move_box, false, false, 0);
			var frame = new Gtk.Frame(null);
			frame.vexpand = false;
			frame.margin_end = 20;
			frame.margin_top = 12;
			frame.add(frame_box);

			listbox_applets = new Gtk.ListBox();
			listbox_applets.set_activate_on_single_click(true);
			listbox_applets.row_selected.connect(row_selected);
			Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
			scroll.add(listbox_applets);
			scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			frame_box.pack_start(scroll, true, true, 0);
			this.pack_start(frame, false, true, 0);

			/* Ensure themes link them together properly */
			move_box.get_style_context().set_junction_sides(Gtk.JunctionSides.BOTTOM);
			listbox_applets.get_style_context().set_junction_sides(Gtk.JunctionSides.TOP);

			/* Make sure we can sort + header */
			listbox_applets.set_sort_func(this.do_sort);
			listbox_applets.set_header_func(this.do_headers);
		}

		/**
		* Configure the action grid to manipulation the applets
		*/
		void configure_actions() {
			var grid = new SettingsGrid();
			grid.small_mode = true;
			this.pack_start(grid, false, false, 0);

			/* Allow adding new applets*/
			button_add = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
			button_add.valign = Gtk.Align.CENTER;
			button_add.vexpand = false;
			button_add.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			button_add.get_style_context().add_class("round-button");
			button_add.clicked.connect(this.add_applet);
			grid.add_row(new SettingsRow(button_add,
				_("Add applet"),
				_("Choose a new applet to add to this panel")));

			settings_stack = new Gtk.Stack();
			settings_stack.set_homogeneous(false);
			settings_stack.halign = Gtk.Align.FILL;
			settings_stack.valign = Gtk.Align.START;
			settings_stack.margin_top = 24;
			grid.attach(settings_stack, 0, ++grid.current_row, 2, 1);


			/* Placeholder for no settings */
			var placeholder = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			placeholder.valign = Gtk.Align.START;
			var placeholder_img = new Gtk.Image.from_icon_name("dialog-information-symbolic", Gtk.IconSize.MENU);
			var placeholder_text = new Gtk.Label(_("No settings available"));
			placeholder_text.set_margin_start(10);
			placeholder.pack_start(placeholder_img, false, false, 0);
			placeholder.pack_start(placeholder_text, false, false, 0);
			placeholder.show_all();
			placeholder_img.valign = Gtk.Align.CENTER;
			placeholder_text.valign = Gtk.Align.CENTER;
			settings_stack.add_named(placeholder, "no-settings");

			/* Empty placeholder for no selection .. */
			var empty = new Gtk.EventBox();
			settings_stack.add_named(empty, "main");
		}

		/**
		* Changed the row so update the UI
		*/
		private void row_selected(Gtk.ListBoxRow? row) {
			if (row == null) {
				this.settings_stack.set_visible_child_name("main");
				return;
			}

			this.update_action_buttons();
			unowned AppletItem? item = row.get_child() as AppletItem;
			unowned Gtk.Widget? lookup = this.settings_stack.get_child_by_name(item.applet.uuid);
			if (lookup == null) {
				this.settings_stack.set_visible_child_name("no-settings");
				return;
			}
			this.settings_stack.set_visible_child(lookup);
		}

		/**
		* We have a new applet, so stored it in the list
		*/
		private void applet_added(Budgie.AppletInfo? applet) {
			if (this.items.contains(applet.uuid)) {
				return;
			}

			/* Allow viewing settings on demand */
			if (applet.applet.supports_settings()) {
				var frame = new AppletSettingsFrame();
				var ui = applet.applet.get_settings_ui();
				frame.add(ui);
				ui.show();
				frame.show();
				settings_stack.add_named(frame, applet.uuid);
			}

			/* Stuff the new item into display */
			var item = new AppletItem(applet);
			item.show_all();
			listbox_applets.add(item);
			items[applet.uuid] = item;
		}

		/**
		* An applet was removed, so remove from our list also
		*/
		private void applet_removed(string uuid) {
			AppletItem? item = items.lookup(uuid);
			Gtk.Widget? lookup = null;

			if (item == null) {
				return;
			}

			/* Remove the child again */
			lookup = settings_stack.get_child_by_name(uuid);
			if (lookup != null) {
				lookup.destroy();
			}

			item.get_parent().destroy();
			items.remove(uuid);
		}

		/**
		* Convert a string alignment into one that is sortable
		*/
		int align_to_int(string al) {
			switch (al) {
				case "start":
					return 0;
				case "center":
					return 1;
				case "end":
				default:
					return 2;
			}
		}

		/**
		* Sort the list in accordance with alignment and actual position
		*/
		int do_sort(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after) {
			AppletItem? before_child = before.get_child() as AppletItem;
			AppletItem? after_child = after.get_child() as AppletItem;

			if (before_child == null || after_child == null) {
				return 0;
			}

			unowned Budgie.AppletInfo? before_info = before_child.applet;
			unowned Budgie.AppletInfo? after_info = after_child.applet;

			if (before_info == null || after_info == null) {
				return 0;
			}

			if (before_info.alignment != after_info.alignment) {
				int bi = align_to_int(before_info.alignment);
				int ai = align_to_int(after_info.alignment);

				if (ai > bi) {
					return -1;
				} else {
					return 1;
				}
			} else if (before_info.position < after_info.position) {
				return -1;
			} else if (before_info.position > after_info.position) {
				return 1;
			}

			return 0;
		}

		/**
		* Provide headers in the list to separate the visual positions
		*/
		void do_headers(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after) {
			string? prev = null;
			string? next = null;
			unowned Budgie.AppletInfo? before_info = null;
			unowned Budgie.AppletInfo? after_info = null;

			if (before != null) {
				before_info = ((AppletItem) before.get_child()).applet;
				prev = before_info.alignment;
			}

			if (after != null) {
				after_info = ((AppletItem) after.get_child()).applet;
				next = after_info.alignment;
			}

			if (after == null || prev != next) {
				Gtk.Label? label = null;
				switch (prev) {
					case "start":
						label = new Gtk.Label(_("Start"));
						break;
					case "center":
						label = new Gtk.Label(_("Center"));
						break;
					default:
						label = new Gtk.Label(_("End"));
						break;
				}
				label.get_style_context().add_class("dim-label");
				label.get_style_context().add_class("applet-row-header");
				label.halign = Gtk.Align.START;
				label.margin_start = 4;
				label.margin_top = 2;
				label.margin_bottom = 2;
				label.valign = Gtk.Align.CENTER;
				label.use_markup = true;
				before.set_header(label);
			} else {
				before.set_header(null);
			}
		}

		/**
		* User requested to add a new applet to the active panel,
		* show a chooser dialog
		*/
		void add_applet() {
			var dlg = new AppletChooser(this.get_toplevel() as Gtk.Window);
			dlg.set_plugin_list(this.manager.get_panel_plugins());
			string? applet_id = dlg.run();
			dlg.destroy();
			if (applet_id == null) {
				return;
			}

			this.toplevel.add_new_applet(applet_id);
		}

		/**
		* User requested we delete this applet. Make sure they meant it!
		*/
		void remove_applet() {
			if (current_info == null) {
				return;
			}

			var dlg = new RemoveAppletDialog(this.get_toplevel() as Gtk.Window);
			bool del = dlg.run();
			dlg.destroy();
			if (del) {
				this.toplevel.remove_applet(this.current_info);
			}
		}

		/**
		* User moved the applet up in the list (left in budgie terms)
		*/
		void move_applet_up() {
			if (current_info != null && this.toplevel.can_move_applet_left(this.current_info)) {
				this.toplevel.move_applet_left(this.current_info);
			}
		}

		/**
		* User moved the applet down in the list (right in budgie terms)
		*/
		void move_applet_down() {
			if (current_info != null && this.toplevel.can_move_applet_right(this.current_info)) {
				this.toplevel.move_applet_right(this.current_info);
			}
		}
	}
}

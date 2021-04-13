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
	public const string SETTINGS_DBUS_NAME = "org.budgie_desktop.Settings";
	public const string SETTINGS_DBUS_PATH = "/org/budgie_desktop/Settings";

	[DBus (name="org.budgie_desktop.Settings")]
	public class SettingsIface {
		private Budgie.SettingsWindow? settings_window = null;

		[DBus (visible=false)]
		public SettingsIface(Budgie.SettingsWindow? win) {
			this.settings_window = win;
		}

		public void Close() throws DBusError, IOError {
			this.settings_window.requested_close();
		}
	}

	public class SettingsWindow : Gtk.Window {
		private SettingsIface? iface;
		private DBusConnection? conn;
		private uint? register_id;

		Gtk.HeaderBar header;
		Gtk.ListBox sidebar;
		Gtk.Stack content;
		Gtk.Box layout;
		HashTable<string,string> group_map;
		HashTable<string,SettingsPage?> page_map;
		HashTable<string,SettingsItem?> sidebar_map;

		public Budgie.DesktopManager? manager { public set ; public get ; }

		/* Special item that allows us to add new items to the display */
		SettingsItem? item_add_panel;
		bool new_panel_requested = false;

		public SettingsWindow(Budgie.DesktopManager? manager) {
			Object(type: Gtk.WindowType.TOPLEVEL, icon_name: "preferences-desktop", manager: manager);

			header = new Gtk.HeaderBar();
			header.set_show_close_button(true);
			set_titlebar(header);

			group_map = new HashTable<string,string>(str_hash, str_equal);
			group_map["appearance"] = _("Appearance");
			group_map["panel"] = _("Panels");
			group_map["session"] = _("Session");
			page_map = new HashTable<string,SettingsPage?>(str_hash, str_equal);
			sidebar_map = new HashTable<string,SettingsItem?>(str_hash, str_equal);

			layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			add(layout);

			/* Have to override wmclass for pinning support */
			set_icon_name("preferences-desktop");
			set_title(_("Budgie Desktop Settings"));
			set_wmclass("budgie-desktop-settings", "budgie-desktop-settings");

			/* Fit even on a spud resolution */
			set_default_size(750, 550);

			/* Sidebar navigation */
			var scroll = new Gtk.ScrolledWindow(null, null);
			scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			sidebar = new Gtk.ListBox();
			sidebar.set_header_func(this.do_headers);
			sidebar.set_sort_func(this.do_sort);
			sidebar.row_activated.connect(this.on_row_activate);
			sidebar.set_activate_on_single_click(true);
			scroll.add(sidebar);
			layout.pack_start(scroll, false, false, 0);
			scroll.margin_end = 24;

			/* Where actual Things go */
			content = new Gtk.Stack();
			content.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
			layout.pack_start(content, true, true, 0);

			/* Help our theming community out */
			get_style_context().add_class("budgie-settings-window");
			sidebar.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);

			this.build_content();

			this.item_add_panel = new SettingsItem(SETTINGS_GROUP_PANEL,
												"x-add-panel",
												_("Create new panel"),
												"list-add-symbolic");

			this.sidebar.add(this.item_add_panel);

			/* We'll need to build panel items for each toplevel */
			this.manager.panel_added.connect(this.on_panel_added);
			this.manager.panel_deleted.connect(this.on_panel_deleted);
			this.manager.panels_changed.connect_after(this.on_panels_changed);

			this.on_panels_changed();

			Bus.own_name(BusType.SESSION, Budgie.SETTINGS_DBUS_NAME, BusNameOwnerFlags.ALLOW_REPLACEMENT, on_bus_acquired, on_name_acquired, on_name_lost);

			unrealize.connect(() => { // When the window is about to be destroyed
				if (conn != null) {
					conn.unregister_object(register_id); // Ensure we unregister our connection
				}
			});

			layout.show_all();
			header.show_all();
		}

		/**
		* Static pages that will always be part of the UI
		*/
		void build_content() {
			this.add_page(new Budgie.StylePage());
			this.add_page(new Budgie.DesktopPage());
			this.add_page(new Budgie.FontPage());
			this.add_page(new Budgie.WindowsPage());
			this.add_page(new Budgie.AutostartPage());
			this.add_page(new Budgie.RavenPage());
		}

		public void requested_close() throws DBusError, IOError {
			this.destroy();
			this.close();
		}

		private void on_bus_acquired(DBusConnection c) {
			try {
				iface = new SettingsIface(this);
				conn = c;
				register_id = conn.register_object(Budgie.SETTINGS_DBUS_PATH, iface);
			} catch (Error e) {
				stderr.printf("Error registering SettingsIface: %s\n", e.message);
			}
		}

		public void on_name_acquired(DBusConnection c, string name) {
			message("Acquired %s DBus connection", name);
		}

		public void on_name_lost(DBusConnection c, string name) {
			message("Lost or replaced DBus connection");
		}

		/**
		* Update the state of the add-panel button in relation to slots
		*/
		void on_panels_changed() {
			item_add_panel.set_sensitive(this.manager.slots_available() >= 1);
			Idle.add(() => {
				this.sidebar.invalidate_sort();
				this.sidebar.invalidate_filter();
				return false;
			});
		}

		/**
		* Handle transition between various pages
		*/
		void on_row_activate(Gtk.ListBoxRow? row) {
			if (row == null) {
				return;
			}
			SettingsItem? item = row.get_child() as SettingsItem;
			if (item != this.item_add_panel) {
				this.content.set_visible_child_name(item.content_id);
				return;
			}
			this.new_panel_requested = true;
			if (this.manager.slots_available() >= 1) {
				this.manager.create_new_panel();
			}
		}

		/**
		* Add a new page to our sidebar + stack
		*/
		void add_page(Budgie.SettingsPage? page) {
			var settings_item = new SettingsItem(page.group, page.content_id, page.title, page.icon_name);
			settings_item.show_all();
			sidebar.add(settings_item);

			page.bind_property("title", settings_item, "label", BindingFlags.DEFAULT);
			page.bind_property("display-weight", settings_item, "display-weight", BindingFlags.DEFAULT|BindingFlags.SYNC_CREATE);

			this.sidebar_map[page.content_id] = settings_item;
			this.page_map[page.content_id] = page;

			if (page.want_scroll) {
				var scroll = new Gtk.ScrolledWindow(null, null);
				scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
				scroll.add(page);
				scroll.show();
				content.add_named(scroll, page.content_id);
			} else {
				page.show();
				content.add_named(page, page.content_id);
			}
			this.sidebar.invalidate_sort();
			this.sidebar.invalidate_headers();
		}

		/**
		* Remove a page from the sidebar and content stack
		*/
		void remove_page(string content_id) {
			Budgie.SettingsPage? page = this.page_map.lookup(content_id);
			Budgie.SettingsItem? item = this.sidebar_map.lookup(content_id);

			/* Remove from listbox */
			if (item != null) {
				item.get_parent().destroy();
			}

			/* Remove from content view */
			if (page != null) {
				page.destroy();
			}
			this.sidebar.invalidate_sort();
			this.sidebar.invalidate_headers();
		}

		/**
		* Provide categorisation for our sidebar items
		*/
		void do_headers(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after) {
			SettingsItem? child = null;
			string? prev = null;
			string? next = null;

			if (before != null) {
				child = before.get_child() as SettingsItem;
				prev = child.group;
			}

			if (after != null) {
				child = after.get_child() as SettingsItem;
				next = child.group;
			}

			if (after == null || prev != next) {
				string? title = group_map.lookup(prev);
				Gtk.Label label = new Gtk.Label(title);
				label.get_style_context().add_class(Gtk.STYLE_CLASS_DIM_LABEL);
				label.halign = Gtk.Align.START;
				label.use_markup = true;
				label.margin_top = 8;
				label.margin_bottom = 8;
				label.margin_start = 12;
				before.set_header(label);
			} else {
				before.set_header(null);
			}
		}

		/**
		* Sort the sidebar items, enforcing clustering of the same groups
		*/
		int do_sort(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after) {
			SettingsItem? child_before = null;
			SettingsItem? child_after = null;

			child_before = before.get_child() as SettingsItem;
			child_after = after.get_child() as SettingsItem;

			/* Match untranslated group string only */
			if (child_before.group != child_after.group) {
				return strcmp(child_before.group, child_after.group);
			}

			/* Always ensure the "new panel" button is last, at the tail of panels group */
			if (child_after == this.item_add_panel) {
				return -1;
			} else if (child_before == this.item_add_panel) {
				return 1;
			}

			if (child_before.display_weight > child_after.display_weight) {
				return 1;
			} else if (child_before.display_weight < child_after.display_weight) {
				return -1;
			}
			return 0;
		}

		/**
		* Emulate sidebar activation for the user
		*/
		void force_select_page(string content_id) {
			Idle.add(() => {
				Gtk.ListBoxRow? row = this.sidebar_map[content_id].get_parent() as Gtk.ListBoxRow;
				sidebar.select_row(row);
				row.grab_focus();
				content.set_visible_child_name(content_id);
				return false;
			});
		}

		/**
		* New panel added, let's make a page for it
		*/
		private void on_panel_added(string uuid, Budgie.Toplevel? toplevel) {
			string content_id = "panel-" + uuid;
			if (content_id in this.page_map) {
				return;
			}
			this.add_page(new PanelPage(this.manager, toplevel));
			if (new_panel_requested) {
				this.force_select_page(content_id);
			}
		}

		/**
		* A panel was destroyed, remove our knowledge of it
		*/
		private void on_panel_deleted(string uuid) {
			string content_id = "panel-" + uuid;

			/* TODO: Set the visible name to another panel that isn't the
			* one being deleted, only when already looking at the panel.
			*/
			if (this.content.get_visible_child_name() == content_id) {
				this.force_select_page("style");
			}

			/* Nuke from orbit */
			this.remove_page("panel-" + uuid);
		}
	}
}

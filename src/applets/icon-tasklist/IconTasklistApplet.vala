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

public class IconTasklist : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new IconTasklistApplet(uuid);
	}
}

[GtkTemplate (ui="/com/solus-project/icon-tasklist/settings.ui")]
public class IconTasklistSettings : Gtk.Grid {
	[GtkChild]
	private unowned Gtk.Switch? switch_grouping;

	[GtkChild]
	private unowned Gtk.Switch? switch_restrict;

	[GtkChild]
	private unowned Gtk.Switch? switch_lock_icons;

	[GtkChild]
	private unowned Gtk.Switch? switch_only_pinned;

	[GtkChild]
	private unowned Gtk.Switch? show_all_on_click;

	[GtkChild]
	private unowned Gtk.Switch? switch_middle_click_create_new_instance;

	[GtkChild]
	private unowned Gtk.Switch? switch_require_double_click_to_launch_new_instance;

	private Settings? settings;

	public IconTasklistSettings(Settings? settings) {
		this.settings = settings;
		settings.bind("grouping", switch_grouping, "active", SettingsBindFlags.DEFAULT);
		settings.bind("restrict-to-workspace", switch_restrict, "active", SettingsBindFlags.DEFAULT);
		settings.bind("lock-icons", switch_lock_icons, "active", SettingsBindFlags.DEFAULT);
		settings.bind("only-pinned", switch_only_pinned, "active", SettingsBindFlags.DEFAULT);
		settings.bind("show-all-windows-on-click", show_all_on_click, "active", SettingsBindFlags.DEFAULT);
		settings.bind("middle-click-launch-new-instance", switch_middle_click_create_new_instance, "active", SettingsBindFlags.DEFAULT);
		settings.bind("require-double-click-to-launch", switch_require_double_click_to_launch_new_instance, "active", SettingsBindFlags.DEFAULT);
	}
}

public class IconTasklistApplet : Budgie.Applet {
	private Budgie.Abomination.Abomination? abomination = null;
	private Wnck.Screen? wnck_screen = null;
	private Settings? settings = null;
	private Gtk.Box? main_layout = null;

	private bool grouping = true;
	private bool restrict_to_workspace = false;
	private bool only_show_pinned = false;

	/**
	 * Avoid inserting/removing/updating the hashmap directly and prefer using
	 * add_button and remove_button that provide thread safety.
	 */
	private HashTable<string,IconButton> buttons;

	/* Applet support */
	private DesktopHelper? desktop_helper = null;
	private Budgie.AppSystem? app_system = null;
	private unowned Budgie.PopoverManager? manager = null;

	public string uuid { public set; public get; }

	public override Gtk.Widget? get_settings_ui() {
		return new IconTasklistSettings(this.get_applet_settings(uuid));
	}

	public override bool supports_settings() {
		return true;
	}

	public IconTasklistApplet(string uuid) {
		Object(uuid: uuid);

		/* Get our settings working first */
		this.settings_schema = "com.solus-project.icon-tasklist";
		this.settings_prefix = "/com/solus-project/budgie-panel/instance/icon-tasklist";
		this.settings = this.get_applet_settings(uuid);

		/* Somewhere to store the window mappings */
		this.buttons = new HashTable<string,IconButton>(str_hash, str_equal);
		this.main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		/* Initial bootstrap of helpers */
		this.desktop_helper = new DesktopHelper(this.settings, this.main_layout);
		this.wnck_screen = Wnck.Screen.get_default();
		this.abomination = new Budgie.Abomination.Abomination();
		this.app_system = new Budgie.AppSystem();

		/* Now hook up settings */
		this.settings.changed.connect(this.on_settings_changed);

		this.add(this.main_layout);

		Gtk.drag_dest_set(this.main_layout, Gtk.DestDefaults.ALL, DesktopHelper.targets, Gdk.DragAction.COPY);
		this.main_layout.drag_data_received.connect(this.on_drag_data_received);

		this.on_settings_changed("grouping");
		this.on_settings_changed("restrict-to-workspace");
		this.on_settings_changed("lock-icons");
		this.on_settings_changed("only-pinned");

		this.connect_app_signals();
		this.on_active_window_changed();

		this.get_style_context().add_class("icon-tasklist");
		this.show_all();
	}

	/**
	 * Our panel has moved somewhere, stash the positions
	 */
	public override void panel_position_changed(Budgie.PanelPosition position) {
		this.desktop_helper.panel_position = position;
		this.desktop_helper.orientation = this.get_orientation();
		this.main_layout.set_orientation(this.desktop_helper.orientation);

		this.set_icons_size();
	}

	/**
	 * Our panel has changed size, record the new icon sizes
	 */
	public override void panel_size_changed(int panel, int icon, int small_icon) {
		this.desktop_helper.icon_size = small_icon;
		this.desktop_helper.panel_size = panel;
		this.set_icons_size();
	}

	public override void update_popovers(Budgie.PopoverManager? manager) {
		this.manager = manager;
	}

	/**
	 * Add IconButton for pinned apps
	 */
	private void startup() {
		string[] pinned = this.settings.get_strv("pinned-launchers");

		foreach (string launcher in pinned) {
			DesktopAppInfo? info = new DesktopAppInfo(launcher);
			if (info == null) {
				continue;
			}

			IconButton button = new IconButton(this.abomination, this.app_system, this.settings, this.desktop_helper, this.manager, info, true);
			this.add_icon_button(launcher, button);
		}
	}

	private void connect_app_signals() {
		this.wnck_screen.active_window_changed.connect_after(this.on_active_window_changed);
		this.wnck_screen.active_workspace_changed.connect_after(this.update_buttons);

		this.abomination.added_app.connect((group, app) => this.on_app_opened(app));
		this.abomination.removed_app.connect((group, app) => this.on_app_closed(app));

		if (!this.grouping) { // remaining logic is only needed for grouping
			return;
		}

		this.abomination.updated_group.connect((group) => { // try to properly group icons
			Wnck.Window window = group.get_windows().nth_data(0);
			if (window == null) {
				return;
			}

			Budgie.Abomination.RunningApp app = this.abomination.get_app_from_window_id(window.get_xid());
			if (app == null) {
				return;
			}

			IconButton button = this.buttons.get(window.get_xid().to_string());

			if (button == null && app.app_info != null) { // Button might be pinned, try to get button from launcher instead
				string launcher = this.get_app_launcher(app.app_info.get_filename());
				button = this.buttons.get(launcher);
			}

			if (button == null) { // we don't manage this button
				return;
			}

			ButtonWrapper wrapper = (button.get_parent() as ButtonWrapper);
			if (wrapper == null) {
				return;
			}

			wrapper.gracefully_die();

			this.remove_button(window.get_xid().to_string());
			this.on_app_opened(app);
		});
	}

	/**
	 * Remove every IconButton and add them back
	 */
	private void rebuild_items() {
		foreach (Gtk.Widget widget in this.main_layout.get_children()) {
			widget.destroy();
		}

		this.buttons.remove_all();

		this.startup();

		this.abomination.get_running_apps().foreach(this.on_app_opened); // for each running apps
	}

	private void on_settings_changed(string key) {
		switch (key) {
			case "grouping":
				this.grouping = this.settings.get_boolean(key);
				Idle.add(() => {
					this.rebuild_items();
					return false;
				});
				break;
			case "lock-icons":
				this.desktop_helper.lock_icons = this.settings.get_boolean(key);
				break;
			case "restrict-to-workspace":
				this.restrict_to_workspace = this.settings.get_boolean(key);
				break;
			case "only-pinned":
				this.only_show_pinned = this.settings.get_boolean(key);
				break;
		}
		if (key != "grouping") {
			this.update_buttons();
		}
	}

	private void update_buttons() {
		this.buttons.foreach((id, button) => {
			this.update_button(button);
		});
	}

	private void on_drag_data_received(Gtk.Widget widget, Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint item, uint time) {
		if (item != 0) {
			message("Invalid target type");
			return;
		}

		// id of app that is currently being dragged
		var app_id = (string)selection_data.get_data();
		ButtonWrapper? original_button = null;

		if (app_id.has_prefix("file://")) {
			app_id = app_id.split("://")[1];
			app_id = app_id.strip();

			DesktopAppInfo? info = new DesktopAppInfo.from_filename(app_id);
			if (info == null) {
				return;
			}

			if (info.get_startup_wm_class() == "budgie-desktop-settings") { // Is Budgie Desktop Settings
				return; // Don't allow drag & drop
			}

			string launcher = this.get_app_launcher(app_id);

			if (this.buttons.contains(launcher)) {
				original_button = (this.buttons[launcher].get_parent() as ButtonWrapper);
			} else {
				IconButton button = new IconButton(this.abomination, this.app_system, this.settings, this.desktop_helper, this.manager, info, true);
				this.add_icon_button(launcher, button);
				original_button = button.get_parent() as ButtonWrapper;
			}
		} else { // Doesn't start with file://
			unowned IconButton? button = null;

			if (this.buttons.contains(app_id)) { // If buttons contains this app_id
				button = this.buttons.get(app_id);
			}

			if (button != null) {
				original_button = button.get_parent() as ButtonWrapper;
			}
		}

		if (original_button == null) {
			return;
		}

		// Iterate through launchers
		foreach (Gtk.Widget widget1 in this.main_layout.get_children()) {
			ButtonWrapper current_button = (widget1 as ButtonWrapper);

			Gtk.Allocation alloc;

			current_button.get_allocation(out alloc);

			if ((this.get_orientation() == Gtk.Orientation.HORIZONTAL && x <= (alloc.x + (alloc.width / 2))) ||
				(this.get_orientation() == Gtk.Orientation.VERTICAL && y <= (alloc.y + (alloc.height / 2)))) {
				int new_position, old_position;
				this.main_layout.child_get(original_button, "position", out old_position, null);
				this.main_layout.child_get(current_button, "position", out new_position, null);

				if (new_position == old_position) {
					break;
				}

				if (new_position == old_position + 1) {
					break;
				}

				if (new_position > old_position) {
					new_position = new_position - 1;
				}

				this.main_layout.reorder_child(original_button, new_position);
				break;
			}

			if ((this.get_orientation() == Gtk.Orientation.HORIZONTAL && x <= (alloc.x + alloc.width)) ||
				(this.get_orientation() == Gtk.Orientation.VERTICAL && y <= (alloc.y + alloc.height))) {
				int new_position, old_position;
				this.main_layout.child_get(original_button, "position", out old_position, null);
				this.main_layout.child_get(current_button, "position", out new_position, null);

				if (new_position == old_position) {
					break;
				}

				if (new_position == old_position - 1) {
					break;
				}

				if (new_position < old_position) {
					new_position = new_position + 1;
				}

				this.main_layout.reorder_child(original_button, new_position);
				break;
			}
		}
		original_button.set_transition_type(Gtk.RevealerTransitionType.NONE);
		original_button.set_reveal_child(true);

		this.desktop_helper.update_pinned();

		Gtk.drag_finish(context, true, true, time);
	}

	/**
	 * on_app_opened handles when we open a new app
	 */
	private void on_app_opened(Budgie.Abomination.RunningApp app) {
		Budgie.Abomination.RunningApp first_app = this.abomination.get_first_app_of_group(app.get_group_name());
		if (first_app == null) {
			return;
		}

		string first_app_id = first_app.id.to_string();
		if (app.app_info != null) { // properly group new apps with their pinned version
			string launcher = this.get_app_launcher(app.app_info.get_filename());
			if (this.buttons.contains(launcher) && this.buttons.get(launcher).pinned) {
				first_app_id = launcher;
			}
		} else {
			warning("No app info");
		}

		// Trigger an animation when a new instance of a window is launched while another is already open
		if (this.buttons.contains(first_app_id) && this.grouping) {
			IconButton first_button = this.buttons.get(first_app_id);
			if (!first_button.icon.waiting && first_button.icon.get_realized()) {
				first_button.icon.waiting = true;
				first_button.icon.animate_wait();
			}
		}

		IconButton button = null;
		if (this.buttons.contains(first_app_id)) { // try to get existing button if any
			button = this.buttons.get(first_app_id);

			if (!this.grouping && !button.is_empty()) {
				button = null; // pinned button is already associated with a window, we'll create a new one
			}

			if (button != null) {
				this.add_button(app.id.to_string(), button); // map app to it's button so that we can update it later on
			}
		}

		if (button == null) { // create a new button
			if (!this.grouping) {
				button = new IconButton.from_app(this.abomination, this.app_system, this.settings, this.desktop_helper, this.manager, app, false);
			} else {
				button = new IconButton.from_group(this.abomination, this.app_system, this.settings, this.desktop_helper, this.manager, app.group_object, false);
			}
			this.add_icon_button(app.id.to_string(), button);
		}

		if (this.grouping && button.get_class_group() == null) { // button was pinned without app opened, set class group in button to properly group windows
			button.set_class_group(app.group_object);
		}

		if (!this.grouping && button.is_empty()) { // button was pinned without app opened
			button.set_wnck_window(app.get_window());
		}

		button.update();
	}

	private void on_app_closed(Budgie.Abomination.RunningApp app) {
		if (app.get_window().is_skip_pager() || app.get_window().is_skip_tasklist()) { // window not managed in the first place
			return;
		}

		IconButton? button = this.buttons.get(app.id.to_string());

		if (button == null && app.app_info != null) { // Button might be pinned, try to get button from launcher instead
			string launcher = this.get_app_launcher(app.app_info.get_filename());
			button = this.buttons.get(launcher);
		}

		if (button == null) { // we don't manage this button
			return;
		}

		if (button.get_class_group() != null && button.get_class_group().get_windows().length() == 0) { // when we don't have windows in the group anymore, it's safe to remove the group
			button.set_class_group(null);
		}

		button.set_wnck_window(null);
		button.update();

		this.remove_button(app.id.to_string());
	}

	private void on_active_window_changed() {
		foreach (IconButton button in this.buttons.get_values()) {
			if (button.has_window(this.desktop_helper.get_active_window())) {
				button.last_active_window = this.desktop_helper.get_active_window();
				button.attention(false);
			}
			button.update();
		}
	}


	private void set_icons_size() {
		Wnck.set_default_icon_size(this.desktop_helper.icon_size);

		Idle.add(() => {
			this.buttons.foreach((id, button) => {
				button.update_icon();
			});
			return false;
		});

		this.queue_resize();
		this.queue_draw();
	}

	/**
	 * Return our orientation in relation to the panel position
	 */
	private Gtk.Orientation get_orientation() {
		switch (this.desktop_helper.panel_position) {
			case Budgie.PanelPosition.TOP:
			case Budgie.PanelPosition.BOTTOM:
				return Gtk.Orientation.HORIZONTAL;
			default:
				return Gtk.Orientation.VERTICAL;
		}
	}

	private void add_icon_button(string app_id, IconButton button) {
		this.add_button(app_id, button); // map app to it's button so that we can update it later on

		ButtonWrapper wrapper = new ButtonWrapper(button);
		wrapper.orient = this.get_orientation();

		// Kill button when there are no window left and its not pinned
		button.became_empty.connect(() => {
			if (!button.pinned) {
				if (wrapper != null) {
					wrapper.gracefully_die();
				}

				this.remove_button(app_id);
			}
		});

		// when button become pinned, make sure we identify it by its launcher instead of xid or grouping will fail
		button.pinned_changed.connect(() => {
			if (button.first_app == null) {
				return;
			}

			string[] parts = button.first_app.app_info.get_filename().split("/");
			string launcher = parts[parts.length - 1];
			if (button.pinned) {
				this.add_button(launcher, button);
				this.remove_button(button.first_app.id.to_string());
			} else {
				this.add_button(button.first_app.id.to_string(), button);
				this.remove_button(launcher);
			}
		});

		this.main_layout.add(wrapper);
		this.show_all();
		this.update_button(button);
	}

	private void update_button(IconButton button) {
		bool visible = true;

		if (this.restrict_to_workspace) { // Only show apps on this workspace
			var workspace = this.wnck_screen.get_active_workspace();
			if (workspace == null) {
				return;
			}

			visible = button.has_window_on_workspace(workspace); // Set if the button is pinned and on workspace
		}

		if (this.only_show_pinned) {
			visible = button.is_pinned();
		}

		visible = visible || button.is_pinned();

		((ButtonWrapper) button.get_parent()).orient = this.get_orientation();
		((Gtk.Revealer) button.get_parent()).set_reveal_child(visible);
		button.update();
	}

	/**
	 * Ensure that we don't access the resource simultaneously when adding new buttons.
	 */
	private void add_button(string key, IconButton button) {
		lock(this.buttons) {
			this.buttons.insert(key, button);
		}
	}

	/**
	 * Ensure that we don't access the resource simultaneously when removing a button.
	 */
	private void remove_button(string key) {
		lock(this.buttons) {
			this.buttons.remove(key);
		}
	}

	private string get_app_launcher(string app_id) {
		string[] parts = app_id.split("/");
		return parts[parts.length - 1];
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(IconTasklist));
}

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
	private Budgie.Abomination? abomination = null;
	private Wnck.Screen? wnck_screen = null;
	private Settings? settings = null;
	private HashTable<string,IconButton> buttons;
	private HashTable<string,string> id_map;
	private Gtk.Box? main_layout = null;
	private bool grouping = true;
	private bool restrict_to_workspace = false;
	private bool only_show_pinned = false;

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
		this.id_map = new HashTable<string,string>(str_hash, str_equal);
		this.main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		/* Initial bootstrap of helpers */
		this.desktop_helper = new DesktopHelper(this.settings, this.main_layout);
		this.wnck_screen = Wnck.Screen.get_default();
		this.abomination = new Budgie.Abomination();
		this.app_system = new Budgie.AppSystem();

		/* Now hook up settings */
		this.settings.changed.connect(this.on_settings_changed);

		this.add(this.main_layout);

		Gtk.drag_dest_set(this.main_layout, Gtk.DestDefaults.ALL, DesktopHelper.targets, Gdk.DragAction.COPY);
		this.main_layout.drag_data_received.connect(on_drag_data_received);

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
			this.buttons.insert(launcher, button); // map app to it's button so that we can update it later on
			this.add_icon_button(launcher, button);
		}
	}

	private void connect_app_signals() {
		this.wnck_screen.active_window_changed.connect_after(on_active_window_changed);
		this.wnck_screen.active_workspace_changed.connect_after(update_buttons);

		this.abomination.added_app.connect((group, app) => on_window_opened(app));
		this.abomination.removed_app.connect((group, app) => on_window_closed(app));

		this.abomination.update_group.connect((group) => {
			foreach (var window in group.get_windows()) {
				IconButton button = this.buttons.get(window.get_xid().to_string());
				button.first_app.group = group.get_name();

				// FIXME: button group isn't updated when group is renamed
			}
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

		this.abomination.running_apps_id.foreach((id, app) => { // For each running app
			this.on_window_opened(app);
		});
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
		warning("on_drag_data_received");

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

			string[] app_id_parts = app_id.split("/");
			string launcher = app_id_parts[app_id_parts.length - 1]; // remove the path parts to keep only the desktop file name

			if (this.buttons.contains(launcher)) {
				original_button = (this.buttons[launcher].get_parent() as ButtonWrapper);
			} else {
				//  FIXME: See if it cannot be deduped
				IconButton button = new IconButton(this.abomination, this.app_system, this.settings, this.desktop_helper, this.manager, info, true);
				button.update();

				this.buttons.set(launcher, button);
				original_button = new ButtonWrapper(button);
				original_button.orient = this.get_orientation();

				button.became_empty.connect(() => {
					if (!button.pinned) {
						this.buttons.remove(launcher);
						original_button.gracefully_die();
					}
				});
				this.main_layout.pack_start(original_button, false, false, 0);
			}
		} else { // Doesn't start with file://
			unowned IconButton? button = null;

			if (this.buttons.contains(app_id)) { // If buttons contains this app_id
				button = this.buttons.get(app_id);
			} else if (this.id_map.contains(app_id)) { // id_map contains the app
				button = this.buttons.get(this.id_map.get(app_id));
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
	 * on_window_opened handles when we open a new app / window
	 */
	private void on_window_opened(Budgie.AbominationRunningApp app) {
		//  warning("App %s has group: %s", app.name, (app.group_object != null).to_string());

		// FIXME: all this logic only work if grouping is enabled

		Budgie.AbominationRunningApp first_app = this.abomination.get_first_app_of_group(app.group);
		if (first_app == null) {
			return;
		}

		string first_app_id = first_app.id.to_string();
		if (app.app != null) { // properly group new apps with their pinned version
			string[] parts = app.app.get_filename().split("/");
			string launcher = parts[parts.length - 1];
			if (this.buttons.contains(launcher) && this.buttons.get(launcher).pinned) {
				first_app_id = launcher;
			}
		}

		//  Trigger an animation when a new instance of a window is launched while another is already open
		if (this.buttons.contains(first_app_id)) {
			IconButton first_button = this.buttons.get(first_app_id);
			if (!first_button.icon.waiting && first_button.icon.get_realized()) {
				first_button.icon.waiting = true;
				first_button.icon.animate_wait();
			}
		}

		this.id_map.insert(app.id.to_string(), app.id.to_string()); // keep track of opened window by their X ID

		IconButton button = null;
		if (this.grouping) { // try to get existing button if any
			button = this.buttons.get(first_app_id);
		}

		if (button == null) { // create a new button
			button = new IconButton.from_window(this.abomination, this.app_system, this.settings, this.desktop_helper, this.manager, app.window, app.app, false);
			this.add_icon_button(app.id.to_string(), button);
		}

		if (this.grouping) { // update button to show that we have multiple instances running
			button.set_class_group(app.group_object);
			button.update();
		}

		this.buttons.insert(app.id.to_string(), button); // map app to it's button so that we can update it later on
	}

	private void on_window_closed(Budgie.AbominationRunningApp app) {
		if (app.window.is_skip_pager() || app.window.is_skip_tasklist()) { // window not managed in the first place
			return;
		}

		IconButton? button = this.buttons.get(app.id.to_string());
		if (button == null) {
			return;
		}

		if (button.is_pinned() && this.grouping && app.group_object.get_windows().length() == 0) { // when we don't have windows in the group anymore, it's safe to remove the group
			button.set_class_group(null);
		}

		if (!button.is_pinned()) {
			button.set_wnck_window(null);
		}
		button.update();
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


	void set_icons_size() {
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
	 * Our panel has moved somewhere, stash the positions
	 */
	public override void panel_position_changed(Budgie.PanelPosition position) {
		this.desktop_helper.panel_position = position;
		this.desktop_helper.orientation = this.get_orientation();
		this.main_layout.set_orientation(this.desktop_helper.orientation);

		set_icons_size();
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
		ButtonWrapper wrapper = new ButtonWrapper(button);
		wrapper.orient = this.get_orientation();

		button.became_empty.connect(() => {
			if (!button.pinned) {
				if (wrapper != null) {
					wrapper.gracefully_die();
				}

				this.buttons.remove(app_id);
				this.id_map.remove(app_id);
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
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(IconTasklist));
}

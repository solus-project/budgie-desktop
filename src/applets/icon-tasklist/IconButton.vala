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

const double DEFAULT_OPACITY = 0.1;
const int INDICATOR_SIZE = 2;
const int INDICATOR_SPACING = 1;
const int INACTIVE_INDICATOR_SPACING = 2;

/**
 * IconButton provides the pretty IconTasklist button to house one or more
 * windows in a group, as well as selection capabilities, interaction, animations
 * and rendering of "dots" for the renderable windows.
 */
public class IconButton : Gtk.ToggleButton {
	public Budgie.AbominationRunningApp? first_app = null;
	private Budgie.IconPopover? popover = null;
	private Wnck.Screen? screen = null;
	private Settings? settings = null;
	private Wnck.Window? window = null; // This will always be null if grouping is enabled
	private Wnck.ClassGroup? class_group = null; // This will always be null if grouping is disabled
	private DesktopAppInfo? app_info = null;
	private int window_count = 0;
	public Icon icon;
	private Gtk.Allocation definite_allocation;
	public bool pinned = false;
	private bool is_from_window = false;
	private bool originally_pinned = false;
	private Gdk.AppLaunchContext launch_context;
	private int64 last_scroll_time = 0;
	public Wnck.Window? last_active_window = null;
	private bool needs_attention = false;
	public signal void became_empty();

	public unowned Budgie.Abomination? abomination { public set; public get; default = null; }
	public unowned Budgie.AppSystem? app_system { public set; public get; default = null; }
	public unowned DesktopHelper? desktop_helper { public set; public get; default = null; }
	public unowned Budgie.PopoverManager? popover_manager { public set; public get; default = null; }

	public IconButton(Budgie.Abomination? ab, Budgie.AppSystem? appsys, Settings? c_settings, DesktopHelper? helper, Budgie.PopoverManager? manager, DesktopAppInfo info, bool pinned) {
		Object(abomination: ab, app_system: appsys, desktop_helper: helper, popover_manager: manager);
		this.settings = c_settings;
		this.app_info = info;
		this.pinned = pinned;
		this.originally_pinned = pinned;
		gobject_constructors_suck();
		create_popover(); // Create our popover

		update_icon();

		if (has_valid_windows(null)) {
			this.get_style_context().add_class("running");
		}
	}

	public IconButton.from_window(Budgie.Abomination? ab, Budgie.AppSystem? appsys, Settings? c_settings, DesktopHelper? helper, Budgie.PopoverManager? manager, Wnck.Window window, DesktopAppInfo? info, bool pinned = false) {
		Object(abomination: ab, app_system: appsys, desktop_helper: helper, popover_manager: manager);
		this.settings = c_settings;
		this.app_info = info;
		this.is_from_window = true;
		this.pinned = pinned;
		this.originally_pinned = pinned;
		this.first_app = new Budgie.AbominationRunningApp(app_system, window);

		if (this.first_app != null && this.first_app.app != null && this.app_info == null) { // Didn't get passed a valid DesktopAppInfo but got one from AbominationRunningApp
			this.app_info = this.first_app.app;
		}

		this.first_app.name_changed.connect(() => { // When the name of the app has changed
			set_tooltip(); // Update our tooltip
		});

		gobject_constructors_suck();

		window.state_changed.connect_after(() => {
			if (window.needs_attention()) {
				attention();
			}
		});

		update_icon();

		if (has_valid_windows(null)) {
			this.get_style_context().add_class("running");
		}

		create_popover(); // Create our popover
		this.set_wnck_window(window);
	}

	public IconButton.from_group(Budgie.Abomination? ab, Budgie.AppSystem? appsys, Settings? c_settings, DesktopHelper? helper, Budgie.PopoverManager? manager, Wnck.ClassGroup class_group, DesktopAppInfo? info) {
		Object(abomination: ab, app_system: appsys, desktop_helper: helper, popover_manager: manager);

		this.settings = c_settings;
		this.class_group = class_group;
		this.app_info = info;
		this.pinned = false;
		this.originally_pinned = false;

		gobject_constructors_suck();
		create_popover(); // Create our popover
		setup_popover_with_class(); // Set up our Popover with info from the Wnck.ClassGroup

		update_icon();

		if (has_valid_windows(null)) {
			this.get_style_context().add_class("running");
			set_app_for_class_group();
		}
	}

	/**
	 * We have race conditions in glib between the desired properties..
	 */
	private void gobject_constructors_suck() {
		icon = new Icon();
		icon.get_style_context().add_class("icon");
		this.add(icon);

		enter_notify_event.connect(() => {
			this.set_tooltip(); // Update our tooltip
			this.queue_draw(); // Redraw tooltip
			return false;
		});

		leave_notify_event.connect(() => {
			this.set_tooltip_text(""); // Clear it
			this.has_tooltip = false;
			return false;
		});

		definite_allocation.width = 0;
		definite_allocation.height = 0;

		this.launch_context = this.get_display().get_app_launch_context();
		this.add_events(Gdk.EventMask.SCROLL_MASK);
		this.set_draggable(!this.desktop_helper.lock_icons);

		drag_begin.connect((context) => {
			switch (this.icon.get_storage_type()) {
				case Gtk.ImageType.PIXBUF:
					Gtk.drag_set_icon_pixbuf(context, icon.get_pixbuf(), icon.pixel_size / 2, icon.pixel_size / 2);
					break;
				case Gtk.ImageType.ICON_NAME:
					unowned string? icon_name = null;
					icon.get_icon_name(out icon_name, null);
					Gtk.drag_set_icon_name(context, icon_name, icon.pixel_size / 2, icon.pixel_size / 2);
					break;
				case Gtk.ImageType.GICON:
					unowned GLib.Icon? gicon = null;
					icon.get_gicon(out gicon, null);
					Gtk.drag_set_icon_gicon(context, gicon, icon.pixel_size / 2, icon.pixel_size / 2);
					break;
				default:
					/* No icon */
					Gtk.drag_set_icon_default(context);
					break;
			}
		});

		drag_data_get.connect((widget, context, selection_data, info, time) => {
			string id = "";
			if (this.is_from_window) { // If this is from a window
				if (this.pinned && this.originally_pinned) { // Has been pinned from the start
					if (this.app_info != null) {
						id = this.app_info.get_id();
					} else {
						id = this.window.get_name();
					}
				} else { // If this hasn't been pinned from the start
					if (this.app_info != null && this.first_app != null) {
						id = "%s|%lu".printf(this.app_info.get_id(), this.first_app.id);
					} else if (this.app_info == null && this.first_app != null) {
						id = "%s|%lu".printf(this.first_app.group, this.first_app.id);
					}
				}
			} else { // If this is from a group
				if (this.app_info != null) {
					id = this.app_info.get_id();
				} else if (this.first_app != null) {
					id = this.first_app.group;
				}
			}

			if (id == "" && this.window != null) { // If id isn't set
			  id = this.window.get_name(); // Just use name
			}

			selection_data.set(selection_data.get_target(), 8, (uchar[])id.to_utf8());
		});

		var st = get_style_context();
		st.remove_class(Gtk.STYLE_CLASS_BUTTON);
		st.remove_class("toggle");
		st.add_class("launcher");
		this.relief = Gtk.ReliefStyle.NONE;

		size_allocate.connect(this.on_size_allocate);
		launch_context.launched.connect(this.on_launched);
		launch_context.launch_failed.connect(this.on_launch_failed);
	}

	/**
	 * create_popover will create our popover
	 */
	public void create_popover() {
		this.screen = Wnck.Screen.get_default(); // Get the default screen
		this.popover = new Budgie.IconPopover(this, this.app_info, screen.get_workspace_count());
		this.popover.set_pinned_state(this.pinned); // Set our pinned state

		this.popover.launch_new_instance.connect(() => { // If we're going to launch a new instance
			launch_app(Gtk.get_current_event_time());
		});

		this.popover.added_window.connect(() => { // If we added a window
			window_count++;
		});

		this.popover.closed_all.connect(() => { // If we closed all windows
			window_count = 0;
			this.popover.hide(); // Hide
			became_empty(); // Call our became empty function
		});

		this.popover.closed_window.connect(() => { // If we closed a window related to this popover
			window_count--;
		});

		this.popover.changed_pin_state.connect((new_pinned_state) => { // On changed pinned state
			this.pinned = new_pinned_state;
			this.desktop_helper.update_pinned(); // Update via desktop helper

			if (!has_valid_windows(null)) { // Does not have any windows open and no longer pinned
				became_empty(); // Trigger our became_empty event (for removal)
			}
		});

		this.popover.move_window_to_workspace.connect((xid, wid) => { // On a request to move a window to a workspace
			Wnck.Window requested_window = Wnck.Window.@get(xid);
			Wnck.Workspace workspace = this.screen.get_workspace(wid - 1);

			if ((requested_window != null) && (workspace != null)) {
				requested_window.move_to_workspace(workspace);
			}
		});

		this.popover.perform_action.connect((action) => {
			if (this.app_info != null) {
				launch_context.set_screen(get_screen());
				launch_context.set_timestamp(Gdk.CURRENT_TIME);
				this.app_info.launch_action(action, launch_context);
				popover.render(); // Re-render
			}
		});

		/**
		 * Wnck bits that are relevant to the popover
		 */

		this.screen.window_opened.connect((new_window) => { // When a window is opened
			if (new_window == null) {
				return;
			}

			if (abomination.is_disallowed_window_type(new_window)) {
				return;
			}

			Wnck.ClassGroup window_class_group = new_window.get_class_group();

			if ((this.class_group != null) && (window_class_group != null)) {
				if (should_add_window(new_window)) {
					ulong xid = new_window.get_xid();
					string name = new_window.get_name() ?? "Loading...";

					this.popover.add_window(xid, name); // Add the window
					new_window.name_changed.connect(() => { // When this window is renamed
						this.popover.rename_window(xid); // Rename its entry in the popover
					});
				}
			}
		});

		this.screen.window_closed.connect((old_window) => { // When a window is close
			this.popover.remove_window(old_window.get_xid()); // Remove from popover if it exists

			if (this.first_app != null) { // If we have an AbominationRunningApp associated with this
				this.first_app.invalidate_window(old_window); // See if we need to invalidate this window and update our new one (if any)
			}
		});

		this.screen.workspace_created.connect((workspace) => { // When we've added a workspace
			this.popover.set_workspace_count(screen.get_workspace_count());
		});

		this.screen.workspace_destroyed.connect((workspace) => { // When we've removed a workspace
			this.popover.set_workspace_count(screen.get_workspace_count());
		});

		this.popover_manager.register_popover(this, popover); // Register
	}

	public void set_class_group(Wnck.ClassGroup? class_group) {
		this.class_group = class_group;

		if (class_group == null) {
			return;
		}

		class_group.icon_changed.connect_after(() => {
			update_icon(); // Update icon based on class group
		});

		set_app_for_class_group();
		setup_popover_with_class();
	}

	public void set_wnck_window(Wnck.Window? window) {
		this.window = window;

		if (window == null) {
			return;
		}

		if (abomination.is_disallowed_window_type(window)) {
			return;
		}

		window.icon_changed.connect_after(() => {
			update_icon(); // Update the icon
		});

		window.name_changed.connect_after(() => { // On window rename
			popover.rename_window(this.window.get_xid());
		});

		window.state_changed.connect_after(() => {
			if (window.needs_attention()) {
				attention();
			}
		});

		popover.add_window(window.get_xid(), window.get_name());
	}

	public void set_draggable(bool draggable) {
		if (draggable) {
			Gtk.drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, DesktopHelper.targets, Gdk.DragAction.COPY);
		} else {
			Gtk.drag_source_unset(this);
		}
	}

	/**
	 * should_add_window will return whether or not we should add this window to our popover
	 */
	private bool should_add_window(Wnck.Window new_window) {
		bool add = false;
		bool should_try_name_match = false;
		bool is_matching_class_name = false; // is_matching_class_name is for matching derpy window class names

		if (this.first_app != null) { // If we have an app defined
			Budgie.AbominationRunningApp app = new Budgie.AbominationRunningApp(app_system, new_window); // Create an abomination app
			if (this.first_app.group.has_prefix("chrome-") || this.first_app.group.has_prefix("google-chrome")) { // Is a Chrome or Chrome app
				should_try_name_match = true;
				is_matching_class_name = (this.first_app.group == app.group);
			} else if (this.first_app.group.has_prefix("libreoffice")) { // Is a LibreOffice window
				should_try_name_match = true;
				is_matching_class_name = (this.first_app.group == app.group);
			}
		}

		if (should_try_name_match) { // If we were doing class name check
			add = is_matching_class_name; // should_add_window based on if class name matches
		} else { // If we weren't doing class name check
			Wnck.ClassGroup window_class_group = new_window.get_class_group();
			add = this.class_group.get_id() == window_class_group.get_id(); // Perform ID check
		}

		return add;
	}

	public void update_icon() {
		if (has_valid_windows(null)) {
			this.icon.waiting = false;
		} else if (!this.pinned) {
			became_empty();
		}

		unowned GLib.Icon? app_icon = null;
		if (app_info != null) {
			app_icon = app_info.get_icon();
		}

		unowned Gdk.Pixbuf? pixbuf_icon = null;
		if (this.window != null) {
			pixbuf_icon = this.window.get_icon();
		}
		if (class_group != null) {
			pixbuf_icon = class_group.get_icon();
		}

		if (app_icon != null) {
			icon.set_from_gicon(app_icon, Gtk.IconSize.INVALID);
		} else if (pixbuf_icon != null) {
			icon.set_from_pixbuf(pixbuf_icon);
		} else {
			icon.set_from_icon_name("image-missing", Gtk.IconSize.INVALID);
		}

		icon.pixel_size = this.desktop_helper.icon_size;
	}

	public void update() {
		if (!has_valid_windows(null)) {
			this.get_style_context().remove_class("running");
			if (!this.pinned || this.is_from_window) {
				became_empty();
				return;
			} else {
				class_group = null;
			}
		} else {
			this.get_style_context().add_class("running");
		}

		bool has_active = false;
		if (this.window != null) {
			has_active = this.window.is_active();
		} else if (class_group != null) {
			has_active = (class_group.get_windows().find(this.desktop_helper.get_active_window()) != null);
		}
		this.set_active(has_active);

		set_tooltip(); // Update our tooltip text

		this.set_draggable(!this.desktop_helper.lock_icons);

		update_icon();
		this.queue_resize();
		this.queue_draw();
	}

	private bool has_valid_windows(out int num_windows) {
		num_windows = this.window_count;
		return (this.window_count != 0);
	}

	public bool has_window(Wnck.Window? window) {
		if (window == null) {
			return false;
		}

		if (this.window != null) {
			return (this.window == window);
		}

		if (class_group == null) {
			return false;
		}

		foreach (Wnck.Window win in class_group.get_windows()) {
			if (win == window) {
				return true;
			}
		}

		return false;
	}

	public bool has_window_on_workspace(Wnck.Workspace workspace) {
		if (workspace == null) {
			return false;
		}

		if (this.window != null) {
			return (!this.window.is_skip_tasklist() && this.window.is_on_workspace(workspace));
		} else if (class_group != null) {
			foreach (Wnck.Window win in class_group.get_windows()) {
				if (!win.is_skip_pager() && !win.is_skip_tasklist() && win.is_on_workspace(workspace)) {
					return true;
				}
			}
		}

		return false;
	}

	private void launch_app(uint32 time) {
		if (app_info == null) {
			return;
		}

		launch_context.set_screen(this.get_screen());
		launch_context.set_timestamp(time);

		this.icon.animate_launch(this.desktop_helper.panel_position);
		this.icon.waiting = true;
		this.icon.animate_wait();

		try {
			app_info.launch(null, launch_context);
		} catch (Error e) {
			warning(e.message);
		}
	}

	public bool is_empty() {
		return (this.window == null && class_group == null);
	}

	public bool is_pinned() {
		return pinned;
	}

	public void attention(bool needs_it = true) {
		this.needs_attention = needs_it;
		this.queue_draw();
		if (needs_it) {
			this.icon.animate_attention(this.desktop_helper.panel_position);
		}
	}

	/**
	 * set_tooltip will set the tooltip text for this IconButton
	 */
	public void set_tooltip() {
		if (this.window_count != 0) { // If we have valid windows open
			if (this.window_count == 1 && this.first_app != null) { // Only one window and a valid AbomationRunningApp for it
				this.set_tooltip_text(this.first_app.name);
			} else if (this.app_info != null) { // Has app info
				this.set_tooltip_text(this.app_info.get_display_name());
			} else if (this.window != null) {
				this.set_tooltip_text(this.window.get_name());
			}
		} else { // If we have no windows open
			if (this.app_info != null) {
				this.set_tooltip_text("Launch %s".printf(this.app_info.get_display_name()));
			} else if (this.class_group != null) { // Has class group
				this.set_tooltip_text(this.class_group.get_name());
			}
		}
	}

	/**
	 * Handle startup notification, set our own ID to the ID selected
	 */
	private void on_launched(AppInfo info, Variant v) {
		Variant? elem;

		var iter = v.iterator();

		while ((elem = iter.next_value()) != null) {
			string? key = null;
			Variant? val = null;

			elem.get("{sv}", out key, out val);

			if (key == null) {
				continue;
			}

			if (!val.is_of_type(VariantType.STRING)) {
				continue;
			}

			if (key != "startup-notification-id") {
				continue;
			}

			this.get_display().notify_startup_complete(val.get_string());
		}
	}

	private void on_launch_failed(string id) {
		warning("launch_failed");
		this.get_display().notify_startup_complete(id);
	}

	public void draw_inactive(Cairo.Context cr, Gdk.RGBA col) {
		int x = definite_allocation.x;
		int y = definite_allocation.y;
		int width = definite_allocation.width;
		int height = definite_allocation.height;
		List<unowned Wnck.Window> windows;

		if (class_group != null) {
			windows = class_group.get_windows().copy();
		} else {
			windows = new List<unowned Wnck.Window>();
			windows.insert(this.window, 0);
		}

		int count;
		if (!this.has_valid_windows(out count)) {
			return;
		}

		count = (count > 5) ? 5 : count;

		int counter = 0;
		foreach (Wnck.Window window in windows) {
			if (counter == count) {
				break;
			}

			if (!window.is_skip_pager() && !window.is_skip_tasklist()) {
				int indicator_x = 0;
				int indicator_y = 0;
				switch (this.desktop_helper.panel_position) {
					case Budgie.PanelPosition.TOP:
						indicator_x = x + (width / 2);
						indicator_x -= ((count * (INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING)) / 2) - INACTIVE_INDICATOR_SPACING;
						indicator_x += (((INDICATOR_SIZE) + INACTIVE_INDICATOR_SPACING) * counter);
						indicator_y = y + (INDICATOR_SIZE / 2);
						break;
					case Budgie.PanelPosition.BOTTOM:
						indicator_x = x + (width / 2);
						indicator_x -= ((count * (INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING)) / 2) - INACTIVE_INDICATOR_SPACING;
						indicator_x += (((INDICATOR_SIZE) + INACTIVE_INDICATOR_SPACING) * counter);
						indicator_y = y + height - (INDICATOR_SIZE / 2);
						break;
					case Budgie.PanelPosition.LEFT:
						indicator_y = x + (height / 2);
						indicator_y -= ((count * (INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING)) / 2) - (INACTIVE_INDICATOR_SPACING * 2);
						indicator_y += (((INDICATOR_SIZE) + INACTIVE_INDICATOR_SPACING) * counter);
						indicator_x = y + (INDICATOR_SIZE / 2);
						break;
					case Budgie.PanelPosition.RIGHT:
						indicator_y = x + (height / 2);
						indicator_y -= ((count * (INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING)) / 2) - INACTIVE_INDICATOR_SPACING;
						indicator_y += ((INDICATOR_SIZE + INACTIVE_INDICATOR_SPACING) * counter);
						indicator_x = y + width - (INDICATOR_SIZE / 2);
						break;
					default:
						break;
				}

				cr.set_source_rgba(col.red, col.green, col.blue, 1);
				cr.arc(indicator_x, indicator_y, INDICATOR_SIZE, 0, Math.PI * 2);
				cr.fill();
				counter++;
			}
		}
	}

	public override bool draw(Cairo.Context cr) {
		int x = definite_allocation.x;
		int y = definite_allocation.y;
		int width = definite_allocation.width;
		int height = definite_allocation.height;
		List<unowned Wnck.Window> windows;

		if (class_group != null) {
			windows = class_group.get_windows().copy();
		} else {
			windows = new List<unowned Wnck.Window>();
			windows.insert(this.window, 0);
		}

		int count;
		if (!this.has_valid_windows(out count)) {
			return base.draw(cr);
		}

		count = (count > 5) ? 5 : count;

		Gtk.StyleContext context = this.get_style_context();

		Gdk.RGBA col;
		if (!context.lookup_color("budgie_tasklist_indicator_color", out col)) {
			col.parse("#3C6DA6");
		}

		if (this.get_active()) {
			if (!context.lookup_color("budgie_tasklist_indicator_color_active", out col)) {
				col.parse("#5294E2");
			}
		} else {
			if (this.needs_attention) {
				if (!context.lookup_color("budgie_tasklist_indicator_color_attention", out col)) {
					col.parse("#D84E4E");
				}
			}
			draw_inactive(cr, col);
			return base.draw(cr);
		}

		int counter = 0;
		int previous_x = 0;
		int previous_y = 0;
		int spacing = width % count;
		spacing = (spacing == 0) ? 1 : spacing;
		foreach (Wnck.Window window in windows) {
			if (counter == count) {
				break;
			}

			if (!window.is_skip_tasklist()) {
				int indicator_x = 0;
				int indicator_y = 0;
				switch (this.desktop_helper.panel_position) {
					case Budgie.PanelPosition.TOP:
						if (counter == 0) {
							indicator_x = x;
						} else {
							previous_x = indicator_x = previous_x + (width/count);
							indicator_x += spacing;
						}
						indicator_y = y;
						break;
					case Budgie.PanelPosition.BOTTOM:
						if (counter == 0) {
							indicator_x = x;
						} else {
							previous_x = indicator_x = previous_x + (width/count);
							indicator_x += spacing;
						}
						indicator_y = y + height;
						break;
					case Budgie.PanelPosition.LEFT:
						if (counter == 0) {
							indicator_y = y;
						} else {
							previous_y = indicator_y = previous_y + (height/count);
							indicator_y += spacing;
						}
						indicator_x = x;
						break;
					case Budgie.PanelPosition.RIGHT:
						if (counter == 0) {
							indicator_y = y;
						} else {
							previous_y = indicator_y = previous_y + (height/count);
							indicator_y += spacing;
						}
						indicator_x = x + width;
						break;
					default:
						break;
				}

				cr.set_line_width(6);
				if (this.desktop_helper.get_active_window() == window && count > 1) {
					Gdk.RGBA col2 = col;
					if (!context.lookup_color("budgie_tasklist_indicator_color_active_window", out col2)) {
						col2.parse("#6BBFFF");
					}
					cr.set_source_rgba(col2.red, col2.green, col2.blue, 1);
				} else {
					cr.set_source_rgba(col.red, col.green, col.blue, 1);
				}
				cr.move_to(indicator_x, indicator_y);

				switch (this.desktop_helper.panel_position) {
					case Budgie.PanelPosition.LEFT:
					case Budgie.PanelPosition.RIGHT:
						int to = 0;
						if (counter == count-1) {
							to = y + height;
						} else {
							to = previous_y+(height/count);
						}
						cr.line_to(indicator_x, to);
						break;
					default:
						int to = 0;
						if (counter == count-1) {
							to = x + width;
						} else {
							to = previous_x+(width/count);
						}
						cr.line_to(to, indicator_y);
						break;
				}

				cr.stroke();
				counter++;
			}
		}


		return base.draw(cr);
	}

	protected void on_size_allocate(Gtk.Allocation allocation) {
		definite_allocation = allocation;

		base.size_allocate(definite_allocation);

		int x, y;
		var toplevel = get_toplevel();
		if (toplevel == null || toplevel.get_window() == null) {
			return;
		}
		translate_coordinates(toplevel, 0, 0, out x, out y);
		toplevel.get_window().get_root_coords(x, y, out x, out y);

		if (this.window != null) {
			this.window.set_icon_geometry(x, y, definite_allocation.width, definite_allocation.height);
		} else if (class_group != null) {
			foreach (Wnck.Window win in class_group.get_windows()) {
				win.set_icon_geometry(x, y, definite_allocation.width, definite_allocation.height);
			}
		}
	}

	/**
	 * set_app_for_class_group will set our AbominationApp for the first window in a given class group, if there is any
	 */
	public void set_app_for_class_group() {
		if (this.first_app == null) { // Not already set
			unowned List<Wnck.Window> class_windows = this.class_group.get_windows();

			if (class_windows.length() != 0) { // Have windows in class group
				Wnck.Window first_window = class_windows.nth_data(0);

				if (first_window != null) {
					this.first_app = new Budgie.AbominationRunningApp(app_system, first_window);

					this.first_app.name_changed.connect(() => { // When the name of the app has changed
						set_tooltip(); // Update our tooltip
					});

					if (this.app_info == null) { // If app_info hasn't been set yet
						this.app_info = this.first_app.app; // Set to our first_app's DesktopAppInfo
					}
				}
			}
		}
	}

	/**
	 * setup_popover_with_class will set up our popover with windows from the class
	 */
	public void setup_popover_with_class() {
		if (this.first_app == null) {
			set_app_for_class_group();
		}

		foreach (unowned Wnck.Window window in this.class_group.get_windows()) {
			if (window != null) {
				if (!abomination.is_disallowed_window_type(window)) { // Not a disallowed window type
					if (should_add_window(window)) { // Should add this window
						ulong xid = window.get_xid();
						string name = window.get_name();

						popover.add_window(xid, name);
						window.name_changed.connect_after(() => {
							ulong win_xid = window.get_xid();
							popover.rename_window(win_xid);
						});

						window.state_changed.connect_after(() => {
							if (window.needs_attention()) {
								attention();
							}
						});
					}
				}
			}
		}
	}

	public override void get_preferred_width(out int min, out int nat) {
		if (this.desktop_helper.orientation == Gtk.Orientation.HORIZONTAL) {
			min = nat = this.desktop_helper.panel_size;
			return;
		} else {
			int m, n;
			base.get_preferred_width(out m, out n);
			min = m;
			nat = n;
		}
	}

	public override void get_preferred_height(out int min, out int nat) {
		if (this.desktop_helper.orientation == Gtk.Orientation.VERTICAL) {
			min = nat = this.desktop_helper.panel_size;
		} else {
			int m, n;
			base.get_preferred_height(out m, out n);
			min = m;
			nat = n;
		}
	}

	public override bool button_press_event(Gdk.EventButton event) {
		bool was_double_click = (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS);

		if (!was_double_click || (was_double_click && (event.button != 1))) { // Wasn't left click or was but not left
			return Gdk.EVENT_PROPAGATE; // Continue propagation
		}

		handle_launch_clicks(event, true); // Got this far, meaning double left clicked

		return base.button_press_event(event);
	}

	public override bool button_release_event(Gdk.EventButton event) {
		if (class_group != null && (last_active_window == null || class_group.get_windows().find(last_active_window) == null)) {
			last_active_window = class_group.get_windows().nth_data(0);
		}

		if (event.button == 3) { // Right click
			this.popover.render();
			this.popover_manager.show_popover(this); // Show the popover
			return Gdk.EVENT_STOP;
		} else if (event.button == 1) { // Left click
			handle_launch_clicks(event, false);
		} else if (event.button == 2) { // Middle click
			List<unowned Wnck.Window> windows;
			bool middle_click_create_new_instance = false;

			if (this.settings != null) { // Settings defined
				middle_click_create_new_instance = this.settings.get_boolean("middle-click-launch-new-instance");
			}

			if (middle_click_create_new_instance) {
				if (class_group != null) {
					windows = class_group.get_windows().copy();
				} else {
					windows = new List<unowned Wnck.Window>();
				}

				if (windows.length() == 0) {
					launch_app(Gtk.get_current_event_time());
				} else if (this.app_info != null) {
					string[] actions = app_info.list_actions();

					if ("new-window" in actions) { // If we have a preferred action set
						launch_context.set_screen(get_screen());
						launch_context.set_timestamp(Gdk.CURRENT_TIME);
						this.app_info.launch_action("new-window", launch_context);
					} else {
						launch_app(Gtk.get_current_event_time());
					}
				}
			}
		}

		return base.button_release_event(event);
	}

	private void handle_launch_clicks(Gdk.EventButton event, bool was_double_click) {
		bool should_launch_app = false;

		if (this.window != null) {
			if (this.window.is_active()) {
				this.window.minimize();
			} else {
				this.window.unminimize(event.time);
				this.window.activate(event.time);
			}
		} else if (class_group != null) {
			bool one_active = false; // Determine if one of our windows is active so we know if we should show all or hide all if that setting is enabled
			Wnck.Workspace active_workspace = screen.get_active_workspace(); // Get the active workspace

			GLib.List<unowned Wnck.Window> list = new List<unowned Wnck.Window>();
			List<weak ulong?> win_ids = this.popover.window_id_to_name.get_keys(); // Get all the window ids regardless of workspace state

			foreach (ulong id in win_ids) { // For each window ID
				Wnck.Window? win = Wnck.Window.@get(id); // Get the window

				if (win == null) { // Window doesn't exist
					continue; // Skip it
				}

				list.append(win); // Add to our list
			}

			foreach (Wnck.Window win in list) {
				if (win.is_active()) { // if the window is active
					one_active = true;
					break;
				}
			}

			uint len = list.length();

			bool show_all_windows_on_click = false;

			if (this.settings != null) { // Settings defined
				show_all_windows_on_click = this.settings.get_boolean("show-all-windows-on-click");
			}

			if ((len == 1) || (len > 1 && !show_all_windows_on_click)) { // Only one window or multiple but show all not enabled
				Wnck.Window only_window = list.nth_data(0); // Get the window

				if (!only_window.is_on_workspace(active_workspace)) { // If the window is not on this workspace
					Wnck.Workspace winspace = only_window.get_workspace(); // Get the window's workspace
					winspace.activate(event.time); // Make this the active workspace
					only_window.activate(event.time); // Activate the window
					only_window.unminimize(event.time); // Ensure we unminimize it
				} else { // Window is on this workspace, allow toggling it
					toggle_window_minstate(event.time, list.nth_data(0)); // Toggle the minimize / unminimize state of the first window in the class group
				}
			} else if (len > 1 && show_all_windows_on_click) { // Multiple windows
				list.foreach((w) => { // Cycle through the apps
					if (one_active) { // One of them is active
						w.minimize(); // Hide all
					} else { // None of them are active
						w.unminimize(event.time);
						w.activate(event.time);
					}
				});
			} else { // No windows
				should_launch_app = true;
			}
		} else {
			should_launch_app = true;
		}

		if (should_launch_app) { // If we should be launching the app
			bool require_double_click = this.settings.get_boolean("require-double-click-to-launch");

			if ((was_double_click && require_double_click) || !require_double_click) { // Used double click when enabled, or don't require double click
				launch_app(event.time);
			}
		}
	}

	public override bool scroll_event(Gdk.EventScroll event) {
		if (this.window != null) {
			this.window.unminimize(event.time);
			this.window.activate(event.time);
			return Gdk.EVENT_STOP;
		}

		if (class_group == null) {
			return Gdk.EVENT_STOP;
		}

		if (event.direction >= 4) {
			return Gdk.EVENT_STOP;
		}

		if (get_monotonic_time() - last_scroll_time < 300000) {
			return Gdk.EVENT_STOP;
		}

		Wnck.Window? target_window = null;

		var current_window = this.desktop_helper.get_active_window();
		bool have_current_window = (current_window != null);

		bool go_next = (event.direction == Gdk.ScrollDirection.UP);

		var ids = popover.window_id_to_name.get_keys();
		var ids_length = ids.length();

		if (ids_length > 1) { // Has more than one item and current window is valid
			if (!go_next) { // Go to previous window
				ids.reverse(); // Reverse our list before doing operations
			}

			var win_id = (have_current_window) ? current_window.get_xid() : 0;

			var current_window_position = 0;

			if (have_current_window) {
				for (var current_id_index = 0; current_id_index < ids.length(); current_id_index++) {
					var id = ids.nth_data(current_id_index);

					if (win_id == id) { // Matching id
						current_window_position = current_id_index;
						break;
					}
				}
			}

			var incr_index = (have_current_window) ? (current_window_position + 1) : 0; // Set our incremented index

			if (incr_index == ids_length) { // If we're on last item
				incr_index = 0; // Reset back to 0
			}

			var new_window_id = ids.nth_data(incr_index); // Get our next window id

			if (new_window_id != null) {
				Wnck.Window window = Wnck.Window.@get(new_window_id); // Get the window

				if (window != null) {
					target_window = window;
				}
			}

			if (target_window != null) {
				target_window.activate(event.time);

				if (target_window.is_minimized()) { // If the window is minimized
					target_window.unminimize(event.time);
				}

				last_scroll_time = get_monotonic_time();
			}
		} else if (ids_length == 1) { // Only has one window and scrolling up
			var id = ids.nth_data(0); // Get id at 0
			target_window = Wnck.Window.@get(id);

			if (target_window != null) {
				if (go_next) { // Activate / ensure is in focus
					target_window.activate(event.time);

					if (target_window.is_minimized()) { // If the window is minimized
						target_window.unminimize(event.time);
					}
				} else { // Effectively minimize
					target_window.minimize();
				}

				last_scroll_time = get_monotonic_time();
			}
		}

		return Gdk.EVENT_STOP;
	}

	// toggle_window_minstate will toggle the minimize / unminimize window state for the provided window
	private void toggle_window_minstate(uint32 time, Wnck.Window win) {
		Wnck.Window? current_active_window = win.get_screen().get_active_window();
		bool is_current_active_window = (win.get_xid() == ((current_active_window != null) ? current_active_window.get_xid() : 0));

		if (win.is_minimized() || !is_current_active_window) { // Is the window minimized or isn't the current active window
			win.activate(time);
			win.unminimize(time); // Ensure we unminimize it
		} else { // Window is not minimized
			win.minimize();
		}
	}

	public DesktopAppInfo? get_appinfo() {
		return this.app_info;
	}

	public unowned Wnck.ClassGroup? get_class_group() {
		return this.class_group;
	}
}

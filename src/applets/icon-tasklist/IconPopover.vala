/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2018-2021 Budgie Desktop Developers
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
	public interface SettingsRemote : GLib.Object {
		public abstract async void Close() throws Error;
	}

	public class IconPopover : Budgie.Popover {
		/**
		 * Data / Logic
		 */
		private bool is_budgie_desktop_settings = false; // We need a special case handler for Budgie Desktop Settings since it is part of budgie-panel
		private ulong current_window_id = 0; // Current window selected in the popover
		private int longest_label_length = 20; // longest_label_length is the longest length / max width chars we should allow for labels
		public HashTable<ulong?,string?> window_id_to_name; // List of IDs to Names
		private HashTable<ulong?,Budgie.IconPopoverItem?> window_id_to_controls; // List of IDs to Controls
		private List<Budgie.IconPopoverItem> workspace_items; // Our referenced list of workspaces
		private unowned string[] actions = null; // List of supported desktop actions
		private string preferred_action = ""; // Any preferred action from Desktop Actions like "new-window"
		private bool pinned = false;
		private int workspace_count = 0;
		private int workspaces_added_to_list = 0;
		private Gtk.Image non_starred_image = null;
		private Gtk.Image starred_image = null;

		private SettingsRemote? settings_remote = null;

		/**
		 * Widgets
		 */
		public Gtk.Stack? stack = null;
		public Gtk.Box? primary_view = null;
		public Gtk.Box? actions_view = null;
		public Gtk.Box? actions_list = null;
		public Gtk.Grid? actions_view_buttons = null;
		public Gtk.Box? windows_list = null;
		public Gtk.Separator? windows_sep = null;
		public Gtk.Grid? quick_actions = null; // (Un)Pin and Close All buttons

		public Gtk.CheckButton? always_on_top_button = null;
		public Gtk.Button? pin_button = null;
		public Gtk.Button? back_button = null;
		public Gtk.Button? close_all_button = null;
		public Gtk.Button? launch_new_instance_button = null;
		public Budgie.IconPopoverItem? maximize_button = null;
		public Budgie.IconPopoverItem? minimize_button = null;

		/**
		 * Signals
		 */
		public signal void added_window();
		public signal void closed_all();
		public signal void closed_window();
		public signal void changed_pin_state(bool new_state);
		public signal void launch_new_instance();
		public signal void move_window_to_workspace(ulong xid, int workspace_num);
		public signal void perform_action(string action);

		public IconPopover(Gtk.Widget relative_parent, DesktopAppInfo? app_info, int current_workspace_count) {
			Object(relative_to: relative_parent);
			get_style_context().add_class("icon-popover");
			workspace_count = current_workspace_count;
			width_request = 200;

			/**
			 * Data / Logic
			 */
			this.window_id_to_name = new HashTable<ulong?,string?>(int_hash, int_equal);
			this.window_id_to_controls = new HashTable<ulong?,Budgie.IconPopoverItem?>(int_hash, int_equal);
			this.workspace_items = new List<Budgie.IconPopoverItem>();
			create_images();

			/**
			 * Views
			 */
			this.stack = new Gtk.Stack();
			this.stack.get_style_context().add_class("icon-popover-stack");

			this.primary_view = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			this.actions_view = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			this.actions_list = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			this.windows_list = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			this.windows_sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
			this.windows_sep.no_show_all = true;

			this.quick_actions = new Gtk.Grid();
			this.quick_actions.column_homogeneous = true;
			this.pin_button = new Gtk.Button();
			this.pin_button.set_image(non_starred_image);

			this.launch_new_instance_button = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			this.launch_new_instance_button.set_tooltip_text(_("Launch New Instance"));

			this.close_all_button = new Gtk.Button.from_icon_name("list-remove-all-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			this.close_all_button.set_tooltip_text(_("Close All Windows"));
			this.close_all_button.sensitive = false;

			this.primary_view.pack_start(actions_list);
			this.primary_view.pack_start(windows_sep);
			this.primary_view.pack_start(windows_list);
			this.primary_view.pack_end(this.quick_actions);

			this.always_on_top_button = new Gtk.CheckButton.with_label(_("Always On Top"));
			this.always_on_top_button.height_request = 32;
			this.maximize_button = new Budgie.IconPopoverItem(_("Maximize"));
			this.minimize_button = new Budgie.IconPopoverItem(_("Minimize"));
			this.back_button = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			this.back_button.width_request = 100;

			actions_view_buttons = new Gtk.Grid();
			actions_view_buttons.attach(this.back_button, 0, 0, 1, 1);

			this.actions_view.pack_start(this.always_on_top_button, false, true, 0);
			this.actions_view.pack_start(this.maximize_button, false, true, 0);
			this.actions_view.pack_start(this.minimize_button, false, true, 0);
			this.actions_view.pack_end(actions_view_buttons, false, true, 0);

			set_workspace_count(this.workspace_count);

			if (app_info != null) {
				is_budgie_desktop_settings = app_info.get_startup_wm_class() == "budgie-desktop-settings";

				if (is_budgie_desktop_settings) {
					acquire_settings_remote();
				}

				this.quick_actions.attach(this.pin_button, 0, 0, 1, 1);
				this.quick_actions.attach(this.launch_new_instance_button, 1, 0, 1, 1);
				this.quick_actions.attach(this.close_all_button, 2, 0, 1, 1);

				this.actions = app_info.list_actions();

				if (this.actions.length != 0) {
					foreach (string action in this.actions) { // First we're going to want to figure out the longest actionable string name length
						string action_name = app_info.get_action_name(action); // Get the name for this action

						if (action_name.length > longest_label_length) { // If the length of this action name is longer than current longest
							longest_label_length = action_name.length; // Update
						}
					}

					foreach (string action in this.actions) { // Now actually create the items
						string action_name = app_info.get_action_name(action); // Get the name for this action

						Budgie.IconPopoverItem action_item = new Budgie.IconPopoverItem(action_name, longest_label_length);
						action_item.actionable_label.set_data("action", action);

						action_item.actionable_label.clicked.connect(() => {
							string assigned_action = action_item.actionable_label.get_data("action");
							this.perform_action(assigned_action);
						});

						this.actions_list.pack_end(action_item, true, false, 0);

						if (action == "new-window") { // Generally supported new-window action
							preferred_action = action;
						}
					}
				}
			} else { // App info isn't defined
				// Intentionally skip pin and launch new instance since that requires the app info
				this.quick_actions.attach(this.close_all_button, 0, 0, 3, 1);
			}

			pin_button.clicked.connect(() => { // When we click the pin button
				set_pinned_state(!this.pinned);
				changed_pin_state(this.pinned); // Call with new pinned state
			});

			launch_new_instance_button.clicked.connect(() => { // When we click to launch a new instance
				if (preferred_action != "") { // If we have a preferred action set
					perform_action(preferred_action);
				} else { // Default to our launch_new_instance signal
					launch_new_instance();
				}
			});

			close_all_button.clicked.connect(this.close_all_windows); // Close all windows

			always_on_top_button.toggled.connect(this.toggle_always_on_top_state);
			maximize_button.actionable_label.clicked.connect(this.toggle_maximized_state);
			minimize_button.actionable_label.clicked.connect(this.minimize_window);
			this.back_button.clicked.connect(this.render); // Go back home

			apply_button_style();
			this.stack.add_named(this.primary_view, "primary");
			this.stack.add_named(this.actions_view, "actions");

			add(this.stack);
		}

		/**
		 * add_window will add a window to our list
		 */
		public void add_window(ulong xid, string name) {
			if (!window_id_to_name.contains(xid)) {
				var window = Wnck.Window.@get(xid); // Get the window just to ensure it exists

				if (window == null) {
					return;
				}

				if (window.get_class_instance_name() == "budgie-panel") { // Likely a NORMAL type window of budgie-panel, which is Budgie Desktop Settings
					is_budgie_desktop_settings = true;
					acquire_settings_remote();
				}

				Budgie.IconPopoverItem item = new Budgie.IconPopoverItem.with_xid(name, xid, longest_label_length);

				item.actionable_label.clicked.connect(() => { // When we click on the window
					this.toggle_window(item.xid); // Toggle the window state
				});

				item.close_button.clicked.connect(() => { // Create our close button click handler
					this.close_window(item.xid); // Close this window if we can
				});

				item.window_controls_button.clicked.connect(() => { // Create our window controls button click handler
					this.current_window_id = item.xid; // Change our current window id
					this.update_actions_view(); // Update our actions view first
					this.actions_view.show_all();
					this.stack.set_visible_child_name("actions"); // Change to actions
				});

				window_id_to_name.insert(xid, name);
				window_id_to_controls.insert(xid, item);

				this.windows_list.pack_end(item, true, false, 0);
				this.render();

				added_window();
			}
		}

		/**
		 * apply_button_style will make our buttons flat
		 */
		public void apply_button_style() {
			pin_button.get_style_context().add_class("flat");
			pin_button.get_style_context().remove_class("button");
			launch_new_instance_button.get_style_context().add_class("flat");
			launch_new_instance_button.get_style_context().remove_class("button");
			close_all_button.get_style_context().add_class("flat");
			close_all_button.get_style_context().remove_class("button");
			back_button.get_style_context().add_class("flat");
			back_button.get_style_context().remove_class("button");
		}

		public void acquire_settings_remote() {
			if (settings_remote != null) {
				return;
			}

			Bus.get_proxy.begin<SettingsRemote>(BusType.SESSION, SETTINGS_DBUS_NAME, SETTINGS_DBUS_PATH, 0, null, on_settings_get);
		}

		public void close_all_windows() {
			if (window_id_to_name.length != 0) { // If there are windows to close
				window_id_to_name.foreach((xid, name) => {
					close_window(xid); // Close this window
				});
			}
		}

		/**
		 * close_window will close a window and remove its respective IconPopoverItem
		 */
		public void close_window(ulong xid) {
			var selected_window = Wnck.Window.@get(xid);

			if (selected_window != null) {
				if (is_budgie_desktop_settings) {
					settings_remote.Close.begin(on_settings_closed);
				} else {
					selected_window.close(Gtk.get_current_event_time());
				}
			} else {
				warning("Failed to get window during close.");
			}
		}

		/**
		 * create_images will create the Pixbufs we need for the pinned button
		 */
		public void create_images() {
			this.non_starred_image = new Gtk.Image.from_icon_name("non-starred-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			this.starred_image = new Gtk.Image.from_icon_name("starred-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		}

		/**
		 * minimize_window will minimize the current window
		 */
		public void minimize_window() {
			var selected_window = Wnck.Window.@get(this.current_window_id);

			if (selected_window != null) {
				selected_window.minimize(); // Minimize the window
			}

			Timeout.add(250, () => { // Give Wnck a moment to enact the change
				update_actions_view();
				return false;
			});
		}

		public void on_settings_get(Object? o, AsyncResult? res) {
			try {
				settings_remote = Bus.get_proxy.end(res);
			} catch (Error e) {
				warning("Failed to get SettingsRemote proxy: %s", e.message);
			}
		}

		public void on_settings_closed(Object? o, AsyncResult? res) {
			try {
				if (settings_remote == null) {
					return;
				}

				settings_remote.Close.end(res);
			} catch (Error e) {
				warning("Failed to close Settings: %s", e.message);
			}
		}

		/**
		 * remove_window will remove the respective item from our windows list and HashTables
		 */
		public void remove_window(ulong xid) {
			if (window_id_to_name.contains(xid)) { // If we have this xid
				Budgie.IconPopoverItem item = window_id_to_controls.get(xid); // Get the control
				windows_list.remove(item); // Remove from the window list
				window_id_to_name.remove(xid);
				window_id_to_controls.remove(xid);
				this.render(); // Re-render

				closed_window();

				if (window_id_to_name.length == 0) {
					closed_all();

					if (is_budgie_desktop_settings) { // Now have an instance of Budgie Desktop Settings
						this.launch_new_instance_button.sensitive = true; // Set to be sensitive again
					}
				}
			}

			this.close_all_button.sensitive = (window_id_to_name.length != 0);
		}

		/**
		 * rename_window will rename a window we have listed
		 */
		public void rename_window(ulong xid) {
			if (window_id_to_name.contains(xid)) { // If we have this window
				var selected_window = Wnck.Window.@get(xid); // Get the window

				if (selected_window != null) {
					Budgie.IconPopoverItem item = window_id_to_controls.get(xid); // Get the control
					item.set_label(selected_window.get_name());
				}
			}
		}

		/**
		 * render will determine what we need to render (show v.s. hide) in the popover
		 */
		public void render() {
			bool has_actions = this.actions.length != 0;
			bool has_windows = this.window_id_to_name.length != 0;

			if (has_actions) { // If there are actions
				this.actions_list.show_all();
			} else { // No actions
				this.actions_list.hide();
			}

			if (has_windows) { // Has windows
				this.windows_list.show_all(); // Show the list
			} else { // Does not have windows
				this.windows_list.hide(); // Hide the list
			}

			if (has_actions && has_windows) { // Both actions and windows
				this.windows_sep.show(); // Show separator
			} else {
				this.windows_sep.hide(); // Hide separator
			}

			if (!has_actions && !has_windows) { // Does not have actions or windows, so "empty"
				this.get_style_context().add_class("only-actions");
			} else { // Has either actions or windows
				this.get_style_context().remove_class("only-actions");
			}

			this.close_all_button.sensitive = (window_id_to_name.length != 0);

			this.actions_view.hide();
			this.primary_view.show_all();
			this.stack.set_visible_child_name("primary");

			if (is_budgie_desktop_settings) { // Budgie Desktop Settings
				pin_button.hide(); // Hide pin button
				launch_new_instance_button.hide(); // Hide launch new instance
			} else {
				pin_button.show();
				launch_new_instance_button.show();
			}

			this.stack.show();
		}

		/**
		 * set_pinned_state will change the icon of our pinned button and set pinned state
		 */
		public void set_pinned_state(bool pinned_state) {
			this.pinned = pinned_state;
			pin_button.set_image(this.pinned ? starred_image : non_starred_image);
			pin_button.set_tooltip_text((this.pinned) ? _("Unfavorite") : _("Favorite"));
		}

		/**
		 * set_workspace_count will update our current maximize number of workspaces
		 */
		public void set_workspace_count(int workspaces) {
			this.workspace_count = workspaces;

			if (this.workspace_count != this.workspaces_added_to_list) { // If our current amount of workspaces is different than how many we have added
				if (this.workspace_count > this.workspaces_added_to_list) { // We have items to add
					for (int i = (this.workspaces_added_to_list + 1); i <= this.workspace_count; i++) { // For workspaces we need to add
						Budgie.IconPopoverItem item = new Budgie.IconPopoverItem(_("Move To Workspace %i").printf(i));
						item.actionable_label.set_data("num", i);

						item.actionable_label.clicked.connect(() => { // On workspace move
							int workspace_num = item.actionable_label.get_data("num");
							this.move_window_to_workspace(this.current_window_id, workspace_num);
						});

						workspace_items.append(item);
						this.actions_view.pack_start(item, false, false, 0);
					}

					this.workspaces_added_to_list = this.workspace_count;
				} else { // We have items to remove
					int workspaces_to_remove = this.workspaces_added_to_list - this.workspace_count;
					if (workspaces_to_remove > 0) { // If there are workspaces to remove
						workspace_items.reverse();

						for (int i = 0; i < workspaces_to_remove; i++) {
							Budgie.IconPopoverItem child = workspace_items.nth_data(i);

							if (child != null) {
								this.actions_view.remove(child);
								workspace_items.remove(child);
							}
						}

						workspace_items.reverse();
					}
				}
			}
		}

		/**
		 * toggle_always_on_top_state will toggle the always on state of the current window
		 */
		public void toggle_always_on_top_state() {
			Wnck.Window selected_window = Wnck.Window.@get(this.current_window_id);

			if (selected_window != null) {
				if (selected_window.is_above()) { // Currently is above other windows
					selected_window.unmake_above(); // No longer have it be above
				} else { // Currently not above other windows
					selected_window.make_above(); // Make the window above others
				}
			}
		}

		/**
		 * toggle_maximized_state will toggle the maximized state of the current window
		 */
		public void toggle_maximized_state() {
			Wnck.Window selected_window = Wnck.Window.@get(this.current_window_id);

			if (selected_window != null) {
				if (!selected_window.is_minimized()) { // Not minimized
					if (selected_window.is_maximized()) { // Current is maximized
						selected_window.unmaximize(); // Unmaximize the window
					} else { // Current is not maximized
						selected_window.maximize(); // Maximize the window
					}
				} else {
					selected_window.maximize(); // Maximize the window
				}

				selected_window.activate(Gtk.get_current_event_time()); // Ensure it is activated

				Timeout.add(250, () => { // Give Wnck a moment to enact the change
					update_actions_view();
					return false;
				});
			}
		}

		/**
		 * toggle_window will activate or minimize this window
		 */
		public void toggle_window(ulong xid) {
			if (window_id_to_name.contains(xid)) { // If we have this xid
				Wnck.Window selected_window = Wnck.Window.@get(xid); // Get the window

				if (selected_window != null) {
					if (!selected_window.is_active()) { // If this window is currently not active
						selected_window.activate(Gtk.get_current_event_time());
					} else {
						selected_window.minimize();
					}
				}
			}
		}

		/**
		 * update_actions_view will update the actions view
		 */
		public void update_actions_view() {
			if (this.current_window_id != 0) {
				Wnck.Window selected_window = Wnck.Window.@get(this.current_window_id);

				if (selected_window != null) {
					always_on_top_button.active = selected_window.is_above(); // Update our always on top button
					string maximize_label = ((selected_window.is_maximized() && !selected_window.is_minimized()) ? _("Unmaximize") : _("Maximize"));
					maximize_button.set_label(maximize_label);

					queue_draw();
				}
			}
		}
	}

	/**
	 * IconPopoverItem is an item for our IconPopover
	 */
	public class IconPopoverItem : Gtk.Box {
		public Gtk.Button? actionable_label; // Primary Button
		public Gtk.Label? actionable_label_content;
		public Gtk.Button? close_button;
		public Gtk.Button? window_controls_button;

		public ulong xid;

		public IconPopoverItem(string label_content, int label_length = 20) {
			Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 0);
			height_request = 32;
			margin = 0;

			actionable_label = new Gtk.Button();
			Gtk.Box actionable_label_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			actionable_label_content = new Gtk.Label(label_content);
			actionable_label_content.ellipsize = Pango.EllipsizeMode.END;
			actionable_label_content.halign = Gtk.Align.START;
			actionable_label_content.justify = Gtk.Justification.LEFT;
			actionable_label_content.max_width_chars = label_length;

			actionable_label_container.pack_start(actionable_label_content, false, true, 0);

			actionable_label.add(actionable_label_container);
			apply_button_style();
			pack_start(actionable_label, true, true, 0);
		}

		public IconPopoverItem.with_xid(string label_content, ulong xid, int label_length = 20) {
			Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 0);
			height_request = 32;
			margin = 0;

			actionable_label = new Gtk.Button();
			Gtk.Box actionable_label_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			actionable_label_content = new Gtk.Label(label_content);
			actionable_label_content.ellipsize = Pango.EllipsizeMode.END;
			actionable_label_content.halign = Gtk.Align.START;
			actionable_label_content.justify = Gtk.Justification.LEFT;
			actionable_label_content.max_width_chars = label_length;

			actionable_label_container.pack_start(actionable_label_content, true, true, 0);
			actionable_label.add(actionable_label_container);

			this.xid = xid;

			close_button = new Gtk.Button.from_icon_name("window-close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			close_button.set_tooltip_text(_("Close Window"));
			window_controls_button = new Gtk.Button.from_icon_name("go-next-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			window_controls_button.set_tooltip_text(_("Show Window Controls"));

			apply_button_style();

			pack_start(actionable_label, true, true, 0);
			pack_start(close_button, false, false, 0);
			pack_end(window_controls_button, false, false, 0);
		}

		/**
		 * apply_button_style will make our buttons flat
		 */
		public void apply_button_style() {
			if (actionable_label != null) {
				actionable_label.get_style_context().add_class("flat");
				actionable_label.get_style_context().remove_class("button");
			}

			if (close_button != null) {
				close_button.get_style_context().add_class("flat");
				close_button.get_style_context().remove_class("button");
			}

			if (window_controls_button != null) {
				window_controls_button.get_style_context().add_class("flat");
				window_controls_button.get_style_context().remove_class("button");
			}
		}

		/**
		 * set_label will set the label content
		 */
		public void set_label(string label) {
			actionable_label_content.set_label(label);
		}
	}
}

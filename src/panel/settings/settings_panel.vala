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
	* Simple trash button which can then be styled by the GTK theme
	*/
	public class TrashButton : Gtk.Button {
		public TrashButton() {
			Object();
			var img = new Gtk.Image.from_icon_name("edit-delete-symbolic", Gtk.IconSize.MENU);
			this.add(img);
			var st = this.get_style_context();
			st.add_class("image-button");
			st.add_class(Gtk.STYLE_CLASS_FLAT);
			st.add_class("budgie-trash-button");
		}
	}

	/**
	* PanelPage allows users to change aspects of the fonts used
	*/
	public class PanelPage : Budgie.SettingsPage {
		unowned Budgie.Toplevel? toplevel;
		Gtk.Stack stack;
		Gtk.StackSwitcher switcher;
		Gtk.ComboBox combobox_position;
		ulong position_id;
		Gtk.ComboBox combobox_autohide;
		ulong autohide_id;
		Gtk.ComboBox combobox_transparency;
		ulong transparency_id;

		Gtk.Switch switch_shadow;
		ulong shadow_id;
		Gtk.Switch switch_regions;
		ulong region_id;
		Gtk.Switch switch_dock;
		ulong dock_id;

		private Gtk.SpinButton? spinbutton_size;
		private ulong size_id;

		Gtk.Button button_remove_panel;

		unowned Budgie.DesktopManager? manager = null;

		public PanelPage(Budgie.DesktopManager? manager, Budgie.Toplevel? toplevel) {
			Object(group: SETTINGS_GROUP_PANEL,
				content_id: "panel-%s".printf(toplevel.uuid),
				title: PanelPage.get_panel_name(toplevel),
				display_weight: PanelPage.get_panel_weight(toplevel),
				icon_name: "user-desktop");

			this.manager = manager;
			this.toplevel = toplevel;

			border_width = 0;
			margin_top = 8;
			margin_bottom = 8;

			var swbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			this.pack_start(swbox, false, false, 0);

			/* Main layout bits */
			switcher = new Gtk.StackSwitcher();
			switcher.halign = Gtk.Align.CENTER;
			stack = new Gtk.Stack();
			stack.set_homogeneous(false);
			switcher.set_stack(stack);
			swbox.pack_start(switcher, true, true, 0);
			this.pack_start(stack, true, true, 0);

			this.stack.add_titled(this.applets_page(), "main", _("Applets"));
			this.stack.add_titled(this.settings_page(), "applets", _("Settings"));

			button_remove_panel = new Gtk.Button.with_label(_("Remove Panel"));
			button_remove_panel.set_tooltip_text(_("Remove this panel from the screen"));
			button_remove_panel.clicked.connect_after(this.delete_panel);
			button_remove_panel.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION); // Indicate it is a destructive action
			button_remove_panel.halign = Gtk.Align.CENTER;
			button_remove_panel.valign = Gtk.Align.CENTER;
			button_remove_panel.margin_bottom = 8;
			button_remove_panel.vexpand = false;

			this.pack_end(button_remove_panel, false, false, 0);

			manager.panels_changed.connect(this.on_panels_changed);
			this.on_panels_changed();
			this.show_all();

			on_panels_changed(); // Call our on_panels_changed so we can immediately set the sensitivity and hide our Remove Panel button if necessary.
		}

		void on_panels_changed() {
			/* Must have at least *one* panel */
			button_remove_panel.set_sensitive(manager.slots_used() > 1);
			this.display_weight = PanelPage.get_panel_weight(this.toplevel);

			if (manager.slots_used() > 1) { // More than one panel
				button_remove_panel.show(); // Show the button
			} else { // Only one panel
				button_remove_panel.hide(); // Don't even show the Remove Panel button, regardless of sensitivity
			}
		}

		/**
		* Determine a human readable named based on the panel's position on screen
		* For brownie points we'll identify docks differently
		*/
		static string get_panel_name(Budgie.Toplevel? panel) {
			if (panel.dock_mode) {
				switch (panel.position) {
					case PanelPosition.TOP:
						return _("Top Dock");
					case PanelPosition.RIGHT:
						return _("Right Dock");
					case PanelPosition.LEFT:
						return _("Left Dock");
					default:
						return _("Bottom Dock");
				}
			} else {
				switch (panel.position) {
					case PanelPosition.TOP:
						return _("Top Panel");
					case PanelPosition.RIGHT:
						return _("Right Panel");
					case PanelPosition.LEFT:
						return _("Left Panel");
					default:
						return _("Bottom Panel");
				}
			}
		}

		/**
		* Assign a display weight to a given panel
		*/
		static int get_panel_weight(Budgie.Toplevel? toplevel) {
			int base_score = 0;
			switch (toplevel.position) {
				case PanelPosition.TOP:
					base_score = 1;
					break;
				case PanelPosition.BOTTOM:
					base_score = 2;
					break;
				case PanelPosition.LEFT:
					base_score = 3;
					break;
				case PanelPosition.RIGHT:
				default:
					base_score = 4;
					break;
			}
			if (toplevel.dock_mode) {
				base_score += 10;
			}
			return base_score;
		}

		/**
		* Convert a position into a usable, renderable Thing™
		*/
		static string pos_to_display(Budgie.PanelPosition position) {
			switch (position) {
				case PanelPosition.TOP:
					return _("Top");
				case PanelPosition.RIGHT:
					return _("Right");
				case PanelPosition.LEFT:
					return _("Left");
				default:
					return _("Bottom");
			}
		}

		/**
		* Get a usable display string for the transparency type
		*/
		static string transparency_to_display(Budgie.PanelTransparency transp) {
			switch (transp) {
				case PanelTransparency.ALWAYS:
					return _("Always");
				case PanelTransparency.DYNAMIC:
					return _("Dynamic");
				case PanelTransparency.NONE:
				default:
					return _("None");
			}
		}

		/**
		* Get a usable display string for the autohide type
		*/
		static string policy_to_display(Budgie.AutohidePolicy policy) {
			switch (policy) {
				case AutohidePolicy.AUTOMATIC:
					return _("Automatic");
				case AutohidePolicy.INTELLIGENT:
					return _("Intelligent");
				case AutohidePolicy.NONE:
				default:
					return _("Never");
			}
		}

		private Gtk.Widget? settings_page() {
			SettingsGrid? ret = new SettingsGrid();
			Gtk.SizeGroup group = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

			ret.border_width = 20;

			/* Position */
			combobox_position = new Gtk.ComboBox();
			position_id = combobox_position.changed.connect(this.set_position);
			group.add_widget(combobox_position);
			ret.add_row(new SettingsRow(combobox_position,
				_("Position"),
				_("Set the edge of the screen that this panel will stay on")));

			/* Size of the panel */
			spinbutton_size = new Gtk.SpinButton.with_range(16, 200, 1);
			spinbutton_size.set_numeric(true);
			size_id = spinbutton_size.value_changed.connect(this.set_size);
			group.add_widget(spinbutton_size);
			ret.add_row(new SettingsRow(spinbutton_size,
				_("Size"),
				_("Set the size (width or height, depending on orientation) of this panel")));

			/* Autohide */
			combobox_autohide = new Gtk.ComboBox();
			autohide_id = combobox_autohide.changed.connect(this.set_autohide);
			group.add_widget(combobox_autohide);
			ret.add_row(new SettingsRow(combobox_autohide,
				_("Automatically hide"),
				_("When set, this panel will hide from view to maximize screen estate")));

			/* Transparency */
			combobox_transparency = new Gtk.ComboBox();
			transparency_id = combobox_transparency.changed.connect(this.set_transparency);
			group.add_widget(combobox_transparency);
			ret.add_row(new SettingsRow(combobox_transparency,
				_("Transparency"),
				_("Control when this panel should have a solid background")));

			/* Shadow */
			switch_shadow = new Gtk.Switch();
			ret.add_row(new SettingsRow(switch_shadow,
				_("Shadow"),
				_("Adds a decorative drop-shadow, ideal for opaque panels")));
			shadow_id = switch_shadow.notify["active"].connect(this.set_shadow);

			/* Regions */
			switch_regions = new Gtk.Switch();
			ret.add_row(new SettingsRow(switch_regions,
				_("Stylize regions"),
				_("Adds a hint to the panel so that each of the panel's three main areas " +
				"may be themed differently.")));
			region_id = switch_regions.notify["active"].connect(this.set_region);

			/* Dock */
			switch_dock = new Gtk.Switch();
			ret.add_row(new SettingsRow(switch_dock,
				_("Dock mode"),
				_("When in dock mode, the panel will use the minimal amount of space possible, " +
				"freeing up valuable screen estate")));
			dock_id = switch_dock.notify["active"].connect(this.set_dock);

			/* We'll reuse this guy */
			var render = new Gtk.CellRendererText();

			/* Now let's sort out some models */
			var model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(Budgie.PanelPosition));
			Gtk.TreeIter iter;
			const Budgie.PanelPosition[] positions = {
				Budgie.PanelPosition.TOP,
				Budgie.PanelPosition.BOTTOM,
				Budgie.PanelPosition.LEFT,
				Budgie.PanelPosition.RIGHT,
			};
			foreach (var pos in positions) {
				model.append(out iter);
				model.set(iter, 0, pos.to_string(), 1, PanelPage.pos_to_display(pos), 2, pos, -1);
			}
			combobox_position.set_model(model);
			combobox_position.pack_start(render, true);
			combobox_position.add_attribute(render, "text", 1);
			combobox_position.set_id_column(0);

			/* Transparency types */
			model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(Budgie.PanelTransparency));
			const Budgie.PanelTransparency transps[] = {
				Budgie.PanelTransparency.ALWAYS,
				Budgie.PanelTransparency.DYNAMIC,
				Budgie.PanelTransparency.NONE,
			};
			foreach (var t in transps) {
				model.append(out iter);
				model.set(iter, 0, t.to_string(), 1, PanelPage.transparency_to_display(t), 2, t, -1);
			}
			combobox_transparency.set_model(model);
			combobox_transparency.pack_start(render, true);
			combobox_transparency.add_attribute(render, "text", 1);
			combobox_transparency.set_id_column(0);

			/* Autohide types */
			model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(Budgie.AutohidePolicy));
			const Budgie.AutohidePolicy policies[] = {
				Budgie.AutohidePolicy.AUTOMATIC,
				Budgie.AutohidePolicy.INTELLIGENT,
				Budgie.AutohidePolicy.NONE,
			};
			foreach (var p in policies) {
				model.append(out iter);
				model.set(iter, 0, p.to_string(), 1, PanelPage.policy_to_display(p), 2, p, -1);
			}
			combobox_autohide.set_model(model);
			combobox_autohide.pack_start(render, true);
			combobox_autohide.add_attribute(render, "text", 1);
			combobox_autohide.set_id_column(0);

			/* Properties we needed to know about */
			const string[] needed_props = {
				"position",
				"intended-size",
				"transparency",
				"autohide",
				"shadow-visible",
				"theme-regions",
				"dock-mode",
			};

			foreach (var init in needed_props) {
				this.update_from_property(init);
				this.toplevel.notify[init].connect_after(this.panel_notify);
			}

			return ret;
		}

		private Gtk.Widget? applets_page() {
			AppletsPage ret = new AppletsPage(this.manager, this.toplevel);
			ret.border_width = 20;
			return ret;
		}

		private void panel_notify(Object? o, ParamSpec ps) {
			this.update_from_property(ps.name);
		}

		/**
		* Update our state from a given property, taking care to not
		* fire off our own handlers and causing a cycle
		*/
		private void update_from_property(string property) {
			switch (property) {
				case "position":
					SignalHandler.block(this.combobox_position, this.position_id);
					this.combobox_position.active_id = this.toplevel.position.to_string();
					this.title = PanelPage.get_panel_name(toplevel);
					SignalHandler.unblock(this.combobox_position, this.position_id);
					break;
				case "intended-size":
					SignalHandler.block(this.spinbutton_size, this.size_id);
					this.spinbutton_size.set_value(this.toplevel.intended_size);
					SignalHandler.unblock(this.spinbutton_size, this.size_id);
					break;
				case "transparency":
					SignalHandler.block(this.combobox_transparency, this.transparency_id);
					this.combobox_transparency.active_id = this.toplevel.transparency.to_string();
					SignalHandler.unblock(this.combobox_transparency, this.transparency_id);
					break;
				case "autohide":
					SignalHandler.block(this.combobox_autohide, this.autohide_id);
					this.combobox_autohide.active_id = this.toplevel.autohide.to_string();
					SignalHandler.unblock(this.combobox_autohide, this.autohide_id);
					break;
				case "shadow-visible":
					SignalHandler.block(this.switch_shadow, this.shadow_id);
					this.switch_shadow.active = this.toplevel.shadow_visible;
					SignalHandler.unblock(this.switch_shadow, this.shadow_id);
					break;
				case "theme-regions":
					SignalHandler.block(this.switch_regions, this.region_id);
					this.switch_regions.active = this.toplevel.theme_regions;
					SignalHandler.unblock(this.switch_regions, this.region_id);
					break;
				case "dock-mode":
					SignalHandler.block(this.switch_dock, this.dock_id);
					this.switch_dock.active = this.toplevel.dock_mode;
					this.title = PanelPage.get_panel_name(toplevel);
					SignalHandler.unblock(this.switch_dock, this.dock_id);
					break;
				default:
					break;
			}
		}

		/**
		* We're asking the panel to update the shadow state
		*/
		private void set_shadow() {
			this.toplevel.shadow_visible = this.switch_shadow.active;
		}

		/**
		* We're asking the panel to update the shadow state
		*/
		private void set_region() {
			this.toplevel.theme_regions = this.switch_regions.active;
		}

		/**
		* Ask the manager to change the dock state of the panel
		*/
		private void set_dock() {
			this.manager.set_dock_mode(this.toplevel.uuid, this.switch_dock.active);
		}

		/**
		* Update the panel position on screen
		*/
		private void set_position() {
			Gtk.TreeIter iter;
			Budgie.PanelPosition position = this.toplevel.position;

			if (!combobox_position.get_active_iter(out iter)) {
				return;
			}

			combobox_position.model.get(iter, 2, out position, -1);
			this.manager.set_placement(toplevel.uuid, position);
		}

		/**
		* Update the autohide policy for the panel
		*/
		private void set_autohide() {
			Gtk.TreeIter iter;
			Budgie.AutohidePolicy policy = this.toplevel.autohide;

			if (!combobox_autohide.get_active_iter(out iter)) {
				return;
			}

			combobox_autohide.model.get(iter, 2, out policy, -1);
			this.manager.set_autohide(toplevel.uuid, policy);
		}

		/**
		* Update the transparency setting for the panel
		*/
		private void set_transparency() {
			Gtk.TreeIter iter;
			Budgie.PanelTransparency transparency = this.toplevel.transparency;

			if (!combobox_transparency.get_active_iter(out iter)) {
				return;
			}

			combobox_transparency.model.get(iter, 2, out transparency, -1);
			this.manager.set_transparency(toplevel.uuid, transparency);
		}

		/**
		* Update the panel size
		*/
		private void set_size() {
			this.manager.set_size(this.toplevel.uuid, (int)this.spinbutton_size.get_value());
		}

		/**
		* Delete ourselves
		*/
		void delete_panel() {
			if (this.manager.slots_used() > 1) {
				var dlg = new RemovePanelDialog(this.get_toplevel() as Gtk.Window);
				bool del = dlg.run();
				dlg.destroy();
				if (del) {
					this.manager.delete_panel(this.toplevel.uuid);
				}
			}
		}
	}
}

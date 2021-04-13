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

public class PlacesIndicator : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new PlacesIndicatorApplet(uuid);
	}
}

[GtkTemplate (ui="/com/solus-project/places-indicator/settings.ui")]
public class PlacesIndicatorSettings : Gtk.Grid {
	[GtkChild]
	private Gtk.Switch? switch_label;

	[GtkChild]
	private Gtk.Switch? switch_places;

	[GtkChild]
	private Gtk.Switch? switch_expand_places;

	[GtkChild]
	private Gtk.Switch? switch_drives;

	[GtkChild]
	private Gtk.Switch? switch_networks;

	private Settings? settings;

	public PlacesIndicatorSettings(Settings? settings) {
		this.settings = settings;
		settings.bind("show-label", switch_label, "active", SettingsBindFlags.DEFAULT);
		settings.bind("expand-places", switch_expand_places, "active", SettingsBindFlags.DEFAULT);
		settings.bind("show-places", switch_places, "active", SettingsBindFlags.DEFAULT);
		settings.bind("show-drives", switch_drives, "active", SettingsBindFlags.DEFAULT);
		settings.bind("show-networks", switch_networks, "active", SettingsBindFlags.DEFAULT);
	}
}

public class PlacesIndicatorApplet : Budgie.Applet {
	private Gtk.EventBox? ebox;
	private PlacesIndicatorWindow? popover;
	private Gtk.Label label;
	private Gtk.Image image;
	private Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;

	private unowned Budgie.PopoverManager? manager = null;
	private Settings settings;
	public string uuid { public set ; public get; }

	public override Gtk.Widget? get_settings_ui() {
		return new PlacesIndicatorSettings(get_applet_settings(uuid));
	}

	public override bool supports_settings() {
		return true;
	}

	public PlacesIndicatorApplet(string uuid) {
		Object(uuid: uuid);

		settings_schema = "com.solus-project.places-indicator";
		settings_prefix = "/com/solus-project/budgie-panel/instance/places-indicator";

		settings = get_applet_settings(uuid);
		settings.changed.connect(on_settings_changed);

		ebox = new Gtk.EventBox();
		Gtk.Box layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		ebox.add(layout);
		image = new Gtk.Image.from_icon_name("folder-symbolic", Gtk.IconSize.MENU);
		layout.pack_start(image, true, true, 3);
		label = new Gtk.Label(_("Places"));
		label.halign = Gtk.Align.START;
		layout.pack_start(label, true, true, 3);

		popover = new PlacesIndicatorWindow(image);

		ebox.button_press_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			toggle_popover();
			return Gdk.EVENT_STOP;
		});

		popover.get_child().show_all();

		add(ebox);
		show_all();

		on_settings_changed("show-label");
		on_settings_changed("expand-places");
		on_settings_changed("show-places");
		on_settings_changed("show-drives");
		on_settings_changed("show-networks");
	}

	public override void panel_position_changed(Budgie.PanelPosition position) {
		this.panel_position = position;
		on_settings_changed("show-label");
	}

	public void toggle_popover() {
		if (popover.get_visible()) {
			popover.hide();
		} else {
			popover.get_child().show_all();
			this.manager.show_popover(ebox);
		}
	}

	public override void invoke_action(Budgie.PanelAction action) {
		toggle_popover();
	}

	public override void update_popovers(Budgie.PopoverManager? manager) {
		this.manager = manager;
		manager.register_popover(ebox, popover);
	}

	protected void on_settings_changed(string key) {
		switch (key) {
			case "show-label":
				bool visible = (panel_position == Budgie.PanelPosition.TOP ||
								panel_position == Budgie.PanelPosition.BOTTOM) &&
								settings.get_boolean(key);
				label.set_visible(visible);
				break;
			case "expand-places":
				popover.expand_places = settings.get_boolean(key);
				break;
			case "show-places":
				popover.show_places = settings.get_boolean(key);
				break;
			case "show-drives":
				popover.show_drives = settings.get_boolean(key);
				break;
			case "show-networks":
				popover.show_networks = settings.get_boolean(key);
				break;
			default:
				break;
		}
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(PlacesIndicator));
}

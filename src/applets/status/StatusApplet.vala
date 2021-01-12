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
public class StatusPlugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new StatusApplet(uuid);
	}
}

[GtkTemplate (ui="/com/solus-project/status/settings.ui")]
public class StatusSettings : Gtk.Grid {
	Settings? settings = null;

	[GtkChild]
	private Gtk.SpinButton? spinbutton_spacing;

	public StatusSettings(Settings? settings) {
		this.settings = settings;
		settings.bind("spacing", spinbutton_spacing, "value", SettingsBindFlags.DEFAULT);
	}
}

public class StatusApplet : Budgie.Applet {
	public string uuid { public set; public get; }
	protected Gtk.Box widget;
	protected BluetoothIndicator blue;
	protected SoundIndicator sound;
	protected PowerIndicator power;
	protected Gtk.EventBox? wrap;
	private Settings? settings;
	private Budgie.PopoverManager? manager = null;

	/**
	 * Set up an EventBox for popovers
	 */
	private void setup_popover(Gtk.Widget? parent_widget, Budgie.Popover? popover) {
		parent_widget.button_press_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			if (popover.get_visible()) {
				popover.hide();
			} else {
				this.manager.show_popover(parent_widget);
			}
			return Gdk.EVENT_STOP;
		});
	}

	public StatusApplet(string uuid) {
		Object(uuid: uuid);

		settings_schema = "com.solus-project.status";
		settings_prefix = "/com/solus-project/budgie-panel/instance/status";

		settings = get_applet_settings(uuid);
		settings.changed["spacing"].connect((key) => {
			if (widget != null) widget.set_spacing(settings.get_int("spacing"));
		});

		wrap = new Gtk.EventBox();
		add(wrap);

		widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, settings.get_int("spacing"));
		wrap.add(widget);

		show_all();

		power = new PowerIndicator();
		widget.pack_start(power, false, false, 0);
		/* Power shows itself - we dont control that */

		sound = new SoundIndicator();
		widget.pack_start(sound, false, false, 0);
		sound.show_all();

		/* Hook up the popovers */
		this.setup_popover(power.ebox, power.popover);
		this.setup_popover(sound.ebox, sound.popover);

		blue = new BluetoothIndicator();
		widget.pack_start(blue, false, false, 0);
		blue.show_all();
		this.setup_popover(blue.ebox, blue.popover);
	}

	public override void panel_position_changed(Budgie.PanelPosition position) {
		Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;
		if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
			orient = Gtk.Orientation.VERTICAL;
		}
		this.widget.set_orientation(orient);
		this.power.change_orientation(orient);
	}

	public override void update_popovers(Budgie.PopoverManager? manager) {
		this.manager = manager;
		manager.register_popover(power.ebox, power.popover);
		manager.register_popover(sound.ebox, sound.popover);
		manager.register_popover(blue.ebox, blue.popover);
	}

	public override bool supports_settings() {
		return true;
	}

	public override Gtk.Widget? get_settings_ui() {
		return new StatusSettings(get_applet_settings(uuid));
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(StatusPlugin));
}

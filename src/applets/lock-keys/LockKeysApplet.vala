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

public class LockKeysPlugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new LockKeysApplet();
	}
}

public class LockKeysApplet : Budgie.Applet {
	Gtk.Box widget;
	Gtk.Image caps;
	Gtk.Image num;
	Gtk.EventBox caps_box;
	Gtk.EventBox num_box;
	new Gdk.Keymap map;

	public LockKeysApplet() {
		widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
		add(widget);

		get_style_context().add_class("lock-keys");
		/* Pretty labels, probably use icons in future */
		caps = new Gtk.Image.from_icon_name("caps-lock-symbolic", Gtk.IconSize.MENU);
		num = new Gtk.Image.from_icon_name("num-lock-symbolic", Gtk.IconSize.MENU);
		caps_box = new Gtk.EventBox();
		num_box = new Gtk.EventBox();
		caps_box.add(caps);
		num_box.add(num);;
		widget.pack_start(caps_box, false, false, 0);
		widget.pack_start(num_box, false, false, 0);

		caps_box.button_press_event.connect((eventbutton) => {
			return on_panel_widget_clicked(eventbutton, "Caps_Lock");
		});
		num_box.button_press_event.connect((eventbutton) => {
			return on_panel_widget_clicked(eventbutton, "Num_Lock");
		});

		map = Gdk.Keymap.get_for_display(Gdk.Display.get_default());
		map.state_changed.connect(on_state_changed);

		on_state_changed();

		show_all();
	}

	public override void panel_position_changed(Budgie.PanelPosition position) {
		Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;
		if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
			orient = Gtk.Orientation.VERTICAL;
		}
		this.widget.set_orientation(orient);
	}

	/* Handle caps lock changes */
	protected void toggle_caps() {
		caps.set_sensitive(map.get_caps_lock_state());
		if (map.get_caps_lock_state()) {
			caps.set_tooltip_text(_("Caps lock is active"));
			caps.get_style_context().remove_class("dim-label");
		} else {
			caps.set_tooltip_text(_("Caps lock is not active"));
			caps.get_style_context().add_class("dim-label");
		}
	}

	/* Handle num lock changes */
	protected void toggle_num() {
		num.set_sensitive(map.get_num_lock_state());
		if (map.get_num_lock_state()) {
			num.set_tooltip_text(_("Num lock is active"));
			num.get_style_context().remove_class("dim-label");
		} else {
			num.set_tooltip_text(_("Num lock is not active"));
			num.get_style_context().add_class("dim-label");
		}
	}

	/* If xdotool is installed, handle the clicks on the panel icons */
	protected bool on_panel_widget_clicked(Gdk.EventButton eventbutton, string button) {
		string? xdotool = Environment.find_program_in_path("xdotool");
		if ((xdotool == null) || (eventbutton.button != 1)) {
			return Gdk.EVENT_PROPAGATE;
		}
		try {
			Process.spawn_command_line_async(string.join(" ", xdotool, "key", button));
		} catch (SpawnError e) {
			warning("Failed to run xdotool: %s", e.message);
			return Gdk.EVENT_PROPAGATE;
		}
		return Gdk.EVENT_STOP;
	}

	protected void on_state_changed() {
		toggle_caps();
		toggle_num();
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(LockKeysPlugin));
}

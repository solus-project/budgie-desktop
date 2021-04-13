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

public class ShowDesktopPlugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new ShowDesktopApplet();
	}
}

public class ShowDesktopApplet : Budgie.Applet {
	protected Gtk.ToggleButton widget;
	protected Gtk.Image img;
	private Wnck.Screen wscreen;
	private List<ulong> window_list;

	public ShowDesktopApplet() {
		widget = new Gtk.ToggleButton();
		widget.relief = Gtk.ReliefStyle.NONE;
		widget.set_active(false);
		img = new Gtk.Image.from_icon_name("user-desktop-symbolic", Gtk.IconSize.BUTTON);
		widget.add(img);
		widget.set_tooltip_text(_("Toggle the desktop"));

		window_list = new List<ulong>();
		wscreen = Wnck.Screen.get_default();

		wscreen.window_opened.connect(() => {
			window_list = new List<ulong>();
			widget.set_active(false);
		});

		widget.toggled.connect(() => {
			if (widget.get_active()) {
				wscreen.get_windows_stacked().foreach(record_windows_state);
			} else {
				window_list.foreach(unminimize_windows);
			}
		});

		add(widget);
		show_all();
	}

	private void record_windows_state(Wnck.Window window) {
		if (window.is_skip_pager() || window.is_skip_tasklist()) {
			return;
		}

		window.state_changed.connect(() => {
			if (!window.is_minimized()) {
				window_list = new List<ulong>();
				widget.set_active(false);
			}
		});

		if (!window.is_minimized()) {
			window_list.append(window.get_xid());
			window.minimize();
		}
	}

	private void unminimize_windows(ulong xid) {
		var window = Wnck.Window.@get(xid);

		if (window != null && window.is_minimized()) {
			window.unminimize(Gtk.get_current_event_time());
		}
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(ShowDesktopPlugin));
}

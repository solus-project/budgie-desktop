/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2014-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class ClockPlugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new ClockApplet();
	}
}

enum ClockFormat {
	TWENTYFOUR = 0,
	TWELVE = 1;
}

public const string CALENDAR_MIME = "text/calendar";

public class ClockApplet : Budgie.Applet {
	protected Gtk.EventBox widget;
	protected Gtk.Box layout;
	protected Gtk.Label clock;
	protected Gtk.Label date_label;
	protected Gtk.Label seconds_label;

	protected bool ampm = false;

	private DateTime time;

	protected Settings settings;

	Budgie.Popover? popover = null;
	AppInfo? calprov = null;
	Gtk.Button cal_button;
	Gtk.CheckButton clock_format;
	Gtk.CheckButton check_seconds;
	Gtk.CheckButton check_date;
	ulong check_id;

	Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;

	private unowned Budgie.PopoverManager? manager = null;

	// Make a fancy button with a direction indicator
	Gtk.Button new_directional_button(string label_str, Gtk.PositionType arrow_direction) {
		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		box.halign = Gtk.Align.FILL;
		var label = new Gtk.Label(label_str);
		var button = new Gtk.Button();
		var image = new Gtk.Image();

		if (arrow_direction == Gtk.PositionType.RIGHT) {
			image.set_from_icon_name("go-next-symbolic", Gtk.IconSize.MENU);
			box.pack_start(label, true, true, 0);
			box.pack_end(image, false, false, 1);
			image.margin_start = 6;
			label.margin_start = 6;
		} else {
			image.set_from_icon_name("go-previous-symbolic", Gtk.IconSize.MENU);
			box.pack_start(image, false, false, 0);
			box.pack_start(label, true, true, 0);
			image.margin_end = 6;
		}

		label.halign = Gtk.Align.START;
		label.margin = 0;
		box.margin = 0;
		box.border_width = 0;
		button.get_style_context().add_class(Gtk.STYLE_CLASS_FLAT);
		button.add(box);
		return button;
	}

	Gtk.Button new_plain_button(string label_str) {
		Gtk.Button ret = new Gtk.Button.with_label(label_str);
		ret.get_child().halign = Gtk.Align.START;
		ret.get_style_context().add_class(Gtk.STYLE_CLASS_FLAT);

		return ret;
	}

	public override void panel_position_changed(Budgie.PanelPosition position) {
		if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
			this.orient = Gtk.Orientation.VERTICAL;
		} else {
			this.orient = Gtk.Orientation.HORIZONTAL;
		}
		this.seconds_label.set_text("");
		this.layout.set_orientation(this.orient);
		this.update_clock();
	}

	public ClockApplet() {
		widget = new Gtk.EventBox();
		layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);

		clock = new Gtk.Label("");
		time = new DateTime.now_local();
		widget.add(layout);

		layout.pack_start(clock, false, false, 0);
		layout.margin = 0;
		layout.border_width = 0;

		seconds_label = new Gtk.Label("");
		seconds_label.get_style_context().add_class("dim-label");
		layout.pack_start(seconds_label, false, false, 0);
		seconds_label.no_show_all = true;
		seconds_label.hide();

		date_label = new Gtk.Label("");
		layout.pack_start(date_label, false, false, 0);
		date_label.no_show_all = true;
		date_label.hide();

		clock.valign = Gtk.Align.CENTER;
		seconds_label.valign = Gtk.Align.CENTER;
		date_label.valign = Gtk.Align.CENTER;

		settings = new Settings("org.gnome.desktop.interface");

		get_style_context().add_class("budgie-clock-applet");

		// Create a submenu system
		popover = new Budgie.Popover(widget);

		var stack = new Gtk.Stack();
		stack.get_style_context().add_class("clock-applet-stack");

		popover.add(stack);
		stack.set_homogeneous(true);
		stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

		var menu = new Gtk.Box(Gtk.Orientation.VERTICAL, 1);
		menu.border_width = 6;

		var time_button = this.new_plain_button(_("Time and date settings"));
		cal_button = this.new_plain_button(_("Calendar"));
		time_button.clicked.connect(on_date_activate);
		cal_button.clicked.connect(on_cal_activate);

		// menu page 1
		menu.pack_start(time_button, false, false, 0);
		menu.pack_start(cal_button, false, false, 0);
		var sub_button = this.new_directional_button(_("Preferences"), Gtk.PositionType.RIGHT);
		sub_button.clicked.connect(() => { stack.set_visible_child_name("prefs"); });
		menu.pack_end(sub_button, false, false, 2);

		stack.add_named(menu, "root");

		// page2
		menu = new Gtk.Box(Gtk.Orientation.VERTICAL, 1);
		menu.border_width = 6;

		check_date = new Gtk.CheckButton.with_label(_("Show date"));
		check_date.get_child().set_property("margin-start", 8);
		settings.bind("clock-show-date", check_date, "active", SettingsBindFlags.GET|SettingsBindFlags.SET);
		settings.bind("clock-show-date", date_label, "visible", SettingsBindFlags.DEFAULT);

		check_seconds = new Gtk.CheckButton.with_label(_("Show seconds"));
		check_seconds.get_child().set_property("margin-start", 8);

		settings.bind("clock-show-seconds", check_seconds, "active", SettingsBindFlags.GET|SettingsBindFlags.SET);
		settings.bind("clock-show-seconds", seconds_label, "visible", SettingsBindFlags.DEFAULT);

		clock_format = new Gtk.CheckButton.with_label(_("Use 24 hour time"));
		clock_format.get_child().set_property("margin-start", 8);

		check_id = clock_format.toggled.connect_after(() => {
			ClockFormat f = (ClockFormat)settings.get_enum("clock-format");
			ClockFormat newf = f == ClockFormat.TWELVE ? ClockFormat.TWENTYFOUR : ClockFormat.TWELVE;
			this.settings.set_enum("clock-format", newf);
		});

		// pack page2
		sub_button = this.new_directional_button(_("Preferences"), Gtk.PositionType.LEFT);
		sub_button.clicked.connect(() => { stack.set_visible_child_name("root"); });
		menu.pack_start(sub_button, false, false, 0);
		menu.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false, 2);
		menu.pack_start(check_date, false, false, 0);
		menu.pack_start(check_seconds, false, false, 0);
		menu.pack_start(clock_format, false, false, 0);
		stack.add_named(menu, "prefs");


		// Always open to the root page
		popover.closed.connect(() => {
			stack.set_visible_child_name("root");
		});

		widget.button_press_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			if (popover.get_visible()) {
				popover.hide();
			} else {
				this.manager.show_popover(widget);
			}
			return Gdk.EVENT_STOP;
		});

		Timeout.add_seconds_full(Priority.LOW, 1, update_clock);

		settings.changed.connect(on_settings_change);

		calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);

		var monitor = AppInfoMonitor.get();
		monitor.changed.connect(update_cal);

		cal_button.set_sensitive(calprov != null);
		cal_button.clicked.connect(on_cal_activate);

		update_cal();

		update_clock();
		add(widget);
		on_settings_change("clock-format");
		popover.get_child().show_all();

		show_all();
	}

	void update_cal() {
		calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
		cal_button.set_sensitive(calprov != null);
	}

	void on_date_activate() {
		this.popover.hide();
		var app_info = new DesktopAppInfo("gnome-datetime-panel.desktop");

		if (app_info == null) {
			return;
		}
		try {
			app_info.launch(null, null);
		} catch (Error e) {
			message("Unable to launch gnome-datetime-panel.desktop: %s", e.message);
		}
	}

	void on_cal_activate() {
		this.popover.hide();

		if (calprov == null) {
			return;
		}
		try {
			calprov.launch(null, null);
		} catch (Error e) {
			message("Unable to launch %s: %s", calprov.get_name(), e.message);
		}
	}

	public override void update_popovers(Budgie.PopoverManager? manager) {
		this.manager = manager;
		manager.register_popover(widget, popover);
	}

	protected void on_settings_change(string key) {
		switch (key) {
			case "clock-format":
				SignalHandler.block((void*)this.clock_format, this.check_id);
				ClockFormat f = (ClockFormat)settings.get_enum(key);
				ampm = f == ClockFormat.TWELVE;
				clock_format.set_active(f == ClockFormat.TWENTYFOUR);
				this.update_clock();
				SignalHandler.unblock((void*)this.clock_format, this.check_id);
				break;
			case "clock-show-seconds":
			case "clock-show-date":
				this.update_clock();
				break;
		}
	}


	/**
	 * Update the date if necessary
	 */
	protected void update_date() {
		if (!check_date.get_active()) {
			return;
		}
		string ftime;
		if (this.orient == Gtk.Orientation.HORIZONTAL) {
			ftime = "%x";
		} else {
			ftime = "<small>%b %d</small>";
		}

		// Prevent unnecessary redraws
		var old = date_label.get_label();
		var ctime = time.format(ftime);
		if (old == ctime) {
			return;
		}

		date_label.set_markup(ctime);
	}

	/**
	 * Update the seconds if necessary
	 */
	protected void update_seconds() {
		if (!check_seconds.get_active()) {
			return;
		}
		string ftime;
		if (this.orient == Gtk.Orientation.HORIZONTAL) {
			ftime = "";
		} else {
			ftime = "<big>%S</big>";
		}

		// Prevent unnecessary redraws
		var old = date_label.get_label();
		var ctime = time.format(ftime);
		if (old == ctime) {
			return;
		}

		seconds_label.set_markup(ctime);
	}

	/**
	 * This is called once every second, updating the time
	 */
	protected bool update_clock() {
		time = new DateTime.now_local();
		string format;


		if (ampm) {
			format = "%l:%M";
		} else {
			format = "%H:%M";
		}

		if (orient == Gtk.Orientation.HORIZONTAL) {
			if (check_seconds.get_active()) {
				format += ":%S";
			}
		}

		if (ampm) {
			format += " %p";
		}

		string ftime;
		if (this.orient == Gtk.Orientation.HORIZONTAL) {
			ftime = " %s ".printf(format);
		} else {
			ftime = " <small>%s</small> ".printf(format);
		}

		this.update_date();
		this.update_seconds();

		// Prevent unnecessary redraws
		var old = clock.get_label();
		var ctime = time.format(ftime);
		if (old == ctime) {
			return true;
		}

		clock.set_markup(ctime);
		this.queue_draw();

		return true;
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(ClockPlugin));
}

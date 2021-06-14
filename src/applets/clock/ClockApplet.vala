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
		return new ClockApplet(uuid);
	}
}

public const string CALENDAR_MIME = "text/calendar";

public class ClockApplet : Budgie.Applet {
	protected Gtk.EventBox widget;
	protected Gtk.Box layout;
	protected Gtk.Label clock_label;
	protected Gtk.Label date_label;
	protected Gtk.Label seconds_label;


	private DateTime time;

	protected Settings settings;

	Budgie.Popover? popover = null;
	AppInfo? calprov = null;
	Gtk.Button cal_button;

	Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;

	private unowned Budgie.PopoverManager? manager = null;


	private bool clock_show_date;
	private bool clock_show_seconds;
	private bool clock_use_24_hour_time;
	private bool clock_use_custom_format;
	private string clock_custom_format;
	private TimeZone clock_timezone;

	public string uuid { public set; public get; }

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

	public ClockApplet(string uuid) {
		Object(uuid: uuid);

		settings_schema = "com.solus-project.clock";
		settings_prefix = "/com/solus-project/clock/instance/clock";


		this.settings = this.get_applet_settings(uuid);

		widget = new Gtk.EventBox();
		layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
		widget.add(layout);


		clock_label = new Gtk.Label("");
		layout.pack_start(clock_label, false, false, 0);
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

		clock_label.valign = Gtk.Align.CENTER;
		seconds_label.valign = Gtk.Align.CENTER;
		date_label.valign = Gtk.Align.CENTER;

		get_style_context().add_class("budgie-clock-applet");

		// Create a submenu system
		popover = new Budgie.Popover(widget);

		var stack = new Gtk.Stack();
		stack.get_style_context().add_class("clock-applet-stack");

		popover.add(stack);
		stack.set_homogeneous(false);
		stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

		var menu = new Gtk.Box(Gtk.Orientation.VERTICAL, 1);
		menu.border_width = 6;

		var time_button = this.new_plain_button(_("System time and date settings"));
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

		var check_date = new Gtk.CheckButton.with_label(_("Show date"));
		check_date.get_child().set_property("margin-start", 8);

		var check_seconds = new Gtk.CheckButton.with_label(_("Show seconds"));
		check_seconds.get_child().set_property("margin-start", 8);


		var clock_format = new Gtk.CheckButton.with_label(_("Use 24 hour time"));
		clock_format.get_child().set_property("margin-start", 8);


		// pack page2
		sub_button = this.new_directional_button(_("Preferences"), Gtk.PositionType.LEFT);
		sub_button.clicked.connect(() => { stack.set_visible_child_name("root"); });
		menu.pack_start(sub_button, false, false, 0);
		menu.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false, 2);
		menu.pack_start(get_settings_ui(), false, false, 0);
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

		

		// make sure every setting is ready
		this.update_setting("clock-show-date");
		this.update_setting("clock-show-seconds");
		this.update_setting("clock-use-24-hour-time");
		this.update_setting("clock-use-custom-format");
		this.update_setting("clock-custom-format");
		this.update_setting("clock-use-custom-timezone");
		this.update_setting("clock-custom-timezone");

		Timeout.add_seconds_full(Priority.LOW, 1, update_clock);

		settings.changed.connect(on_settings_change);

		calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);

		var monitor = AppInfoMonitor.get();
		monitor.changed.connect(update_cal);

		cal_button.set_sensitive(calprov != null);
		cal_button.clicked.connect(on_cal_activate);

		update_cal();

		
		add(widget);


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

	private void update_setting(string key) {
		switch (key) {
			case "clock-show-date":
				this.clock_show_date = settings.get_boolean(key);
				this.date_label.set_visible(this.clock_show_date);
				break;
			case "clock-show-seconds":
				this.clock_show_seconds = settings.get_boolean(key);
				this.seconds_label.set_visible(this.clock_show_seconds);
				break;
			case "clock-use-24-hour-time":
				this.clock_use_24_hour_time = settings.get_boolean(key);
				break;
			case "clock-use-custom-format":
				this.clock_use_custom_format = settings.get_boolean(key);
				this.date_label.set_visible(!this.clock_use_custom_format);
				this.seconds_label.set_visible(!this.clock_use_custom_format);
				break;
			case "clock-custom-format":
				this.clock_custom_format = settings.get_string(key);
				break;
			case "clock-use-custom-timezone":
			case "clock-custom-timezone":
				if (settings.get_boolean("clock-use-custom-timezone")) {
					this.clock_timezone = new TimeZone(settings.get_string("clock-custom-timezone"));
				} else {
					this.clock_timezone = new TimeZone.local();
				}
				break;
		}
	}

	protected void on_settings_change(string key) {
		update_setting(key);
		update_clock();
	}


	/**
	 * Update the date if necessary
	 */
	protected void update_date() {
		if (!this.clock_show_date || this.clock_use_custom_format) {
			return;
		}
		string ftime;
		if (this.orient == Gtk.Orientation.HORIZONTAL) {
			ftime = "%x";
		} else {
			ftime = "<small>%b %d</small>";
		}

		// Prevent unnecessary redraws
		var old = this.date_label.get_label();
		var ctime = this.time.format(ftime);
		if (old == ctime) {
			return;
		}
		this.date_label.set_markup(ctime);
	}

	/**
	 * Update the seconds if necessary
	 */
	protected void update_seconds() {
		if (!this.clock_show_seconds || this.clock_use_custom_format) {
			return;
		}
		string ftime;
		if (this.orient == Gtk.Orientation.HORIZONTAL) {
			ftime = "";
		} else {
			ftime = "<big>%S</big>";
		}

		// Prevent unnecessary redraws
		var old = this.seconds_label.get_label();
		var ctime = this.time.format(ftime);
		if (old == ctime) {
			return;
		}

		this.seconds_label.set_markup(ctime);
	}

	/**
	 * This is called once every second, updating the time
	 */
	protected bool update_clock() {
		this.time = new DateTime.now(this.clock_timezone);
		
		string format;
		if (!this.clock_use_custom_format) {
			if (!this.clock_use_24_hour_time) {
				format = "%l:%M";
			} else {
				format = "%H:%M";
			}

			if (orient == Gtk.Orientation.HORIZONTAL) {
				if (this.clock_show_seconds) {
					format += ":%S";
				}
			}

			if (!this.clock_use_24_hour_time) {
				format += " %p";
			}
		} else {
			format = this.clock_custom_format;
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
		var old = this.clock_label.get_label();
		var ctime = this.time.format(ftime);
		if (old == ctime) {
			return true;
		}

		this.clock_label.set_markup(ctime);
		this.queue_draw();

		return true;
	}

	public override bool supports_settings() {
		return true;
	}

	public override Gtk.Widget? get_settings_ui() {
		return new ClockSettings(this.get_applet_settings(uuid));
	}
}


[GtkTemplate (ui="/com/solus-project/clock/settings.ui")]
public class ClockSettings : Gtk.Grid {

	[GtkChild]
	private Gtk.Switch? swShowDate;

	[GtkChild]
	private Gtk.Switch? swShowSeconds;

	[GtkChild]
	private Gtk.Switch? swUse24HourTime;

	[GtkChild]
	private Gtk.Switch? swCustomFormat;

	[GtkChild]
	private Gtk.Entry? txtFormat;
	
	[GtkChild]
	private Gtk.Switch? swCustomTimezone;

	[GtkChild]
	private Gtk.Entry? txtTimezone;

	public ClockSettings(Settings? settings) {
		settings.bind("clock-show-date", this.swShowDate, "active", SettingsBindFlags.DEFAULT);
		settings.bind("clock-show-seconds", this.swShowSeconds, "active", SettingsBindFlags.DEFAULT);
		settings.bind("clock-use-24-hour-time", this.swUse24HourTime, "active", SettingsBindFlags.DEFAULT);
		settings.bind("clock-use-custom-format", this.swCustomFormat, "active", SettingsBindFlags.DEFAULT);
		settings.bind("clock-custom-format", this.txtFormat, "text", SettingsBindFlags.DEFAULT);
		settings.bind("clock-use-custom-timezone", this.swCustomTimezone, "active", SettingsBindFlags.DEFAULT);
		settings.bind("clock-custom-timezone", this.txtTimezone, "text", SettingsBindFlags.DEFAULT);

		this.swCustomFormat.notify["active"].connect(this.updateSensitve);
		this.swCustomTimezone.notify["active"].connect(this.updateSensitve);

		this.updateSensitve();
	}

	private void updateSensitve() {
		var useCustomFormat = this.swCustomFormat.get_active();
		this.swShowDate.set_sensitive(!useCustomFormat);
		this.swShowSeconds.set_sensitive(!useCustomFormat);
		this.swUse24HourTime.set_sensitive(!useCustomFormat);
		this.txtFormat.set_sensitive(useCustomFormat);

		this.txtTimezone.set_sensitive(this.swCustomTimezone.get_active());
	}

}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(ClockPlugin));
}

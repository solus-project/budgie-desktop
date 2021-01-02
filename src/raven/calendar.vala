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


const string ENABLE_WEEK_NUM = "enable-week-numbers";

public class CalendarWidget : RavenWidget {
	private Budgie.HeaderWidget? header = null;
	private Gtk.Calendar? cal = null;
	private unowned Settings settings = null;

	private const string date_format = "%e %b %Y";

	public CalendarWidget(Settings c_settings) {
		Object(orientation: Gtk.Orientation.VERTICAL);
		this.settings = c_settings;

		var time = new DateTime.now_local();
		header = new Budgie.HeaderWidget(time.format(date_format), "x-office-calendar-symbolic", false);
		var expander = new Budgie.RavenExpander(header);
		expander.expanded = true;

		this.pack_start(expander, false, false, 0);

		cal = new Gtk.Calendar();
		cal.get_style_context().add_class("raven-calendar");
		var ebox = new Gtk.EventBox();
		ebox.get_style_context().add_class("raven-background");
		ebox.add(cal);
		expander.add(ebox);

		Timeout.add_seconds_full(Priority.LOW, 30, this.update_date);

		cal.month_changed.connect(() => {
			update_date();
		});

		this.settings.changed.connect((key) => {
			if (key == ENABLE_WEEK_NUM) {
				set_week_number();
			} else {
				return;
			}
		});

		set_week_number();
	}

	/**
	 * set_week_number will set the display of the week number
	 */
	private void set_week_number() {
		bool show = false;

		if (this.settings != null) {
			show = this.settings.get_boolean(ENABLE_WEEK_NUM);
		}

		this.cal.show_week_numbers = show;
	}

	private bool update_date() {
		var time = new DateTime.now_local();
		var strf = time.format(date_format);
		header.text = strf;
		cal.day = (cal.month + 1) == time.get_month() && cal.year == time.get_year() ? time.get_day_of_month() : 0;
		return true;
	}
}

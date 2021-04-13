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

const int icon_size = 32;

public class TasklistPlugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new TasklistApplet();
	}
}

public class TasklistApplet : Budgie.Applet {
	Gtk.ScrolledWindow? scroller;
	Wnck.Tasklist? tlist;

	public TasklistApplet() {
		scroller = new Gtk.ScrolledWindow(null, null);
		tlist = new Wnck.Tasklist();

		scroller.overlay_scrolling = true;
		scroller.propagate_natural_height = true;
		scroller.propagate_natural_width = true;
		scroller.shadow_type = Gtk.ShadowType.NONE;
		scroller.hscrollbar_policy = Gtk.PolicyType.EXTERNAL;
		scroller.vscrollbar_policy = Gtk.PolicyType.NEVER;

		tlist.set_scroll_enabled(false);

		scroller.add(tlist);
		add(scroller);

		tlist.set_grouping(Wnck.TasklistGroupingType.AUTO_GROUP);

		add_events(Gdk.EventMask.SCROLL_MASK);
		show_all();
	}

	public override bool scroll_event(Gdk.EventScroll event) {
		if (event.direction == Gdk.ScrollDirection.UP) { // Scrolling up
			scroller.hadjustment.value-=50;
		} else { // Scrolling down
			scroller.hadjustment.value+=50; // Always increment by 50
		}

		return Gdk.EVENT_STOP;
	}

	/**
	 * Update the tasklist orientation to match the panel direction
	 */
	public override void panel_position_changed(Budgie.PanelPosition position) {
		Gtk.Orientation orientation = Gtk.Orientation.HORIZONTAL;
		if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
			orientation = Gtk.Orientation.VERTICAL;
		}
		tlist.set_orientation(orientation);
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(TasklistPlugin));
}

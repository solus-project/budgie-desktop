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

public const string RAVEN_DBUS_NAME = "org.budgie_desktop.Raven";
public const string RAVEN_DBUS_OBJECT_PATH = "/org/budgie_desktop/Raven";

[DBus (name="org.budgie_desktop.Raven")]
public interface RavenTriggerProxy : GLib.Object {
	public abstract async void ToggleAppletView() throws Error;
	public abstract bool GetExpanded() throws Error;
	public abstract bool GetLeftAnchored() throws Error;
	public abstract signal void ExpansionChanged(bool expanded);
	public abstract signal void AnchorChanged(bool left_anchor);
}

public class RavenTriggerPlugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new RavenTriggerApplet();
	}
}

public class RavenTriggerApplet : Budgie.Applet {
	protected Gtk.Button widget;
	protected Gtk.Image img_expanded;
	protected Gtk.Image img_hidden;
	protected Gtk.Stack img_stack;

	private RavenTriggerProxy? raven_proxy = null;
	private bool raven_expanded = false;

	private string raven_show_icon = "pane-show-symbolic";
	private string raven_hide_icon = "pane-hide-symbolic";

	public RavenTriggerApplet() {
		widget = new Gtk.Button();
		widget.clicked.connect_after(on_button_clicked);
		widget.relief = Gtk.ReliefStyle.NONE;
		widget.set_can_focus(false);
		widget.get_style_context().add_class("raven-trigger");

		img_hidden = new Gtk.Image.from_icon_name(this.raven_show_icon, Gtk.IconSize.BUTTON);
		img_expanded = new Gtk.Image.from_icon_name(this.raven_hide_icon, Gtk.IconSize.BUTTON);

		img_stack = new Gtk.Stack();
		img_stack.add_named(img_hidden, "hidden");
		img_stack.add_named(img_expanded, "expanded");
		img_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);

		widget.add(img_stack);
		add(widget);
		show_all();

		get_raven();
	}

	/**
	 * Schedule toggle_raven on the idle loop
	 */
	void on_button_clicked() {
		Idle.add(this.toggle_raven);
	}

	/**
	 * Toggle the Raven Applet View, we'll update view state on callback
	 */
	private bool toggle_raven() {
		if (raven_proxy == null) {
			return false;
		}
		try {
			raven_proxy.ToggleAppletView.begin();
		} catch (Error e) {
			message("Error in dbus: %s", e.message);
		}
		return false;
	}

	/**
	 * Asynchronously fetch a Raven proxy
	 */
	void get_raven() {
		if (raven_proxy == null) {
			Bus.get_proxy.begin<RavenTriggerProxy>(BusType.SESSION, RAVEN_DBUS_NAME, RAVEN_DBUS_OBJECT_PATH, 0, null, on_raven_get);
		}
	}

	/**
	 * Handle Raven expansion state changing
	 */
	void on_prop_changed(bool expanded) {
		raven_expanded = expanded;

		if (raven_expanded) {
			img_stack.set_visible_child_name("expanded");
		} else {
			img_stack.set_visible_child_name("hidden");
		}
	}

	private void on_anchor_changed(bool left_anchor) {
		if (left_anchor) {
			this.raven_show_icon = "pane-hide-symbolic";
			this.raven_hide_icon = "pane-show-symbolic";
		} else {
			this.raven_show_icon = "pane-show-symbolic";
			this.raven_hide_icon = "pane-hide-symbolic";
		}

		img_hidden.set_from_icon_name(this.raven_show_icon, Gtk.IconSize.BUTTON);
		img_expanded.set_from_icon_name(this.raven_hide_icon, Gtk.IconSize.BUTTON);
	}

	// Horrific work around to stop us getting caught up in our own dbus
	// spam
	private void* update_anchors() {
		bool b;
		try {
			b = raven_proxy.GetLeftAnchored();
		} catch (Error e) {
			warning("Failed to get left anchored status of raven trigger for update: %s", e.message);
			return null;
		}

		Gdk.threads_enter();
		this.on_anchor_changed(b);
		Gdk.threads_leave();
		return null;
	}

	/* Hold onto our Raven proxy ref */
	void on_raven_get(Object? o, AsyncResult? res) {
		try {
			raven_proxy = Bus.get_proxy.end(res);
			raven_proxy.ExpansionChanged.connect_after((e) => {
				Idle.add(() => {
					on_prop_changed(e);
					return false;
				});
			});
			raven_proxy.AnchorChanged.connect((e) => {
				Idle.add(() => {
					on_anchor_changed(e);
					return false;
				});
			});

			/* Stop Vala from getting scared. */
			unowned Thread<void*> t = Thread.create<void*>(this.update_anchors, false);
		} catch (Error e) {
			warning("Failed to gain Raven proxy: %s", e.message);
		}
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(RavenTriggerPlugin));
}

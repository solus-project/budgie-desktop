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

public class BudgieMenu : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new BudgieMenuApplet(uuid);
	}
}

[GtkTemplate (ui="/com/solus-project/budgie-menu/settings.ui")]
public class BudgieMenuSettings : Gtk.Grid {
	[GtkChild]
	private Gtk.Switch? switch_menu_label;

	[GtkChild]
	private Gtk.Switch? switch_menu_compact;

	[GtkChild]
	private Gtk.Switch? switch_menu_headers;

	[GtkChild]
	private Gtk.Switch? switch_menu_categories_hover;

	[GtkChild]
	private Gtk.Entry? entry_label;

	[GtkChild]
	private Gtk.Entry? entry_icon_pick;

	[GtkChild]
	private Gtk.Button? button_icon_pick;

	private Settings? settings;

	public BudgieMenuSettings(Settings? settings) {
		this.settings = settings;
		settings.bind("enable-menu-label", switch_menu_label, "active", SettingsBindFlags.DEFAULT);
		settings.bind("menu-compact", switch_menu_compact, "active", SettingsBindFlags.DEFAULT);
		settings.bind("menu-headers", switch_menu_headers, "active", SettingsBindFlags.DEFAULT);
		settings.bind("menu-categories-hover", switch_menu_categories_hover, "active", SettingsBindFlags.DEFAULT);
		settings.bind("menu-label", entry_label, "text", SettingsBindFlags.DEFAULT);
		settings.bind("menu-icon", entry_icon_pick, "text", SettingsBindFlags.DEFAULT);

		this.button_icon_pick.clicked.connect(on_pick_click);
	}

	/**
	 * Handle the icon picker
	 */
	void on_pick_click() {
		IconChooser chooser = new IconChooser(this.get_toplevel() as Gtk.Window);
		string? response = chooser.run();
		chooser.destroy();
		if (response != null) {
			this.entry_icon_pick.set_text(response);
		}
	}
}

public class BudgieMenuApplet : Budgie.Applet {
	protected Gtk.ToggleButton widget;
	protected BudgieMenuWindow? popover;
	protected Settings settings;
	Gtk.Image img;
	Gtk.Label label;
	Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;
	int pixel_size = 32;

	private unowned Budgie.PopoverManager? manager = null;

	public string uuid { public set ; public get; }

	public override Gtk.Widget? get_settings_ui() {
		return new BudgieMenuSettings(this.get_applet_settings(uuid));
	}

	public override bool supports_settings() {
		return true;
	}

	public BudgieMenuApplet(string uuid) {
		Object(uuid: uuid);

		settings_schema = "com.solus-project.budgie-menu";
		settings_prefix = "/com/solus-project/budgie-panel/instance/budgie-menu";

		settings = this.get_applet_settings(uuid);

		settings.changed.connect(on_settings_changed);

		widget = new Gtk.ToggleButton();
		widget.relief = Gtk.ReliefStyle.NONE;
		img = new Gtk.Image.from_icon_name("view-grid-symbolic", Gtk.IconSize.INVALID);
		img.pixel_size = pixel_size;
		img.no_show_all = true;

		var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		layout.pack_start(img, true, true, 0);
		label = new Gtk.Label("");
		label.halign = Gtk.Align.START;
		layout.pack_start(label, true, true, 3);

		widget.add(layout);

		// Better styling to fit in with the budgie-panel
		var st = widget.get_style_context();
		st.add_class("budgie-menu-launcher");
		st.add_class("panel-button");
		popover = new BudgieMenuWindow(settings, widget);
		popover.bind_property("visible", widget, "active");

		widget.button_press_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			if (popover.get_visible()) {
				popover.hide();
			} else {
				popover.get_child().show_all();
				this.manager.show_popover(widget);
			}
			return Gdk.EVENT_STOP;
		});

		popover.get_child().show_all();

		supported_actions = Budgie.PanelAction.MENU;

		add(widget);
		show_all();
		layout.valign = Gtk.Align.CENTER;
		valign = Gtk.Align.FILL;
		halign = Gtk.Align.FILL;
		on_settings_changed("enable-menu-label");
		on_settings_changed("menu-icon");
		on_settings_changed("menu-label");

		/* Potentially reload icon on pixel size jumps */
		panel_size_changed.connect((p, i, s) => {
			if (this.pixel_size != i) {
				this.pixel_size = (int)i;
				this.on_settings_changed("menu-icon");
			}
		});

		popover.key_release_event.connect((e) => {
			if (e.keyval == Gdk.Key.Escape) {
				popover.hide();
			}
			return Gdk.EVENT_PROPAGATE;
		});
	}

	public override void panel_position_changed(Budgie.PanelPosition position) {
		this.panel_position = position;
		bool vertical = (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT);
		int margin = vertical ? 0 : 3;
		img.set_margin_end(margin);
		on_settings_changed("enable-menu-label");
	}

	public override void invoke_action(Budgie.PanelAction action) {
		if ((action & Budgie.PanelAction.MENU) != 0) {
			if (popover.get_visible()) {
				popover.hide();
			} else {
				popover.get_child().show_all();
				this.manager.show_popover(widget);
			}
		}
	}

	protected void on_settings_changed(string key) {
		bool should_show = true;

		switch (key) {
			case "menu-icon":
				string? icon = settings.get_string(key);
				if ("/" in icon) {
					try {
						Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(icon);
						img.set_from_pixbuf(pixbuf.scale_simple(this.pixel_size, this.pixel_size, Gdk.InterpType.BILINEAR));
					} catch (Error e) {
						warning("Failed to update Budgie Menu applet icon: %s", e.message);
						img.set_from_icon_name("view-grid-symbolic", Gtk.IconSize.INVALID); // Revert to view-grid-symbolic
					}
				} else if (icon == "") {
					should_show = false;
				} else {
					img.set_from_icon_name(icon, Gtk.IconSize.INVALID);
				}
				img.set_pixel_size(this.pixel_size);
				img.set_visible(should_show);
				break;
			case "menu-label":
				label.set_label(settings.get_string(key));
				break;
			case "enable-menu-label":
				bool visible = (panel_position == Budgie.PanelPosition.TOP ||
								panel_position == Budgie.PanelPosition.BOTTOM) &&
								settings.get_boolean(key);
				label.set_visible(visible);
				break;
			default:
				break;
		}
	}

	public override void update_popovers(Budgie.PopoverManager? manager) {
		this.manager = manager;
		manager.register_popover(widget, popover);
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(BudgieMenu));
}

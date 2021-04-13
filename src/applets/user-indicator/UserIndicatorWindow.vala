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

public const string ACCOUNTSSERVICE_ACC = "org.freedesktop.Accounts";
public const string ACCOUNTSSERVICE_USER = "org.freedesktop.Accounts.User";
public const string LOGIND_LOGIN = "org.freedesktop.login1";
public const string G_SESSION = "org.gnome.SessionManager";

public const string UNABLE_CONTACT = "Unable to contact ";

public class UserIndicatorWindow : Budgie.Popover {
	public Gtk.Box? menu = null;
	public Gtk.Revealer? user_section = null;

	private ScreenSaver? saver = null;
	private SessionManager? session = null;
	private LogindInterface? logind_interface = null;

	private AccountsInterface? user_manager = null;
	private AccountUserInterface? current_user = null;
	private string? current_username = null;
	private PropertiesInterface? current_user_props = null;

	private IndicatorItem? user_item = null;
	private IndicatorItem? lock_menu = null;
	private IndicatorItem? suspend_menu = null;
	private IndicatorItem? hibernate_menu = null;
	private IndicatorItem? reboot_menu = null;
	private IndicatorItem? shutdown_menu = null;
	private IndicatorItem? logout_menu = null;

	async void setup_dbus() {
		try {
			user_manager = yield Bus.get_proxy(BusType.SYSTEM, ACCOUNTSSERVICE_ACC, "/org/freedesktop/Accounts");

			string uid = user_manager.find_user_by_name(current_username);

			try {
				current_user_props = yield Bus.get_proxy(BusType.SYSTEM, ACCOUNTSSERVICE_ACC, uid);
				update_userinfo();
			} catch (Error e) {
				warning(UNABLE_CONTACT + "Account User Service: %s", e.message);
			}

			try {
				current_user = yield Bus.get_proxy(BusType.SYSTEM, ACCOUNTSSERVICE_ACC, uid);
				current_user.changed.connect(update_userinfo);
			} catch (Error e) {
				warning(UNABLE_CONTACT + "Account User Service: %s", e.message);
			}
		} catch (Error e) {
			warning(UNABLE_CONTACT + "Accounts Service: %s", e.message);
		}

		try {
			logind_interface = yield Bus.get_proxy(BusType.SYSTEM, LOGIND_LOGIN, "/org/freedesktop/login1");
		} catch (Error e) {
			warning(UNABLE_CONTACT + "logind: %s", e.message);
		}

		try {
			saver = yield Bus.get_proxy(BusType.SESSION, "org.gnome.ScreenSaver", "/org/gnome/ScreenSaver");
		} catch (Error e) {
			warning(UNABLE_CONTACT + "gnome-screensaver: %s", e.message);
			return;
		}

		try {
			session = yield Bus.get_proxy(BusType.SESSION, G_SESSION, "/org/gnome/SessionManager");
		} catch (Error e) {
			warning(UNABLE_CONTACT + "GNOME Session: %s", e.message);
		}
	}

	public UserIndicatorWindow(Gtk.Widget? window_parent) {
		Object(relative_to: window_parent);
		current_username = Environment.get_user_name();

		setup_dbus.begin();

		// Menu creation
		menu = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		Gtk.ListBox items = new Gtk.ListBox();

		get_style_context().add_class("user-menu");
		items.get_style_context().add_class("content-box");
		items.set_selection_mode(Gtk.SelectionMode.NONE);

		// User Menu Creation

		user_item = new IndicatorItem(_("User"), USER_SYMBOLIC_ICON, true); // Default to "User" and symbolic icon
		user_section = create_usersection();

		// The rest
		Gtk.Separator separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);

		lock_menu = new IndicatorItem(_("Lock"), "system-lock-screen-symbolic", false);
		suspend_menu = new IndicatorItem(_("Suspend"), "system-suspend-symbolic", false);
		hibernate_menu = new IndicatorItem(_("Hibernate"), "system-hibernate-symbolic", false);
		reboot_menu = new IndicatorItem(_("Restart"), "system-restart-symbolic", false);
		shutdown_menu = new IndicatorItem(_("Shutdown"), "system-shutdown-symbolic", false);

		// Adding stuff
		items.add(user_item);
		items.add(user_section);
		items.add(separator);
		items.add(lock_menu);
		items.add(suspend_menu);
		items.add(hibernate_menu);
		items.add(reboot_menu);
		items.add(shutdown_menu);

		menu.pack_start(items, false, false, 0);
		add(menu);

		set_size_request(250, 0);

		// Events

		user_item.button_release_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			toggle_usersection();
			return Gdk.EVENT_STOP;
		});

		lock_menu.button_release_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			lock_screen();
			return Gdk.EVENT_STOP;
		});

		suspend_menu.button_release_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			suspend();
			return Gdk.EVENT_STOP;
		});

		reboot_menu.button_release_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			reboot();
			return Gdk.EVENT_STOP;
		});

		hibernate_menu.button_release_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			hibernate();
			return Gdk.EVENT_STOP;
		});

		shutdown_menu.button_release_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			shutdown();
			return Gdk.EVENT_STOP;
		});

		this.unmap.connect(hide_usersection); // Ensure User Section is hidden.
	}

	// hide will override so we can unfocus items
	public override void hide() {
		Gtk.Button[] buttons = {
			user_item,
			logout_menu,
			lock_menu,
			suspend_menu,
			reboot_menu,
			hibernate_menu,
			shutdown_menu
		};

		for (var i  = 0; i < buttons.length; i++) {
			Gtk.Button button = buttons[0];

			if (button == null) { // Button doesn't exist
				continue;
			}

			button.has_focus = false;
			button.is_focus = false;
		}

		base.hide();
	}

	private Gtk.Revealer create_usersection() {
		Gtk.Revealer user_section = new Gtk.Revealer();
		Gtk.Box user_section_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		logout_menu = new IndicatorItem(_("Logout"), "system-log-out-symbolic", false);
		user_section_box.pack_start(logout_menu, false, false, 0); // Add the Logout item
		user_section.add(user_section_box); // Add the User Section box

		logout_menu.button_release_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			logout();
			return Gdk.EVENT_STOP;
		});

		return user_section;
	}

	public void toggle_usersection() {
		if (user_section != null){
			if (!user_section.child_revealed) { // If the User Section is not revealed
				show_usersection();
			} else {
				hide_usersection();
			}
		}
	}

	private void show_usersection() {
		if (!user_section.child_revealed) {
			user_section.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
			user_section.reveal_child = true;
			user_item.set_arrow("up");
		}
	}

	private void hide_usersection() {
		if (user_section.child_revealed) {
			user_section.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
			user_section.reveal_child = false;
			user_item.set_arrow("down");
		}
	}

	// Set up User info in user_item
	private void update_userinfo() {
		string user_image = get_user_image();
		string user_name = get_user_name();

		user_item.set_image(user_image); // Ensure we have updated image
		user_item.set_label(user_name); // Ensure we have updated label
	}

	// Get the user image and if we fallback to icon_name
	private string get_user_image() {
		string image = USER_SYMBOLIC_ICON; // Default to symbolic icon

		if (current_user_props != null) {
			try {
				string icon_file = current_user_props.get(ACCOUNTSSERVICE_USER, "IconFile").get_string();
				image = (icon_file != "") ? icon_file : image;
			} catch (Error e) {
				warning("Failed to fetch IconFile: %s", e.message);
			}
		}

		return image;
	}

	// Get the User's name
	private string get_user_name() {
		string user_name = current_username; // Default to current_username

		if (current_user_props != null) {
			try {
				string real_name = current_user_props.get(ACCOUNTSSERVICE_USER, "RealName").get_string();
				user_name = (real_name != "") ? real_name : user_name;
			} catch (Error e) {
				warning("Failed to fetch RealName: %s", e.message);
			}
		}

		return user_name;
	}

	private void logout() {
		hide();
		if (session == null) {
			return;
		}

		Idle.add(() => {
			try {
				session.Logout(0);
			} catch (Error e) {
				warning("Failed to logout: %s", e.message);
			}
			return false;
		});
	}

	private void hibernate() {
		hide();
		if (logind_interface == null) {
			return;
		}

		Idle.add(() => {
			try {
				lock_screen();
				logind_interface.hibernate(false);
			} catch (Error e) {
				warning("Cannot hibernate: %s", e.message);
			}
			return false;
		});
	}

	private void reboot() {
		hide();
		if (session == null) {
			return;
		}

		Idle.add(() => {
			session.Reboot.begin();
			return false;
		});
	}

	private void shutdown() {
		hide();
		if (session == null) {
			return;
		}

		Idle.add(() => {
			session.Shutdown.begin();
			return false;
		});
	}

	private void suspend() {
		hide();
		if (logind_interface == null) {
			return;
		}

		Idle.add(() => {
			try {
				lock_screen();
				logind_interface.suspend(false);
			} catch (Error e) {
				warning("Cannot suspend: %s", e.message);
			}
			return false;
		});
	}

	private void lock_screen() {
		hide();
		Idle.add(() => {
			try {
				saver.lock();
			} catch (Error e) {
				warning("Cannot lock screen: %s", e.message);
			}
			return false;
		});
	}
}

// Individual Indicator Items
public class IndicatorItem : Gtk.Button {
	private Gtk.Box? menu_item = null;
	private Gtk.Image? arrow = null;
	private Gtk.Image? button_image = null;
	private Gtk.Label? button_label = null;

	private string? _image_source = null;
	public string? image_source {
		get { return _image_source; }
		set {
			_image_source = image_source;
			set_image(image_source);
		}
	}

	private string? _label_text = null;
	public string? label_text {
		get { return _label_text; }
		set {
			_label_text = label_text;
			set_label(label_text);
		}
	}

	public IndicatorItem(string label_string, string image_source, bool? add_arrow) {
		menu_item = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);

		set_image(image_source); // Set the image
		set_label(label_string); // Set the label
		set_can_focus(false);

		menu_item.pack_start(button_image, false, false, 0);
		menu_item.pack_start(button_label, false, false, 0);

		if (add_arrow) {
			arrow = new Gtk.Image.from_icon_name("pan-down-symbolic", Gtk.IconSize.MENU);
			menu_item.pack_end(arrow, false, false, 0);
		}

		add(menu_item);
		get_style_context().add_class("indicator-item");
		get_style_context().add_class("flat");
		get_style_context().add_class("menuitem");
	}

	public void set_arrow(string direction) {
		if (arrow == null) {
			return;
		}

		arrow.set_from_icon_name("pan-" + direction + "-symbolic", Gtk.IconSize.MENU);
	}

	public new void set_image(string source) {
		Gdk.Pixbuf pixbuf = null;
		bool has_slash_prefix = source.has_prefix("/");
		bool is_user_image = (has_slash_prefix && !source.has_suffix(".face"));

		source = (has_slash_prefix && !is_user_image) ? USER_SYMBOLIC_ICON : source;

		if (button_image == null) {
			button_image = new Gtk.Image();
		}

		if (is_user_image) { // Valid user image
			try {
				pixbuf = new Gdk.Pixbuf.from_file_at_size(source, 24, 24);
				button_image.set_from_pixbuf(pixbuf);
			} catch (Error e) {
				message("File does not exist: %s", e.message);
			}
		} else {
			button_image.set_from_icon_name(source, Gtk.IconSize.SMALL_TOOLBAR);
		}
	}

	public new void set_label(string text) {
		if (button_label == null) {
			button_label = new Gtk.Label(text);
			button_label.use_markup = true;
		} else {
			button_label.set_label(text);
		}
	}
}

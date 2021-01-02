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

namespace Budgie {
	/**
	* We need to probe the dbus daemon directly, hence this interface
	*/
	[DBus (name="org.freedesktop.DBus")]
	public interface DBusImpl : Object {
		public abstract async string[] list_names() throws DBusError, IOError;
		public signal void name_owner_changed(string name, string old_owner, string new_owner);
	}

	/**
	* Simple launcher button
	*/
	public class AppLauncherButton : Gtk.Box {
		public DesktopAppInfo? app_info = null;

		public AppLauncherButton(DesktopAppInfo? info) {
			Object(orientation: Gtk.Orientation.HORIZONTAL);
			this.app_info = info;

			get_style_context().add_class("launcher-button");
			var image = new Gtk.Image.from_gicon(info.get_icon(), Gtk.IconSize.DIALOG);
			image.pixel_size = 48;
			image.set_margin_start(8);
			pack_start(image, false, false, 0);

			var nom = Markup.escape_text(info.get_name());
			var sdesc = info.get_description();
			if (sdesc == null) {
				sdesc = "";
			}
			var desc = Markup.escape_text(sdesc);
			var label = new Gtk.Label("<big>%s</big>\n<small>%s</small>".printf(nom, desc));
			label.get_style_context().add_class("dim-label");
			label.set_line_wrap(true);
			label.set_property("xalign", 0.0);
			label.use_markup = true;
			label.set_margin_start(12);
			label.set_max_width_chars(60);
			label.set_halign(Gtk.Align.START);
			pack_start(label, false, false, 0);

			set_hexpand(false);
			set_vexpand(false);
			set_halign(Gtk.Align.START);
			set_valign(Gtk.Align.START);
			set_tooltip_text(info.get_name());
			set_margin_top(3);
			set_margin_bottom(3);
		}
	}

	/**
	* The meat of the operation
	*/
	public class RunDialog : Gtk.ApplicationWindow {
		Gtk.Revealer bottom_revealer;
		Gtk.ListBox? app_box;
		Gtk.SearchEntry entry;
		Budgie.ThemeManager theme_manager;
		Gdk.AppLaunchContext context;
		bool focus_quit = true;
		DBusImpl? impl = null;

		string search_text = "";

		/* The .desktop file without the .desktop */
		string wanted_dbus_id = "";

		/* Active dbus names */
		HashTable<string,bool> active_names = null;

		public RunDialog(Gtk.Application app) {
			Object(application: app);
			set_keep_above(true);
			set_skip_pager_hint(true);
			set_skip_taskbar_hint(true);
			set_position(Gtk.WindowPosition.CENTER);
			Gdk.Visual? visual = screen.get_rgba_visual();
			if (visual != null) {
				this.set_visual(visual);
			}

			/* Quicker than a list lookup */
			active_names = new HashTable<string,bool>(str_hash, str_equal);

			context = get_display().get_app_launch_context();
			context.launched.connect(on_launched);
			context.launch_failed.connect(on_launch_failed);

			/* Handle all theme management */
			this.theme_manager = new Budgie.ThemeManager();

			var header = new Gtk.EventBox();
			set_titlebar(header);
			header.get_style_context().remove_class("titlebar");

			get_style_context().add_class("budgie-run-dialog");

			key_release_event.connect(on_key_release);

			var main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			add(main_layout);

			/* Main layout, just a hbox with search-as-you-type */
			var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			main_layout.pack_start(hbox, false, false, 0);

			this.entry = new Gtk.SearchEntry();
			entry.changed.connect(on_search_changed);
			entry.activate.connect(on_search_activate);
			entry.get_style_context().set_junction_sides(Gtk.JunctionSides.BOTTOM);
			hbox.pack_start(entry, true, true, 0);

			bottom_revealer = new Gtk.Revealer();
			main_layout.pack_start(bottom_revealer, true, true, 0);
			app_box = new Gtk.ListBox();
			app_box.set_selection_mode(Gtk.SelectionMode.SINGLE);
			app_box.set_activate_on_single_click(true);
			app_box.row_activated.connect(on_row_activate);
			app_box.set_filter_func(this.on_filter);
			var scroll = new Gtk.ScrolledWindow(null, null);
			scroll.get_style_context().set_junction_sides(Gtk.JunctionSides.TOP);
			scroll.set_size_request(-1, 300);
			scroll.add(app_box);
			scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			bottom_revealer.add(scroll);

			/* Just so I can debug for now */
			bottom_revealer.set_reveal_child(false);

			this.build_app_box();

			set_size_request(420, -1);
			set_default_size(420, -1);
			main_layout.show_all();
			set_border_width(0);
			set_resizable(false);

			focus_out_event.connect(() => {
				if (!this.focus_quit) {
					return Gdk.EVENT_STOP;
				}
				this.application.quit();
				return Gdk.EVENT_STOP;
			});

			setup_dbus.begin();
		}

		/**
		* Handle click/<enter> activation on the main list
		*/
		void on_row_activate(Gtk.ListBoxRow row) {
			var child = ((Gtk.Bin) row).get_child() as AppLauncherButton;
			this.launch_button(child);
		}

		/**
		* Handle <enter> activation on the search
		*/
		void on_search_activate() {
			AppLauncherButton? act = null;
			foreach (var row in app_box.get_children()) {
				if (row.get_visible() && row.get_child_visible()) {
					act = ((Gtk.Bin) row).get_child() as AppLauncherButton;
					break;
				}
			}
			if (act != null) {
				this.launch_button(act);
			}
		}

		/**
		* Launch the given preconfigured button
		*/
		void launch_button(AppLauncherButton button) {
			try {
				var dinfo = button.app_info as DesktopAppInfo;

				context.set_screen(get_screen());
				context.set_timestamp(Gdk.CURRENT_TIME);
				this.focus_quit = false;
				var splits = dinfo.get_id().split(".desktop");
				if (dinfo.get_boolean("DBusActivatable")) {
					this.wanted_dbus_id = string.joinv(".desktop", splits[0:splits.length-1]);
				}
				dinfo.launch(null, context);
				this.check_dbus_name();
				/* Some apps are slow to open so hide and quit when they're done */
				this.hide();
			} catch (Error e) {
				this.application.quit();
			}
		}

		void on_search_changed() {
			this.search_text = entry.get_text().down();
			this.app_box.invalidate_filter();
			Gtk.Widget? active_row = null;

			foreach (var row in app_box.get_children()) {
				if (row.get_visible() && row.get_child_visible()) {
					active_row = row;
					break;
				}
			}

			if (active_row == null) {
				bottom_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
				bottom_revealer.set_reveal_child(false);
			} else {
				bottom_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
				bottom_revealer.set_reveal_child(true);
				app_box.select_row(active_row as Gtk.ListBoxRow);
			}
		}

		/**
		* Filter the list
		*/
		bool on_filter(Gtk.ListBoxRow row) {
			var button = row.get_child() as AppLauncherButton;

			if (search_text == "") {
				return false;
			}

			string? app_name, desc, name, exec;

			/* Ported across from budgie menu */
			app_name = button.app_info.get_display_name();
			if (app_name != null) {
				app_name = app_name.down();
			} else {
				app_name = "";
			}
			desc = button.app_info.get_description();
			if (desc != null) {
				desc = desc.down();
			} else {
				desc = "";
			}
			name = button.app_info.get_name();
			if (name != null) {
				name = name.down();
			} else {
				name = "";
			};
			exec = button.app_info.get_executable();
			if (exec != null) {
				exec = exec.down();
			} else {
				exec = "";
			}
			bool in_keywords = false;
			string[] keywords = button.app_info.get_keywords(); // Get any potential keywords

			if ((keywords != null) && (search_text in keywords)) {
				in_keywords = true;
			}

			return (search_text in app_name || search_text in desc ||
					search_text in name || search_text in exec || in_keywords);
		}

		/**
		* Build the app box in the background
		*/
		void build_app_box() {
			var apps = AppInfo.get_all();
			apps.foreach(this.add_application);
			app_box.show_all();
			this.entry.set_text("");
		}

		void add_application(AppInfo? app_info) {
			if (!app_info.should_show()) {
				return;
			}
			var button = new AppLauncherButton(app_info as DesktopAppInfo);
			app_box.add(button);
			button.show_all();
		}

		/**
		* Be a good citizen and pretend to be a dialog.
		*/
		bool on_key_release(Gdk.EventKey btn) {
			if (btn.keyval == Gdk.Key.Escape) {
				Idle.add(() => {
					this.application.quit();
					return false;
				});
				return Gdk.EVENT_STOP;
			}
			return Gdk.EVENT_PROPAGATE;
		}

		/**
		* Handle startup notification, mark it done, quit
		* We may not get the ID but we'll be told it's launched
		*/
		private void on_launched(AppInfo info, Variant v) {
			Variant? elem;

			var iter = v.iterator();

			while ((elem = iter.next_value()) != null) {
				string? key = null;
				Variant? val = null;

				elem.get("{sv}", out key, out val);

				if (key == null) {
					continue;
				}

				if (!val.is_of_type(VariantType.STRING)) {
					continue;
				}

				if (key != "startup-notification-id") {
					continue;
				}
				get_display().notify_startup_complete(val.get_string());
			}
			this.application.quit();
		}

		/**
		* Set the ID if it exists, quit regardless
		*/
		private void on_launch_failed(string id) {
			get_display().notify_startup_complete(id);
			this.application.quit();
		}


		void on_name_owner_changed(string? n, string? o, string? ne) {
			if (o == "") {
				this.active_names[n] = true;
				this.check_dbus_name();
			} else {
				if (n in this.active_names) {
					this.active_names.remove(n);
				}
			}
		}

		/**
		* Check if our dbus name appeared. if it did, bugger off.
		*/
		void check_dbus_name() {
			if (this.wanted_dbus_id != "" && this.wanted_dbus_id in this.active_names) {
				this.application.quit();
			}
		}

		/**
		* Do basic dbus initialisation
		*/
		public async void setup_dbus() {
			try {
				impl = yield Bus.get_proxy(BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");

				/* Cache the names already active */
				foreach (string name in yield impl.list_names()) {
					this.active_names[name] = true;
				}
				/* Watch for new names */
				impl.name_owner_changed.connect(on_name_owner_changed);
			} catch (Error e) {
				warning("Failed to initialise dbus: %s", e.message);
			}
		}
	}

	/**
	* GtkApplication for single instance wonderness
	*/
	public class RunDialogApp : Gtk.Application {
		private RunDialog? rd = null;

		public RunDialogApp() {
			Object(application_id: "org.budgie_desktop.BudgieRunDialog", flags: 0);
		}

		public override void activate() {
			if (rd == null) {
				rd = new RunDialog(this);
			}
			rd.present();
		}
	}
}

public static int main(string[] args) {
	Intl.setlocale(LocaleCategory.ALL, "");
	Intl.bindtextdomain(Budgie.GETTEXT_PACKAGE, Budgie.LOCALEDIR);
	Intl.bind_textdomain_codeset(Budgie.GETTEXT_PACKAGE, "UTF-8");
	Intl.textdomain(Budgie.GETTEXT_PACKAGE);

	Budgie.RunDialogApp rd = new Budgie.RunDialogApp();
	return rd.run(args);
}

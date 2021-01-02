/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {
	[Compact]
	public class CommandInfo {
		public string title;
		public string description;
		public string command;
	}

	public class AutostartItem : GLib.Object {
		public string id;
		public string filename;
		public string title;
		public string description;
		public string command;
		public string executable;
		public Icon? icon = null;

		construct {
			id = "";
			filename = "";
			title = "";
			description = "";
			command = "";
			executable = "";
		}

		public AutostartItem.from_app_info(DesktopAppInfo info) {
			this.id = info.get_id() ?? "";
			this.filename = info.get_filename() ?? "";
			this.title = info.get_display_name() ?? "";
			this.description = info.get_description() ?? "";
			this.executable = info.get_executable() ?? "";
			this.icon = info.get_icon();
		}

		public AutostartItem.from_command_info(CommandInfo info) {
			this.title = info.title;
			this.description = info.description;
			this.command = info.command;
		}

		public string? make_autostart() {
			DirUtils.create_with_parents(Path.build_path("/", AutostartPage.AUTOSTART_PATH), 00755);
			if (filename != "") {
				string destination_path = Path.build_path("/", AutostartPage.AUTOSTART_PATH, Filename.display_basename(filename));
				File destination = File.new_for_path(destination_path);
				File file = File.new_for_path(filename);
				try {
					file.copy(destination, FileCopyFlags.NONE);
					this.filename = destination_path;
				} catch (Error e) {
					warning(e.message);
					return null;
				}
			} else if (command != "") {
				string destination_path = Path.build_path("/", AutostartPage.AUTOSTART_PATH, @"$title.desktop");
				File file = File.new_for_path(destination_path);
				try {
					FileOutputStream file_stream = file.create(FileCreateFlags.NONE);
					if (file.query_exists()) {
						DataOutputStream data_stream = new DataOutputStream(file_stream);
						data_stream.put_string(@"[Desktop Entry]\nType=Application\nName=$title\nDescription=$description\nExec=$command\n");
						this.filename = file.get_path();
						DesktopAppInfo? info = new DesktopAppInfo.from_filename(file.get_path());
						if (info == null) {
							this.delete();
							return null;
						}
						this.id = info.get_id();
					} else {
						return null;
					}
				} catch (Error e) {
					warning(e.message);
					return null;
				}
			}

			return this.filename;
		}

		public void delete() {
			File file = File.new_for_path(filename);
			try {
				file.delete();
			} catch (Error e) {
				warning(e.message);
			}
			AutostartPage.autostart_files.remove(this.id);
		}
	}

	public class AutostartItemWidget : Gtk.ListBoxRow {
		public AutostartItem autostart_item;
		public bool running;

		public AutostartItemWidget(AutostartItem item, bool show_delete = true, bool running = false) {
			Object(can_focus: false,
				focus_on_click: false);

			this.autostart_item = item;
			this.running = running;

			Gtk.Box main_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
			this.add(main_box);
			main_box.margin = 6;

			Gtk.Image icon;
			if (item.icon != null) {
				icon = new Gtk.Image.from_gicon(item.icon, Gtk.IconSize.INVALID);
			} else {
				icon = new Gtk.Image.from_icon_name("image-missing", Gtk.IconSize.INVALID);
			}
			icon.pixel_size = 48;
			main_box.pack_start(icon, false, false, 0);
			icon.valign = Gtk.Align.CENTER;

			Gtk.Box text_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
			main_box.pack_start(text_box, false, false, 0);
			text_box.valign = Gtk.Align.CENTER;

			string title = item.title;
			title = (title != "") ? Markup.escape_text(title) : "<i>" + _("Untitled") + "</i>";
			Gtk.Label title_label = new Gtk.Label(@"<big>$title</big>");
			text_box.add(title_label);
			title_label.set_use_markup(true);
			title_label.halign = Gtk.Align.START;

			string description = item.description;
			description = (description != "") ? Markup.escape_text(description) : "<i>" + _("No description") + "</i>";
			Gtk.Label desc_label = new Gtk.Label(description);
			text_box.add(desc_label);
			desc_label.set_max_width_chars(35);
			desc_label.set_tooltip_text(description);
			desc_label.set_ellipsize(Pango.EllipsizeMode.END);
			desc_label.set_use_markup(true);
			desc_label.get_style_context().add_class("dim-label");
			desc_label.halign = Gtk.Align.START;

			if (show_delete) {
				Gtk.Button remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic", Gtk.IconSize.MENU);
				main_box.pack_end(remove_button, false, false, 0);
				remove_button.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
				remove_button.get_style_context().add_class("round-button");
				remove_button.valign = Gtk.Align.CENTER;
				remove_button.clicked.connect(() => {
					autostart_item.delete();
					this.destroy();
				});
			}

			if (running) {
				Gtk.Label running_label = new Gtk.Label(_("running"));
				main_box.pack_end(running_label, false, false, 0);
				running_label.get_style_context().add_class("dim-label");
				running_label.valign = Gtk.Align.CENTER;
			}

			this.show_all();
		}
	}

	public class AppChooser : Gtk.Dialog {
		private Gtk.ListBox app_listbox;
		private Gtk.Widget button_ok;
		private Gtk.SearchEntry search_entry;
		private GenericSet<string> running_processes;

		private AutostartItem? selected_item = null;

		public AppChooser(Gtk.Window parent) {
			Object(use_header_bar: 1,
				modal: true,
				title: _("Applications"),
				transient_for: parent);

			running_processes = new GenericSet<string>(str_hash, str_equal);

			get_running_processes();

			Gtk.Box content_area = get_content_area() as Gtk.Box;

			this.add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
			button_ok = this.add_button(_("Add"), Gtk.ResponseType.ACCEPT);
			button_ok.set_sensitive(false);
			button_ok.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);

			Gtk.HeaderBar header_bar = this.get_header_bar() as Gtk.HeaderBar;
			Gtk.ToggleButton search_button = new Gtk.ToggleButton();
			search_button.image = new Gtk.Image.from_icon_name("system-search-symbolic", Gtk.IconSize.MENU);
			header_bar.pack_end(search_button);

			Gtk.SearchBar search_bar = new Gtk.SearchBar();
			content_area.pack_start(search_bar, false, false, 0);
			search_bar.show_all();
			search_button.bind_property("active", search_bar, "search-mode-enabled");
			search_bar.bind_property("search-mode-enabled", search_button, "active");

			this.key_press_event.connect(search_bar.handle_event);

			search_entry = new Gtk.SearchEntry();
			search_bar.add(search_entry);

			search_entry.changed.connect(() => {
				app_listbox.invalidate_filter();
				app_listbox.invalidate_sort();
			});

			Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
			content_area.pack_start(scroll, true, true, 0);
			scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

			app_listbox = new Gtk.ListBox();
			scroll.add(app_listbox);
			app_listbox.set_filter_func(search_filter);
			app_listbox.set_sort_func(sort_function);
			app_listbox.set_activate_on_single_click(false);
			app_listbox.row_selected.connect(row_selected);
			app_listbox.row_activated.connect(row_activated);

			content_area.show_all();

			set_default_size(400, 450);
			set_app_list(AppInfo.get_all());
		}

		private bool search_filter(Gtk.ListBoxRow row) {
			AutostartItem item = ((AutostartItemWidget) row).autostart_item;
			if (AutostartPage.autostart_files.contains(item.id)) {
				return false;
			}
			string search_text = search_entry.get_text().down();
			string title_text = item.title.down();
			string desc_text = item.description.down();
			return (search_text in title_text || search_text in desc_text);
		}

		/* Credit to gnome-tweak-tool for inspiration */
		private int sort_function(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
			AutostartItemWidget item1 = row1 as AutostartItemWidget;
			AutostartItemWidget item2 = row2 as AutostartItemWidget;

			if (item1.running && !item2.running) {
				return -1;
			} else if (!item1.running && item2.running) {
				return 1;
			}

			return strcmp(item1.autostart_item.title, item2.autostart_item.title);
		}

		public new AutostartItem? run() {
			Gtk.ResponseType resp = (Gtk.ResponseType)base.run();
			switch (resp) {
				case Gtk.ResponseType.ACCEPT:
					return this.selected_item;
				case Gtk.ResponseType.CANCEL:
				default:
					return null;
			}
		}

		private void row_selected(Gtk.ListBoxRow? row) {
			if (row == null) {
				this.selected_item = null;
				this.button_ok.set_sensitive(false);
				return;
			}

			this.button_ok.set_sensitive(true);

			this.selected_item = ((AutostartItemWidget) row).autostart_item;
		}

		private void row_activated(Gtk.ListBoxRow? row) {
			this.row_selected(row);

			if (this.selected_item != null) {
				this.response(Gtk.ResponseType.ACCEPT);
			}
		}

		private void set_app_list(List<AppInfo> app_list) {
			foreach (var child in app_listbox.get_children()) {
				child.destroy();
			}

			foreach (var app in app_list) {
				if (app.should_show()) {
					DesktopAppInfo? info = new DesktopAppInfo(app.get_id());
					if (info != null) {
						AutostartItem item = new AutostartItem.from_app_info(info);
						bool running = running_processes.contains(item.executable);
						app_listbox.add(new AutostartItemWidget(item, false, running));
					}
				}
			}
			this.show_all();
		}

		private void get_running_processes() {
			string ls_stdout;
			string ls_stderr;
			int ls_status;

			try {
				string username = Environment.get_user_name();
				// Credit to gnome-tweak-tool for inspiration
				Process.spawn_command_line_sync(@"ps -e -w -w -U $username -o cmd",
					out ls_stdout,
					out ls_stderr,
					out ls_status);

				if (ls_status != 0) {
					return;
				}

				string[] commands = ls_stdout.split("\n");
				foreach (string line in commands) {
					string command = line.split(" ")[0];
					if (command != null && command != "") {
						if (!command.has_prefix("[")) {
							running_processes.add(command);
						}
					}
				}
			} catch (SpawnError e) {
				warning(e.message);
			}
		}
	}

	public class CommandDialog : Gtk.Dialog {
		Gtk.Widget button_ok;
		Gtk.Label exists_label;
		Gtk.Entry title_entry;
		Gtk.Entry desc_entry;
		Gtk.Entry command_entry;

		public CommandDialog(Gtk.Window parent) {
			Object(use_header_bar: 1,
				modal: true,
				title: _("Command"),
				transient_for: parent);

			Gtk.Box content_area = get_content_area() as Gtk.Box;

			this.add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
			button_ok = this.add_button(_("Add"), Gtk.ResponseType.ACCEPT);
			button_ok.set_sensitive(false);
			button_ok.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);

			Gtk.Grid grid = new Gtk.Grid();
			grid.set_column_spacing(20);
			grid.set_row_spacing(10);
			grid.halign = Gtk.Align.CENTER;
			grid.valign = Gtk.Align.CENTER;

			exists_label = new Gtk.Label(_("An entry with that title already exists"));
			grid.attach(exists_label, 0, 0, 2, 1);

			Gtk.Label label = new Gtk.Label(_("Title"));
			label.halign = Gtk.Align.START;
			grid.attach(label, 0, 1, 1, 1);
			title_entry = new Gtk.Entry();
			title_entry.set_placeholder_text(_("Required"));
			grid.attach(title_entry, 1, 1, 1, 1);

			label = new Gtk.Label(_("Description"));
			label.halign = Gtk.Align.START;
			grid.attach(label, 0, 2, 1, 1);
			desc_entry = new Gtk.Entry();
			desc_entry.set_placeholder_text(_("Optional"));
			grid.attach(desc_entry, 1, 2, 1, 1);

			label = new Gtk.Label(_("Command"));
			label.halign = Gtk.Align.START;
			grid.attach(label, 0, 3, 1, 1);
			command_entry = new Gtk.Entry();
			command_entry.set_placeholder_text(_("Required"));
			grid.attach(command_entry, 1, 3, 1, 1);

			title_entry.changed.connect(check_inputs);
			command_entry.changed.connect(check_inputs);

			content_area.pack_start(grid, true, true, 0);
			content_area.show_all();

			exists_label.hide();

			set_default_size(300, 200);
		}

		private void check_inputs() {
			string title_text = title_entry.get_text();
			string command_text = command_entry.get_text();
			bool exists = false;
			foreach (string title in AutostartPage.autostart_files.get_values()) {
				if (title.down() == title_text.down()) {
					exists = true;
					break;
				}
			}
			exists_label.set_visible(exists);
			button_ok.set_sensitive(title_text != "" && command_text != "" && !exists);
		}

		public new CommandInfo? run() {
			Gtk.ResponseType resp = (Gtk.ResponseType)base.run();
			switch (resp) {
				case Gtk.ResponseType.ACCEPT:
					CommandInfo info = new CommandInfo();
					info.title = title_entry.get_text();
					info.description = desc_entry.get_text();
					info.command = command_entry.get_text();
					return info;
				case Gtk.ResponseType.CANCEL:
				default:
					return null;
			}
		}
	}

	/**
	* AutostartPage allows users to control autostart apps
	*/
	public class AutostartPage : Budgie.SettingsPage {
		private Gtk.ListBox listbox_autostart;
		public static HashTable<string,string> autostart_files;
		public static string AUTOSTART_PATH;

		public AutostartPage() {
			Object(group: SETTINGS_GROUP_SESSION,
				content_id: "autostart",
				title: _("Autostart"),
				display_weight: 0,
				icon_name: "preferences-other",
				halign: Gtk.Align.FILL);

			AUTOSTART_PATH = Path.build_path("/", Environment.get_user_config_dir(), "autostart");

			autostart_files = new HashTable<string,string>(str_hash, str_equal);

			Gtk.Frame frame = new Gtk.Frame(null);
			this.pack_start(frame, true, true, 0);

			Gtk.Box frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			frame.add(frame_box);

			Gtk.Overlay overlay = new Gtk.Overlay();
			frame_box.pack_start(overlay, false, false, 0);

			Gtk.Label add_label = new Gtk.Label(_("Autostart apps"));
			overlay.add(add_label);
			add_label.margin = 15;
			add_label.get_style_context().add_class("dim-label");

			Gtk.MenuButton add_button = new Gtk.MenuButton();
			add_button.image = new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
			add_button.popup = create_menu();
			overlay.add_overlay(add_button);
			add_button.margin_end = 10;
			add_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			add_button.get_child().get_style_context().add_class("round-button");
			add_button.halign = Gtk.Align.END;
			add_button.valign = Gtk.Align.CENTER;

			Gtk.Separator separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
			frame_box.pack_start(separator, false, false, 0);

			listbox_autostart = new Gtk.ListBox();
			frame_box.pack_start(listbox_autostart, true, true, 0);
			listbox_autostart.set_selection_mode(Gtk.SelectionMode.NONE);

			/* No sense in iterating it if it doesn't exist .. */
			if (!FileUtils.test(AUTOSTART_PATH, FileTest.EXISTS|FileTest.IS_DIR)) {
				return;
			}

			list_directory.begin(AUTOSTART_PATH, (obj, res) => {
				string[] files = list_directory.end(res);
				foreach (string file in files) {
					DesktopAppInfo? info = new DesktopAppInfo.from_filename(file);
					if (info != null) {
						AutostartItem item = new AutostartItem.from_app_info(info);
						add_item(item);
						autostart_files.set(item.id, item.title);
					}
				}
			});
		}

		private Gtk.Menu create_menu() {
			Gtk.Menu menu = new Gtk.Menu();
			Gtk.MenuItem item_new_app = new Gtk.MenuItem.with_label(_("Add Application"));
			menu.add(item_new_app);
			Gtk.MenuItem item_new_command = new Gtk.MenuItem.with_label(_("Add Command"));
			menu.add(item_new_command);

			item_new_app.activate.connect(on_add_app);
			item_new_command.activate.connect(on_add_command);

			menu.show_all();

			return menu;
		}

		private void add_item(AutostartItem item) {
			listbox_autostart.add(new AutostartItemWidget(item));
		}

		private async string[] list_directory(string directory) {
			string[] filelist = {};
			File dir = File.new_for_path(directory);

			try {
				var e = yield dir.enumerate_children_async(FileAttribute.STANDARD_NAME, 0, Priority.DEFAULT);
				while (true) {
					var files = yield e.next_files_async(10, Priority.DEFAULT);
					if (files == null) {
						break;
					}
					foreach (FileInfo info in files) {
						if (info.get_name().has_suffix(".desktop")) {
							string path = Path.build_path("/", directory, info.get_name());
							filelist += path;
						}
					}
				}
			} catch (Error e) {
				warning("Error: list_directory failed: %s\n", e.message);
			}

			return filelist;
		}

		void on_add_app() {
			var dlg = new AppChooser(this.get_toplevel() as Gtk.Window);
			AutostartItem? item = dlg.run();
			dlg.destroy();

			if (item == null) {
				return;
			}

			if (autostart_files.contains(item.id)) {
				return;
			}

			string? autostart_path = item.make_autostart();

			if (autostart_path == null) {
				return;
			}

			autostart_files.set(item.id, item.title);
			add_item(item);
		}

		void on_add_command() {
			var dlg = new CommandDialog(this.get_toplevel() as Gtk.Window);
			CommandInfo? command_info = dlg.run();
			dlg.destroy();

			if (command_info == null) {
				return;
			}

			AutostartItem item = new AutostartItem.from_command_info(command_info);
			string? autostart_path = item.make_autostart();

			if (autostart_path == null) {
				return;
			}

			autostart_files.set(item.id, item.title);
			add_item(item);
		}
	}
}

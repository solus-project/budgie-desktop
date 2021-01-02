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

public enum ThemeType {
	ICON_THEME,
	GTK_THEME,
	CURSOR_THEME
}

[Compact]
class ThemeInfo : GLib.Object {
	private ThemeType theme_type;
	private List<string> paths;

	public ThemeInfo(ThemeType type) {
		this.theme_type = type;
		this.paths = new List<string>();
	}

	/**
	 * Try to add a path
	 */
	public bool add_path(string path) {
		if (this.contains_path(path)) {
			return false;
		}
		this.paths.append(path);
		return true;
	}

	public bool contains_path(string path) {
		unowned List<string>? g = paths.find_custom(path, strcmp);
		return g != null;
	}
}

public class ThemeScanner : GLib.Object {
	string[]? xdg_paths = null;

	string[] gtk_theme_blacklist = {
		"Adwaita",
		"Breeze",
		"Clearlooks",
		"Crux",
		"Emacs",
		"Industrial",
		"Mist",
		"Raleigh",
		"Redmond",
		"ThinIce"
	};

	string[] icon_theme_blacklist = {
		"breeze",
		"Papirus-Adapta",
		"Papirus-Adapta-Nokto",
		"solus-sc"
	};

	string[] normal_suffixes = {
		"themes",
		"icons"
	};

	string[] legacy_suffixes = {
		".themes",
		".icons"
	};

	string[]? gtk_theme_paths = null;

	private HashTable<string,ThemeInfo?> gtk_themes = null;
	private HashTable<string,ThemeInfo?> cursor_themes = null;
	private HashTable<string,ThemeInfo?> icon_themes = null;

	public ThemeScanner() {
		/* Set up the xdg paths */
		xdg_paths = new string[] {
			Environment.get_user_data_dir()
		};
		foreach (string item in Environment.get_system_data_dirs()) {
			if (item in xdg_paths) {
				continue;
			}
			xdg_paths += item;
		}
		/* Valid GTK theme directories */
		gtk_theme_paths = new string[] {
			"gtk-%d.0".printf(Gtk.MAJOR_VERSION),
			"gtk-%d-%d".printf(Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION)
		};

		/* Table init */
		gtk_themes = new HashTable<string,ThemeInfo?>(str_hash, str_equal);
		cursor_themes = new HashTable<string,ThemeInfo?>(str_hash, str_equal);
		icon_themes = new HashTable<string,ThemeInfo?>(str_hash, str_equal);
	}

	/**
	 * Scan all theme types
	 */
	public async void scan_themes() {
		foreach (string xdg_path in this.xdg_paths) {
			yield scan_themes_dir(xdg_path, this.normal_suffixes);
		}
		var home_dir = Environment.get_home_dir();
		if (home_dir == null || home_dir.length < 1) {
			return;
		}
		yield scan_themes_dir(home_dir, this.legacy_suffixes);
	}

	/**
	 * Scan a directory for all theme types
	 */
	private async void scan_themes_dir(string base_dir, string[] suffixes) {
		if (!FileUtils.test(base_dir, FileTest.IS_DIR)) {
			return;
		}

		try {
			foreach (string suffix in suffixes) {
				var full_path = "%s%s%s".printf(base_dir, Path.DIR_SEPARATOR_S, suffix);
				if (!FileUtils.test(full_path, FileTest.IS_DIR)) {
					continue;
				}

				/* Now attempt to iterate the dir */
				File f = File.new_for_path(full_path);
				var en = yield f.enumerate_children_async("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, null);
				while (true) {
					var files = yield en.next_files_async(10, Priority.DEFAULT, null);
					if (files == null) {
						break;
					}

					foreach (var file in files) {
						var display_path = file.get_display_name();
						var sep = Path.DIR_SEPARATOR_S;
						string path = "%s%s%s".printf(full_path, sep, display_path);
						yield scan_one(suffix, path, display_path);
					}
				}
			}
		} catch (Error e) {
			message("Error in scan_themes_dir: %s\n", e.message);
		}
	}

	/**
	 * Scan one directory with the given type, i.e. "icons", or "themes"
	 */
	private async void scan_one(string path_type, string full_path, string display_name) {
		bool gtk_theme = false;
		if (path_type == "themes" || path_type == ".themes") {
			gtk_theme = true;
		}

		if (gtk_theme) {
			foreach (var suffix in this.gtk_theme_paths) {
				var path = "%s%s%s".printf(full_path, Path.DIR_SEPARATOR_S, suffix);
				bool added = yield maybe_add_gtk_theme(path, display_name);
				if (added) {
					return;
				}
			}
		} else {
			/* Icon theme */
			yield maybe_add_icon_theme(full_path, display_name);
		}
	}

	/**
	 * Attempt to add a unique theme into the set
	 */
	private async bool maybe_add_gtk_theme(string path, string theme_name) {
		for (int index = 0; index < gtk_theme_blacklist.length; index++) {
			string blacklisted_item = gtk_theme_blacklist[index];

			if ((blacklisted_item == theme_name) || (theme_name.index_of(blacklisted_item) != -1)) {
				return false;
			}
		}

		unowned ThemeInfo? info = gtk_themes.lookup(theme_name);
		if (info == null) {
			ThemeInfo? ninfo = new ThemeInfo(ThemeType.GTK_THEME);
			gtk_themes.insert(theme_name, ninfo);
			info = gtk_themes.lookup(theme_name);
		}
		if (info.add_path(path)) {
			return true;
		}
		return false;
	}

	/**
	 * Return a unique list of currently known gtk themes
	 */
	public string[] get_gtk_themes() {
		string[] t = new string[] {};
		unowned string? name = null;
		unowned ThemeInfo? info = null;

		var iter = HashTableIter<string,ThemeInfo?>(this.gtk_themes);
		while (iter.next(out name, out info)) {
			t += "" + name;
		}
		return t;
	}

	/**
	 * Return a unique list of currently known cursor themes
	 */
	public string[] get_cursor_themes() {
		string[] t = new string[] {};
		unowned string? name = null;
		unowned ThemeInfo? info = null;

		var iter = HashTableIter<string,ThemeInfo?>(this.cursor_themes);
		while (iter.next(out name, out info)) {
			t += "" + name;
		}
		return t;
	}

	/**
	 * Return a unique list of currently known icon themes
	 */
	public string[] get_icon_themes() {
		string[] t = new string[] {};
		unowned string? name = null;
		unowned ThemeInfo? info = null;

		var iter = HashTableIter<string,ThemeInfo?>(this.icon_themes);
		while (iter.next(out name, out info)) {
			t += "" + name;
		}
		return t;
	}

	/**
	 * Attempt to add cursor/icon theme to the set
	 */
	private async void maybe_add_icon_theme(string path, string theme_name) {
		var test_path = "%s%s%s".printf(path, Path.DIR_SEPARATOR_S, "index.theme");
		if (!FileUtils.test(test_path, FileTest.EXISTS)) {
			return;
		}
		bool icon_theme = true;

		KeyFile f = new KeyFile();
		/* Try and load ini file first */
		try {
			f.load_from_file(test_path, KeyFileFlags.NONE);
		} catch (Error e) {
			return;
		}
		/* Check if its an icon theme */
		try {
			if (!f.has_key("Icon Theme", "Directories")) {
				icon_theme = false;
			}
		} catch (Error e) {
			icon_theme = false;
		}

		if (icon_theme) {
			yield maybe_add_icons(path, theme_name);
		}

		/* Test if we have cursors here too */
		var cursor_path = "%s%s%s".printf(path, Path.DIR_SEPARATOR_S, "cursors");
		if (FileUtils.test(cursor_path, FileTest.EXISTS)) {
			yield maybe_add_cursors(path, theme_name);
		}
	}

	/**
	 * Try adding unique cursor theme
	 */
	private async bool maybe_add_cursors(string path, string theme_name) {
		unowned ThemeInfo? info = cursor_themes.lookup(theme_name);
		if (info == null) {
			ThemeInfo? ninfo = new ThemeInfo(ThemeType.CURSOR_THEME);
			cursor_themes.insert(theme_name, ninfo);
			info = cursor_themes.lookup(theme_name);
		}
		if (info.add_path(path)) {
			return true;
		}
		return false;
	}

	/**
	 * Try adding unique icon theme
	 */
	private async bool maybe_add_icons(string path, string theme_name) {
		for (int index = 0; index < icon_theme_blacklist.length; index++) {
			string blacklisted_item = icon_theme_blacklist[index];

			if ((blacklisted_item == theme_name) || (theme_name.index_of(blacklisted_item) != -1)) {
				return false;
			}
		}

		unowned ThemeInfo? info = icon_themes.lookup(theme_name);
		if (info == null) {
			ThemeInfo? ninfo = new ThemeInfo(ThemeType.ICON_THEME);
			icon_themes.insert(theme_name, ninfo);
			info = icon_themes.lookup(theme_name);
		}
		if (info.add_path(path)) {
			return true;
		}
		return false;
	}
}

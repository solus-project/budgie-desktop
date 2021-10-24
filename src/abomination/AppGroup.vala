/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2018-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie.Abomination {
	/**
	 * A replacement for Wnck.ClassGroup as Wnck.ClassGroup relies on the sometime
	 * missing, sometime incoherent WM_CLASS property to group windows together.
	 */
	public class AppGroup : GLib.Object {
		private string name;
		private HashTable<ulong?,Wnck.Window?> windows;

		/**
		 * Signals
		 */
		public signal void icon_changed();
		public signal void added_window(Wnck.Window window);
		public signal void removed_window(Wnck.Window window);
		public signal void renamed_group(string old_name, string new_name);

		/**
		 * Create a new group from a window instance
		 */
		internal AppGroup(Wnck.Window window) {
			this.windows = new HashTable<ulong?,Wnck.Window?>(int_hash, int_equal);

			this.name = get_group_name(window);
			this.add_window(window); // track window

			debug("Created group: %s", this.name);

			window.icon_changed.connect(() => this.icon_changed()); // pass signal to whoever is listening
		}

		public void add_window(Wnck.Window window) {
			if (this.windows.contains(window.get_xid())) {
				return;
			}

			this.windows.insert(window.get_xid(), window);

			// some window without WM_CLASS change their name after starting (e.g. android studio: emulator -> Android Emulator - Pixel_3a_API_30_x86:5554),
			// and since we rely on the window name instead of WM_CLASS for those, we need to rename the group when it happen.
			// We use connect_after to be sure that this signals are caught last, otherwise it cause confusion with Abomination own signals.
			window.name_changed.connect_after(() => this.update_group(window));
			window.class_changed.connect_after(() => this.update_group(window));

			debug("Number of window: %u (group: %s)", this.get_windows().length(), this.name);

			this.added_window(window);
		}

		public void remove_window(Wnck.Window window) {
			if (!this.windows.contains(window.get_xid())) {
				return;
			}

			this.windows.remove(window.get_xid());

			debug("Number of window: %u (group: %s)", this.get_windows().length(), this.name);

			this.removed_window(window);
		}

		public List<weak Wnck.Window> get_windows() {
			return this.windows.get_values();
		}

		public string get_name() {
			return this.name;
		}

		public Gdk.Pixbuf? get_icon() {
			if (this.get_windows().length() == 0 || this.get_windows().nth_data(0).get_class_group() == null) {
				return null;
			}
			return this.get_windows().nth_data(0).get_class_group().get_icon();
		}

		private void update_group(Wnck.Window window) {
			if (window == null) {
				return;
			}

			string old_name = this.name;
			this.name = get_group_name(window);

			if (this.name != old_name) { // send signal that group was renamed
				debug("Renamed group %s into %s", old_name, this.name);
				this.renamed_group(old_name, this.name);
			}
		}
	}
}

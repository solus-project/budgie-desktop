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

/**
 * Try to get application group from its WM_CLASS property or fallback to using
 * the app name when WM_CLASS isn't set (e.g. LibreOffice, Google Chrome, Android Studio emulator, maybe others)
 */
string get_group_name(Wnck.Window window) {
	// Try to use class group name from WM_CLASS as it's the most precise.
	string name = window.get_class_group_name();

	// Fallback to using class instance name (still from WM_CLASS),
	// less precise, if app is part of a "family", like libreoffice,
	// instance will always be libreoffice.
	if (name == null || name == "") {
		name = window.get_class_instance_name();
	}

	// Fallback to using name (when WM_CLASS isn't set).
	// i.e. Chrome profile launcher, android studio emulator
	if (name == null || name == "") {
		name = window.get_name();
		warning("Fallback to using window name for %s", name);
	}

	if (name != null) {
		name = name.down();
	}

	// Chrome profile launcher doesn't have WM_CLASS, so name is used
	// instead and is not the same as the group of the window opened afterward.
	if (name == "google chrome") {
		name = "google-chrome";
	}

	return name;
}

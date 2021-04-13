/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2016-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

/**
 * Whether we need to replace an existing daemon
 */
static bool replace = false;

const OptionEntry[] options = {
	{ "replace", 0, 0, OptionArg.NONE, ref replace, "Replace currently running daemon" },
	{ null }
};

namespace Budgie {
	bool setup = false;
	bool spammed = false;

	void DaemonNameLost(DBusConnection conn, string name) {
		warning("budgie-daemon lost d-bus name %s", name);
		if (!spammed) {
			if (setup) {
				message("Replaced existing budgie-daemon");
			} else {
				message("Another instance of budgie-daemon is running. Use --replace");
			}
			spammed = true;
		}
		Gtk.main_quit();
	}
}

/**
 * Main entry for the daemon
 */
public static int main(string[] args) {
	Gtk.init(ref args);
	OptionContext ctx;

	Budgie.ServiceManager? manager = null;
	Budgie.EndSessionDialog? end_dialog = null;
	Budgie.SettingsManager? settings = null;
	Wnck.Screen? screen = null;

	Intl.setlocale(LocaleCategory.ALL, "");
	Intl.bindtextdomain(Budgie.GETTEXT_PACKAGE, Budgie.LOCALEDIR);
	Intl.bind_textdomain_codeset(Budgie.GETTEXT_PACKAGE, "UTF-8");
	Intl.textdomain(Budgie.GETTEXT_PACKAGE);

	ctx = new OptionContext("- Budgie Daemon");
	ctx.set_help_enabled(true);
	ctx.add_main_entries(options, null);
	ctx.add_group(Gtk.get_option_group(false));

	try {
		ctx.parse(ref args);
	} catch (Error e) {
		stderr.printf("Error: %s\n", e.message);
		return 0;
	}

	/* Initialise wnck after gtk-start */
	Idle.add(() => {
		screen = Wnck.Screen.get_default();
		if (screen != null) {
			screen.force_update();
		}
		return false;
	});

	manager = new Budgie.ServiceManager(replace);
	end_dialog = new Budgie.EndSessionDialog(replace);
	settings = new Budgie.SettingsManager();

	end_dialog.Opened.connect(settings.do_disable_quietly); // When we've opened the EndSession dialog, disable Caffeine Mode
	end_dialog.Closed.connect(settings.do_disable_quietly); // When we've closed the EndSession dialog as well, ensure Caffeine mode is disabled

	/* Enter main loop */
	Gtk.main();

	/* Deref - clean */
	manager = null;
	end_dialog = null;
	settings = null;
	screen = null;

	return 0;
}

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

static bool replace = false;
static bool reset = false;

const OptionEntry[] options = {
	{ "replace", 0, 0, OptionArg.NONE, ref replace, "Replace currently running panel" },
	{ "reset", 0, 0, OptionArg.NONE, ref reset, "Reset the panel configuration" },
	{ null }
};

public static int main(string[] args) {
	Gtk.init(ref args);
	OptionContext ctx;

	Intl.setlocale(LocaleCategory.ALL, "");
	Intl.bindtextdomain(Budgie.GETTEXT_PACKAGE, Budgie.LOCALEDIR);
	Intl.bind_textdomain_codeset(Budgie.GETTEXT_PACKAGE, "UTF-8");
	Intl.textdomain(Budgie.GETTEXT_PACKAGE);

	ctx = new OptionContext("- Budgie Panel");
	ctx.set_help_enabled(true);
	ctx.add_main_entries(options, null);
	ctx.add_group(Gtk.get_option_group(false));

	try {
		ctx.parse(ref args);
	} catch (Error e) {
		stderr.printf("Error: %s\n", e.message);
		return 0;
	}

	var manager = new Budgie.PanelManager(reset);
	manager.serve(replace);

	Gtk.main();
	return 0;
}

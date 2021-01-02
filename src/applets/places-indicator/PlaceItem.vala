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

public class PlaceItem : ListItem {
	public PlaceItem(File file, string class, string? bookmark_name) {
		item_class = class;

		string name = "";
		if (bookmark_name != null) {
			name = bookmark_name;
		} else if (file.get_basename() == "/" && file.get_uri() != "file:///") {
			name = file.get_uri().split("://")[1];
			if (name.has_suffix("/")) {
				name = name[0:name.length - 1];
			}
		} else {
			name = file.get_basename();
		}

		// Get and set the appropriate icon
		try {
			FileInfo info = file.query_info("standard::symbolic-icon", FileQueryInfoFlags.NONE, null);
			set_button(name.strip(), get_icon(info.get_symbolic_icon()));
		} catch (Error e) {
			set_button(name.strip(), get_icon(null));
		}

		name_button.set_tooltip_text(_("Open \"%s\"".printf(name.strip())));

		name_button.clicked.connect(() => {
			open_directory(file);
		});
	}
}

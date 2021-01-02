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

public class RavenWidget : Gtk.Box {
	/**
	 * set_show will set our show / hide to specified state
	 */
	public void set_show(bool show) {
		if (show) {
			show_all();
		} else {
			hide();
		}

		queue_draw();
	}
}

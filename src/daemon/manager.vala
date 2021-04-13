/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2016-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {
	/**
	* Main lifecycle management, handle all the various session and GTK+ bits
	*/
	public class ServiceManager : GLib.Object {
		private Budgie.ThemeManager theme_manager;
		/* Keep track of our SessionManager */
		private LibSession.SessionClient? sclient;

		/* On Screen Display */
		Budgie.OSDManager? osd;
		Budgie.MenuManager? menus;
		Budgie.TabSwitcher? switcher;

		/**
		* Construct a new ServiceManager and initialiase appropriately
		*/
		public ServiceManager(bool replace) {
			theme_manager = new Budgie.ThemeManager();
			register_with_session.begin((o, res) => {
				bool success = register_with_session.end(res);
				if (!success) {
					message("Failed to register with Session manager");
				}
			});
			osd = new Budgie.OSDManager();
			osd.setup_dbus(replace);
			menus = new Budgie.MenuManager();
			menus.setup_dbus(replace);
			switcher = new Budgie.TabSwitcher();
			switcher.setup_dbus(replace);
		}

		/**
		* Attempt registration with the Session Manager
		*/
		private async bool register_with_session() {
			try {
				sclient = yield LibSession.register_with_session("budgie-daemon");
			} catch (Error e) {
				return false;
			}

			sclient.QueryEndSession.connect(() => {
				end_session(false);
			});
			sclient.EndSession.connect(() => {
				end_session(false);
			});
			sclient.Stop.connect(() => {
				end_session(true);
			});
			return true;
		}

		/**
		* Properly shutdown when asked to
		*/
		private void end_session(bool quit) {
			if (quit) {
				Gtk.main_quit();
				return;
			}
			try {
				sclient.EndSessionResponse(true, "");
			} catch (Error e) {
				warning("Unable to respond to session manager! %s", e.message);
			}
		}
	}
}

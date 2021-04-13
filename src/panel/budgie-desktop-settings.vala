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

public const string PANEL_DBUS_NAME = "org.budgie_desktop.Panel";
public const string PANEL_DBUS_OBJECT_PATH = "/org/budgie_desktop/Panel";

[DBus (name="org.budgie_desktop.Panel")]
public interface PanelRemote : GLib.Object {
	public abstract void OpenSettings() throws Error;
}

public static void main(string[] args) {
	try {
		PanelRemote? proxy = Bus.get_proxy_sync<PanelRemote>(BusType.SESSION, PANEL_DBUS_NAME, PANEL_DBUS_OBJECT_PATH, 0, null);
		proxy.OpenSettings();
	} catch (Error e) {
		warning("Failed to launch settings UI: %s", e.message);
	}
}

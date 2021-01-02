/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace LibSession {
	/**
	 * Proxy for gnome-session
	 */
	[DBus (name="org.gnome.SessionManager")]
	public interface SessionManager : Object {
		public abstract async ObjectPath RegisterClient(string app_id, string client_start_id) throws DBusError, IOError;
	}

	[DBus (name="org.gnome.SessionManager.ClientPrivate")]
	public interface SessionClient : Object {
		public abstract void EndSessionResponse(bool is_ok, string reason) throws DBusError, IOError;

		public signal void Stop() ;
		public signal void QueryEndSession(uint flags);
		public signal void EndSession(uint flags);
		public signal void CancelEndSession();
	}


	public static async SessionClient? register_with_session(string app_id) {
		ObjectPath? path = null;
		string? msg = null;
		string? start_id = null;

		SessionManager? session = null;
		SessionClient? sclient = null;

		start_id = Environment.get_variable("DESKTOP_AUTOSTART_ID");
		if (start_id != null) {
			Environment.unset_variable("DESKTOP_AUTOSTART_ID");
		} else {
			start_id = "";
			message("DESKTOP_AUTOSTART_ID not set, session registration may be broken (not running budgie-desktop?)");
		}

		try {
			session = yield Bus.get_proxy(BusType.SESSION, "org.gnome.SessionManager", "/org/gnome/SessionManager");
		} catch (Error e) {
			warning("Unable to connect to session manager: %s", e.message);
			return null;
		}
		/* now we need to gain Moar.. */
		try {
			path = yield session.RegisterClient(app_id, start_id);
		} catch (Error e) {
			msg = e.message;
			path = null;
		}
		if (path == null) {
			warning("Error registering with session manager%s", msg != null ? ": %s".printf(msg) : "");
			return null;
		}

		try {
			sclient = yield Bus.get_proxy(BusType.SESSION, "org.gnome.SessionManager", path);
		} catch (Error e) {
			warning("Unable to get Private Client proxy: %s", e.message);
			return null;
		}

		return sclient;
	}
}

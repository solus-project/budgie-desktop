/*
 * This file is part of budgie-desktop.
 *
 * Copyright (C) 2015 Ikey Doherty
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace LibSession
{

    [CCode (cheader_filename = "BudgieSession.h")]
    public interface SessionClient : GLib.Object
    {
        public abstract void EndSessionResponse(bool is_ok, string reason) throws GLib.IOError;

        public signal void Stop() ;
        public signal void QueryEndSession(uint flags);
        public signal void EndSession(uint flags);
        public signal void CancelEndSession();
    }

    [CCode (cheader_filename = "BudgieSession.h")]
    public static async LibSession.SessionClient? register_with_session(string app_id);

} /* End namespace */

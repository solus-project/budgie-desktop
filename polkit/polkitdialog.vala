/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

[GtkTemplate (ui = "/com/solus-project/budgie/polkit/dialog.ui")]
public class AgentDialog : Gtk.Dialog
{

}

public class Agent : PolkitAgent.Listener
{

    public override void initiate_authentication(string action_id, string message, string icon_name,
        Polkit.Details details, string cookie, GLib.List<Polkit.Identity?> identities,
        GLib.Cancellable cancellable, GLib.AsyncReadyCallback @callback)
    {

    }

    public override bool initiate_authentication_finish(GLib.AsyncResult res)
    {
        return false;
    }

}

} /* End namespace */

public static int main(string[] args)
{
    return 0;
}

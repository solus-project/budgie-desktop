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

    [GtkChild]
    private Gtk.Entry? entry_auth;

    [GtkChild]
    private Gtk.Label? label_message;

    [GtkChild]
    private Gtk.Image? image_icon;

    [GtkChild]
    private Gtk.ScrolledWindow? scrolledwindow_idents;

    private Gtk.ListBox? list_idents;

    public PolkitAgent.Session? pk_session = null;

    public string action_id { public get; public set; }
    public string message {
        public set {
            label_message.set_text(value);
        }
        public owned get {
            return label_message.get_text();
        }
    }

    public string auth_data {
        public owned get {
            return entry_auth.get_text();
        }
        public set {
            entry_auth.set_text(value);
        }
    }

    private string? _icon = "dialog-password-symbolic";
    public string auth_icon_name {
        public get {
            return _icon;
        }
        public set {
            this.image_icon.set_from_icon_name(value, Gtk.IconSize.DIALOG);
            this._icon = value;
        }
    }

    public string cookie { public get; public set; }

    /* Save manually setting all this crap via some nice properties */
    public AgentDialog(string action_id, string message, string icon_name, string cookie)
    {
        Object(action_id: action_id, message: message, auth_icon_name: icon_name, cookie: cookie, use_header_bar: 0);
        realize.connect(on_realize);

        set_keep_above(true);
        list_idents = new Gtk.ListBox();
        scrolledwindow_idents.add(list_idents);
    }

    /* Ensure we grab focus */
    void on_realize()
    {
        weak Gdk.Window? win = null;

        if ((win = get_window()) == null) {
            return;
        }
        win.focus(Gdk.CURRENT_TIME);
        entry_auth.grab_focus();
    }
}

public class Agent : PolkitAgent.Listener
{

    /* Placeholder */
    void on_agent_response(AgentDialog? dialog)
    {
        if (dialog.pk_session == null) {
            return;
        }
        dialog.pk_session.response(dialog.auth_data);
    }

    /* Noop */
    public override void initiate_authentication(string action_id, string message, string icon_name,
        Polkit.Details details, string cookie, GLib.List<Polkit.Identity?> identities,
        GLib.Cancellable cancellable, GLib.AsyncReadyCallback @callback)
    {
    }

    /* Noop */
    public override bool initiate_authentication_finish(GLib.AsyncResult res)
    {
        return false;
    }

}

} /* End namespace */

static void set_css_from_uri(string? uri)
{
    var screen = Gdk.Screen.get_default();
    Gtk.CssProvider? new_provider = null;

    try {
        var f = File.new_for_uri(uri);
        new_provider = new Gtk.CssProvider();
        new_provider.load_from_file(f);
    } catch (Error e) {
        warning("Error loading theme: %s", e.message);
        new_provider = null;
        return;
    }


    Gtk.StyleContext.add_provider_for_screen(screen, new_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
}

public static int main(string[] args)
{
    Gtk.init(ref args);


    set_css_from_uri("resource://com/solus-project/budgie/theme/theme.css");
    /* Testing  */
    var dlg = new Budgie.AgentDialog("lol", "SQUIRRELS", "dialog-password-symbolic", "cookies!");
    int response = dlg.run();

    return 0;
}

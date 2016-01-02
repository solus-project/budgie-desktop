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
    private unowned Polkit.Identity? pk_identity = null;

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

        var header = new Gtk.EventBox();
        set_titlebar(header);
        header.get_style_context().remove_class("titlebar");

        get_settings().set_property("gtk-application-prefer-dark-theme", true);

        list_idents.row_activated.connect(on_row_activated);
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

    void deselect_session()
    {
        /* dc old signals */
        pk_session = null;
        pk_identity = null;

    }

    void select_session()
    {
        if (pk_session != null) {
            deselect_session();
        }

        pk_session = new PolkitAgent.Session(this.pk_identity, this.cookie);
        /*pk_session.completed.connect(on_pk_session_completed);
        pk_session.request.connect(on_pk_request);
        pk_session.show_error.connect(on_pk_error);
        pk_session.show_info.connect(on_pk_info);*/
    }

    void on_row_activated(Gtk.ListBoxRow? row)
    {
        if (row == null) {
            deselect_session();
            return;
        }

        var child = row.get_child();

        pk_identity = row.get_data("pk_identity");
        select_session();
    }

    void set_from_idents(ref List<Polkit.Identity?> idents)
    {
        Gtk.ListBoxRow? active_row = null;

        foreach (var child in list_idents.get_children()) {
            child.destroy();
        }

        foreach (unowned Polkit.Identity? ident in idents)
        {
            string? name = null;

            if (ident is Polkit.UnixUser) {
                unowned Posix.Passwd? pwd = Posix.getpwuid((ident as Polkit.UnixUser).get_uid());
                name = "%s".printf(pwd.pw_name);
            } else if (ident is Polkit.UnixGroup) {
                unowned Posix.Group? gwd = Posix.getgrgid((ident as Polkit.UnixGroup).get_gid());
                name = "%s: %s".printf(_("Group:"), gwd.gr_name);
            } else {
                name = ident.to_string();
            }

            var label = new Gtk.Label(name);
            label.halign = Gtk.Align.START;
            label.set_data("pk_identity", ident);
            list_idents.add(label);

            if (active_row == null) {
                active_row = label.get_parent() as Gtk.ListBoxRow;
                list_idents.select_row(active_row);
            }
        }
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
    /* Testing  
    var dlg = new Budgie.AgentDialog("lol", "Authentication is required to launch a nuke at the neighbour's squirrel", "dialog-password-symbolic", "cookies!");
    int response = dlg.run();*/

    return 0;
}

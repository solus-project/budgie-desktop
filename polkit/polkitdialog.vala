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
    private Gtk.ComboBox? combobox_idents;

    [GtkChild]
    private Gtk.Label? label_prompt;

    public PolkitAgent.Session? pk_session = null;
    private Polkit.Identity? pk_identity = null;

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

    /* Manipulate Vala's pointer logic to prevent a copy */
    public unowned GLib.Cancellable? cancellable { public set ; public get; }

    public string cookie { public get; public set; }

    /* Save manually setting all this crap via some nice properties */
    public AgentDialog(string action_id, string message, string icon_name, string cookie, GLib.Cancellable? cancellable)
    {
        Object(action_id: action_id, message: message, auth_icon_name: icon_name, cookie: cookie, cancellable: cancellable, use_header_bar: 0);

        set_keep_above(true);

        var header = new Gtk.EventBox();
        set_titlebar(header);
        header.get_style_context().remove_class("titlebar");

        get_settings().set_property("gtk-application-prefer-dark-theme", true);

        combobox_idents.changed.connect(on_ident_changed);
        var render = new Gtk.CellRendererText();
        combobox_idents.pack_start(render, true);
        combobox_idents.add_attribute(render, "text", 0);
        combobox_idents.set_id_column(0);

        response.connect(on_agent_response);
        cancellable.cancelled.connect(on_agent_cancelled);

        window_position = Gtk.WindowPosition.CENTER_ALWAYS;
    }

    [GtkCallback]
    void on_entry_auth_activate()
    {
        /* Stop hardcoding, make an enum */
        this.response(1);
    }

    /* Ensure we grab focus */
    public override void show()
    {
        base.show();
        weak Gdk.Window? win = null;

        if ((win = get_window()) == null) {
            return;
        }
        win.focus(Gdk.CURRENT_TIME);
        entry_auth.grab_focus();
    }

    /* Session request completed */
    void on_pk_session_completed(bool authorized)
    {
        /* Not authed */
        if (!authorized || cancellable.is_cancelled()) {
            /* TODO: Cancel non existent spinner */
            var session = pk_session;
            deselect_session();
            auth_data = "";
            entry_auth.grab_focus();
            pk_session = session;
            select_session();
            return;
        }
        done();
    }

    void on_pk_request(string request, bool echo_on)
    {
        entry_auth.set_visibility(echo_on);
        /* TODO: Force i18n */
        label_prompt.set_text(request);
    }

    void on_pk_error(string text)
    {
        warning("PkError: %s", text);
    }

    void on_pk_info(string text)
    {
        GLib.message("PKInfo: %s", text);
    }

    void deselect_session()
    {
        /* dc old signals */
        if (pk_session != null) {
            SignalHandler.disconnect(pk_session, error_id);
            SignalHandler.disconnect(pk_session, complete_id);
            SignalHandler.disconnect(pk_session, request_id);
            SignalHandler.disconnect(pk_session, info_id);
        }
        pk_session = null;
    }

    ulong error_id;
    ulong request_id;
    ulong info_id;
    ulong complete_id;

    void select_session()
    {
        if (pk_session != null) {
            deselect_session();
        }

        pk_session = new PolkitAgent.Session(this.pk_identity, this.cookie);
        complete_id = pk_session.completed.connect(on_pk_session_completed);
        request_id = pk_session.request.connect(on_pk_request);
        error_id = pk_session.show_error.connect(on_pk_error);
        info_id = pk_session.show_info.connect(on_pk_info);
        pk_session.initiate();
    }

    void on_ident_changed()
    {
        Gtk.TreeIter iter;

        if (!combobox_idents.get_active_iter(out iter)) {
            deselect_session();
            return;
        }

        var model = combobox_idents.get_model();
        if (model == null) {
            return;
        }

        model.get(iter, 1, out pk_identity, -1);
        select_session();
    }


    public void set_from_idents(List<Polkit.Identity?> idents)
    {
        Gtk.ListBoxRow? active_row = null;

        Gtk.ListStore? model = new Gtk.ListStore(2, typeof(string), typeof(Polkit.Identity));
        Gtk.TreeIter iter;

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

            
            model.append(out iter);
            model.set(iter, 0, name, 1, ident);
        }

        combobox_idents.set_model(model);
        combobox_idents.active = 0;
    }

    /* Got a response from the AgentDialog */
    void on_agent_response(int response)
    {
        if (response < 1) {
            cancellable.cancel();
            done();
            return;
        }

        if (pk_session == null) {
            return;
        }

        /* TODO: Start up a spinner */
        pk_session.response(auth_data);
    }

    /* Cancellable, whichever, kill this session */
    void on_agent_cancelled()
    {
        if (pk_session != null) {
            pk_session.cancel();
        }
        done();
    }

    public signal void done();

}

public class Agent : PolkitAgent.Listener
{

    public override async bool initiate_authentication(string action_id, string message, string icon_name,
        Polkit.Details details, string cookie, GLib.List<Polkit.Identity?>? identities, GLib.Cancellable cancellable)
    {

        var dialog = new AgentDialog(action_id, message, "dialog-password-symbolic", cookie, cancellable);
        dialog.done.connect(()=> {
            initiate_authentication.callback();
        });

        if (identities == null) {
            dialog.destroy();
            return false;
        }

        dialog.set_from_idents(identities);

        dialog.show();
        yield;

        dialog.destroy();

        return true;
    }

}

} /* End namespace */

static void set_css_from_uri(string? uri)
{
    Budgie.please_link_me_libtool_i_have_great_themes();
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

    Budgie.Agent? agent = new Budgie.Agent();
    Polkit.Subject? subject = null;

    int pid = Posix.getpid();

    try {
        subject = Polkit.UnixSession.new_for_process_sync(pid, null);
    } catch (Error e) {
        stdout.printf("Unable to initiate PolKit: %s", e.message);
        return 1;
    }

    try {
        PolkitAgent.register_listener(agent, subject, null);
    } catch (Error e) {
        stderr.printf("Unable to register listener: %s", e.message);
        return 1;
    }

    set_css_from_uri("resource://com/solus-project/budgie/theme/theme.css");

    Gtk.main();

    return 0;
}

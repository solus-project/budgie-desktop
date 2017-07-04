/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

/**
 * PluginItem is used to represent a plugin for the user to add to their
 * panel through the Applet API
 */
public class PluginItem : Gtk.Grid {

    /**
     * We're bound to the info
     */
    public unowned Peas.PluginInfo? plugin { public get ; construct set; }

    private Gtk.Image image;
    private Gtk.Label label;
    private Gtk.Label desc;

    /**
     * Construct a new PluginItem for the given applet
     */
    public PluginItem(Peas.PluginInfo? info)
    {
        Object(plugin: info);

        get_style_context().add_class("plugin-item");

        margin_top = 4;
        margin_bottom = 4;

        image = new Gtk.Image.from_icon_name(info.get_icon_name(), Gtk.IconSize.LARGE_TOOLBAR);
        image.pixel_size = 32;
        image.margin_start = 12;
        image.margin_end = 14;

        label = new Gtk.Label(info.get_name());
        label.margin_end = 18;
        label.halign = Gtk.Align.START;

        desc = new Gtk.Label(info.get_description());
        desc.margin_top = 4;
        desc.halign = Gtk.Align.START;
        desc.set_property("xalign", 0.0);
        desc.get_style_context().add_class("dim-label");

        attach(image, 0, 0, 1, 2);
        attach(label, 1, 0, 1, 1);
        attach(desc, 1, 1, 1, 1);

        this.show_all();
    }
}

/**
 * AppletChooser provides a dialog to allow selection of an
 * applet to be added to a panel
 */
public class AppletChooser : Gtk.Dialog
{
    Gtk.ListBox applets;

    public AppletChooser(Gtk.Window parent)
    {
        Object(use_header_bar: 1,
               modal: true,
               title: _("Choose an applet"),
               transient_for: parent);

        Gtk.Box content_area = get_content_area() as Gtk.Box;

        var cancel = this.add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
        var ok = this.add_button(_("Add applet"), Gtk.ResponseType.ACCEPT);

        ok.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        applets = new Gtk.ListBox();
        scroll.add(applets);

        content_area.pack_start(scroll, true, true, 0);
        content_area.show_all();

        set_default_size(400, 450);
    }

    /**
     * Set the available plugins to show in the dialog
     */
    public void set_plugin_list(GLib.List<Peas.PluginInfo?> plugins)
    {
        foreach (var child in applets.get_children()) {
            child.destroy();
        }

        foreach (var plugin in plugins) {
            this.add_plugin(plugin);
        }
    }

    /**
     * Add a new plugin to our display area
     */
    void add_plugin(Peas.PluginInfo? plugin)
    {
        this.applets.add(new PluginItem(plugin));
    }

} /* End class */

} /* End namespace */

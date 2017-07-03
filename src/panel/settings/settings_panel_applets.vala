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
 * AppletItem is used to represent a Budgie Applet in the list
 */
public class AppletItem : Gtk.Box {

    /**
     * We're bound to the info
     */
    public unowned Budgie.AppletInfo? applet { public get ; construct set; }

    private Gtk.Image image;
    private Gtk.Label label;

    /**
     * Construct a new AppletItem for the given applet
     */
    public AppletItem(Budgie.AppletInfo? info)
    {
        Object(applet: info);

        get_style_context().add_class("applet-item");

        margin_top = 4;
        margin_bottom = 4;

        image = new Gtk.Image();
        image.margin_start = 6;
        image.margin_end = 14;
        pack_start(image, false, false, 0);

        label = new Gtk.Label("");
        label.margin_end = 14;
        label.halign = Gtk.Align.START;
        pack_start(label, false, false, 0);

        this.applet.bind_property("description", this.label, "label", BindingFlags.DEFAULT|BindingFlags.SYNC_CREATE);
        this.applet.bind_property("icon", this.image, "icon-name", BindingFlags.DEFAULT|BindingFlags.SYNC_CREATE);
        this.image.icon_size = Gtk.IconSize.MENU;

        this.show_all();
    }
}

/**
 * AppletsPage contains the applets view for a given panel
 */
public class AppletsPage : Gtk.Box {

    unowned Budgie.Toplevel? toplevel;
    unowned Budgie.DesktopManager? manager = null;

    /* Used applet storage */
    Gtk.ListBox listbox_applets;
    HashTable<string,AppletItem?> items;

    public AppletsPage(Budgie.DesktopManager? manager, Budgie.Toplevel? toplevel)
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
        this.manager = manager;
        this.toplevel = toplevel;

        items = new HashTable<string,AppletItem?>(str_hash, str_equal);
        listbox_applets = new Gtk.ListBox();
        var frame = new Gtk.Frame(null);
        frame.add(listbox_applets);
        this.pack_start(frame, false, false, 0);

        /* Insert them now */
        foreach (var applet in this.toplevel.get_applets()) {
            this.applet_added(applet);
        }

        toplevel.applet_added.connect(this.applet_added);
        toplevel.applet_removed.connect(this.applet_removed);
    }

    /**
     * We have a new applet, so stored it in the list
     */
    private void applet_added(Budgie.AppletInfo? applet)
    {
        if (this.items.contains(applet.uuid)) {
            return;
        }

        /* Stuff the new item into display */
        var item = new AppletItem(applet);
        listbox_applets.add(item);
        items[applet.uuid] = item;
    }

    /**
     * An applet was removed, so remove from our list also
     */
    private void applet_removed(string uuid)
    {
        AppletItem? item = items.lookup(uuid);
        if (item == null) {
            return;
        }
        item.get_parent().destroy();
        items.remove(uuid);
    }

} /* End class */

} /* End namespace */

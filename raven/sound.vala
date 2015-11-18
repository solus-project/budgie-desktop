/*
 * This file is part of arc-desktop
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class SoundWidget : Gtk.Box
{

    private Gtk.Revealer? revealer = null;
    private Gtk.Scale? scale = null;

    public bool expanded {
        public set {
            this.revealer.set_reveal_child(value);
        }
        public get {
            return this.revealer.get_reveal_child();
        }
        default = true;
    }

    private Arc.HeaderWidget? header = null;

    public SoundWidget()
    {
        Object(orientation: Gtk.Orientation.VERTICAL);

        /* TODO: Fix icon */
        scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale.set_draw_value(false);
        header = new Arc.HeaderWidget("", "audio-volume-muted-symbolic", false, scale);
        pack_start(header, false, false);

        revealer = new Gtk.Revealer();
        pack_start(revealer, false, false, 0);

        var label = new Gtk.Label("This widget is not yet complete");

        label.get_style_context().add_class("dim-label");
        label.margin_top = 6;
        var ebox = new Gtk.EventBox();
        ebox.get_style_context().add_class("raven-background");
        ebox.add(label);
        revealer.add(ebox);

        header.bind_property("expanded", this, "expanded");
        expanded = true;
    }

} // End class

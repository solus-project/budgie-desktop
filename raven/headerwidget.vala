/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

/**
 * Simple expander button for the header widget
 */
public class HeaderExpander : Gtk.Button
{
    private Gtk.Image? image;

    private bool _expanded = true;
    private unowned HeaderWidget? owner = null;

    public bool expanded {
        public set {
            this._expanded = value;
            if (this._expanded) {
                image.icon_name = "pan-down-symbolic";
            } else {
                image.icon_name = "pan-end-symbolic";
            }
        }
        public get {
            return this._expanded;
        }
    }

    public HeaderExpander(HeaderWidget? owner)
    {
        Object();
        /* Bind the expanded state on parent and button */
        this.owner = owner;

        image = new Gtk.Image.from_icon_name("pan-down-symbolic", Gtk.IconSize.MENU);
        this.add(image);

        var st = get_style_context();
        st.add_class("flat");
        st.add_class("expander-button");
    }

    public override void clicked()
    {
        this.expanded = !this.expanded;
        this.owner.expanded = expanded;
    }
}

/**
 * Headered expander widget for use in groups within the Raven UI
 */
public class HeaderWidget : Gtk.Box
{
    private Gtk.Image? image = null;
    private Gtk.Label? label = null;
    private Gtk.Button? close_button = null;
    private Gtk.Box? header_box = null;

    /** Display text */
    public string? text {
        public set {
            string? t = value;
            if (t != null) {
                this.label.set_label(value);
                this.label.show();
            } else {
                this.label.hide();
            }
        }
        public get {
            return this.label.get_label();
        }
    }

    /** Icon to show, if any */
    public string? icon_name {
        public set {
            string? iname = value;
            if (iname == null) {
                this.image.hide();
            } else {
                this.image.set_from_icon_name(iname, Gtk.IconSize.MENU);
                this.image.show();
            }
        }
        public owned get {
            return this.image.icon_name;
        }
    }

    /**
     * Whether this headerwidget shows a close button
     */
    public bool can_close {
        public set {
            if (value) {
                this.close_button.show();
            } else {
                this.close_button.hide();
            }
        }
        public get {
            return this.close_button.get_visible();
        }
    }

    /**
     * Manage the expanded state of this expanding header widget
     */
    public bool expanded { public get; public set ; default = true; }

    /**
     * Emitted when this widget has been closed
     */
    public signal void closed();

    public HeaderWidget(string? text, string? icon_name, bool can_close, Gtk.Widget? custom_widget = null, Gtk.Widget? end_widget = null)
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 0);

        get_style_context().add_class("raven-header");

        header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        header_box.margin = 3;
        pack_start(header_box, true, true, 0);

        image = new Gtk.Image();
        image.no_show_all = true;
        image.margin_start = 8;
        image.margin_end = 8;
        header_box.pack_start(image, false, false, 0);

        label = new Gtk.Label("");
        label.no_show_all = true;
        label.set_line_wrap(true);
        label.set_line_wrap_mode(Pango.WrapMode.WORD);
        label.halign = Gtk.Align.START;
        if (custom_widget != null) {
            header_box.pack_start(custom_widget, true, true, 0);
        } else {
            header_box.pack_start(label, true, true, 0);
        }

        /* No custom end-widget, use an expander */
        if (end_widget == null) {
            var expander = new HeaderExpander(this);
            header_box.pack_end(expander, false, false, 0);
        } else {
            header_box.pack_end(end_widget, false, false, 0);
        }

        show_all();

        close_button = new Gtk.Button.from_icon_name("window-close-symbolic", Gtk.IconSize.MENU);
        close_button.get_style_context().add_class("flat");
        close_button.get_style_context().add_class("primary-control");
        close_button.no_show_all = true;
        close_button.get_child().show();
        header_box.pack_start(close_button, false, false, 0);

        close_button.clicked.connect(()=> {
            this.closed();
        });

        this.text = text;
        this.icon_name = icon_name;
        this.can_close = can_close;
    }
}

} /* End namespace */

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */

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

public class KeyboardLayoutPlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new KeyboardLayoutApplet();
    }
}

public static const string DEFAULT_LOCALE = "en_US";
public static const string DEFAULT_LAYOUT = "us";
public static const string DEFAULT_VARIANT = "";

class InputSource
{
    public bool xkb = false;
    public string? layout = null;
    public string? variant = null;
    public string? description = null;
    public uint idx = 0;

    public InputSource(uint idx, string? layout, string? variant, string? description = null, bool xkb = false)
    {
        this.idx = idx;
        this.layout = layout;
        this.variant = variant;
        this.xkb = xkb;
        if (description != null) {
            this.description = description;
        } else {
            this.description = this.layout;
        }
    }
}

public class KeyboardLayoutApplet : Budgie.Applet
{
    private Gtk.EventBox widget;
    private Gtk.EventBox img_wrap;
    private Gtk.Image img;

    /* Tracking input-source settings */
    private Settings? settings;

    /* Keyboard tracking */
    Array<InputSource> sources;
    InputSource fallback;
    private Gnome.XkbInfo? xkb;

    /* Allow showing ie/gb/ type labels */
    private Gtk.Stack label_stack;

    /* For left click interaction... */
    private Gtk.Popover popover;
    private Gtk.ListBox listbox;
    private Budgie.PopoverManager? manager = null;

    public KeyboardLayoutApplet()
    {
        /* Graphical stuff */
        widget = new Gtk.EventBox();

        /* Hook up the popover clicks */
        widget.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (popover.get_visible()) {
                popover.hide();
            } else {
                this.manager.show_popover(img_wrap);
            }
            return Gdk.EVENT_STOP;
        });

        get_style_context().add_class("keyboard-indicator");

        /* Layout */
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        widget.add(layout);

        /* Image */
        img = new Gtk.Image.from_icon_name("input-keyboard-symbolic", Gtk.IconSize.MENU);
        img_wrap = new Gtk.EventBox();
        img_wrap.add(img);
        layout.pack_start(img_wrap, false, false, 0);
        img.set_margin_end(4);
        add(widget);

        /* Stack o' labels */
        label_stack = new Gtk.Stack();
        label_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_UP_DOWN);
        layout.pack_start(label_stack, false, false, 0);

        /* Popover menu magicks */
        popover = new Gtk.Popover(img_wrap);
        popover.get_style_context().add_class("user-menu");
        listbox = new Gtk.ListBox();
        listbox.get_style_context().add_class("content-box");
        popover.add(listbox);
        popover.get_child().show_all();

        /* Settings/init */
        xkb = new Gnome.XkbInfo();
        update_fallback();
        settings = new Settings("org.gnome.desktop.input-sources");
        settings.changed.connect(on_settings_changed);

        /* Forcibly init ourselves */
        on_settings_changed("sources");

        /* Go show up */
        show_all();
    }

    /**
     * Reset the menu/stack
     */
    private void reset_keyboards()
    {
        foreach (Gtk.Widget child in label_stack.get_children()) {
            child.destroy();
        }
        foreach (Gtk.Widget child in listbox.get_children()) {
            child.destroy();
        }

        for (int i = 0; i < sources.length; i++) {
            var kbinfo = sources.index(i);

            /* Firstly we create our display label.. */
            Gtk.EventBox wrap = new Gtk.EventBox();
            Gtk.Label displ_label = new Gtk.Label(kbinfo.layout);
            wrap.add(displ_label);
            displ_label.set_halign(Gtk.Align.START);
            wrap.get_style_context().add_class("keyboard-label");

            /* Pack the display label */
            label_stack.add_named(wrap, kbinfo.idx.to_string());
            wrap.show_all();

            /* Add a menu item in the popover.. */
            Gtk.Button menu_label = new Gtk.Button.with_label(kbinfo.description);
            menu_label.set_relief(Gtk.ReliefStyle.NONE);
            menu_label.set_data("_kb_id", kbinfo.idx.to_string());
            menu_label.set_halign(Gtk.Align.START);
            menu_label.get_style_context().add_class("indicator-item");
            menu_label.get_style_context().add_class("menuitem");
            menu_label.halign = Gtk.Align.FILL;
            menu_label.get_child().halign = Gtk.Align.START;

            menu_label.show_all();

            listbox.add(menu_label);
        }
    }

    private void on_settings_changed(string key)
    {
        if (key == "sources") {
            update_sources();
        } else if (key == "current") {
            update_current();
        }
    }

    /*
     * Reset InputSource list and produce something consumable by xkb
     *
     * TODO: Share code between WM and plugin in private Budgie library in
     * the C rewrite, this is a joke now.
     */
    void update_sources()
    {
        sources = null;
        sources = new Array<InputSource>();

        var val = settings.get_value("sources");
        for (size_t i = 0; i < val.n_children(); i++) {
            InputSource? source = null;
            string? id = null;
            string? type = null;

            val.get_child(i, "(ss)", out id, out type);

            if (id == "xkb") {
                string[] spl = type.split("+");
                string? variant = "";
                if (spl.length > 1) {
                    variant = spl[1];
                }
                string desc = this.get_xkb_description(type);
                source = new InputSource((uint)i, spl[0], variant, desc, true);
                sources.append_val(source);
            } else {
                warning("FIXME: Budgie does not yet support IBUS!");
                continue;
            }
        }

        if (sources.length == 0) {
            /* Always add fallback last, at the very worst it's the only available
             * source and we use the locale guessed source */
            fallback.idx = sources.length;
            sources.append_val(fallback);
        }

        this.reset_keyboards();
    }

    private string get_xkb_description(string id)
    {
        string display_name, short_name, xkb_layout, xkb_variant = null;
        if (xkb.get_layout_info(id, out display_name, out short_name, out xkb_layout, out xkb_variant)) {
            return display_name;
        }
        return id;
    }

    void update_fallback()
    {
        string? type = null;
        string? id = null;
        string? locale = Intl.get_language_names()[0];
        string? display_name = null;
        string? short_name = null;
        string? xkb_layout = null;
        string? xkb_variant = null;

        if (!locale.contains("_")) {
            locale = DEFAULT_LOCALE;
        }

        if (!Gnome.get_input_source_from_locale(locale, out type, out id)) {
            Gnome.get_input_source_from_locale(DEFAULT_LOCALE, out type, out id);
        }

        if(xkb.get_layout_info(id, out display_name, out short_name, out xkb_layout, out xkb_variant)) {
            fallback = new InputSource(0, xkb_layout, xkb_variant, display_name, true);
        } else {
            fallback = new InputSource(0, DEFAULT_LAYOUT, DEFAULT_VARIANT, null, true);
        }
    }

    /**
     * Update our knowledge of the currently selected keyboard layout
     */
    private void update_current()
    {
        uint id = settings.get_uint("current");
        /* Safety: Check we have this guy :] */
        Gtk.Widget? child = label_stack.get_child_by_name(id.to_string());
        if (child == null) {
            message("WARNING: Missing child in layout!!");
            return;
        }
        /* Update to the new kid */
        label_stack.set_visible_child(child);
    }

    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        this.manager = manager;
        manager.register_popover(img_wrap, popover);
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(KeyboardLayoutPlugin));
}

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

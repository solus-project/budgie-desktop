/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2019 Budgie Desktop Developers
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

public const string DEFAULT_LOCALE = "en_US";
public const string DEFAULT_LAYOUT = "us";
public const string DEFAULT_VARIANT = "";

errordomain InputMethodError {
    UNKNOWN_IME
}

/**
 * Reflects the ibus-manager in budgie-wm, with very limited functionality,
 * simply to enable us to mimick the behavior over there.
 */
class AppletIBusManager : GLib.Object
{
    private HashTable<string,weak IBus.EngineDesc> engines = null;
    private List<IBus.EngineDesc>? enginelist = null;
    private bool did_ibus_init = false;
    private bool ibus_available = true;
    private IBus.Bus? bus = null;

    public AppletIBusManager()
    {
        Object();
        this.reset_ibus();
    }

    /**
     * Run init separately so that the owner can connect to the ready() signal
     */
    public void do_init()
    {
        this.engines = new HashTable<string,weak IBus.EngineDesc>(str_hash, str_equal);
        if (Environment.find_program_in_path("ibus-daemon") == null) {
            GLib.message("ibus-daemon unsupported on this system");
            this.ibus_available = false;
            this.ready();
            return;
        }

        /* Get the bus */
        bus = new IBus.Bus.async();

        /* Hook up basic signals */
        bus.connected.connect(this.ibus_connected);
        bus.disconnected.connect(this.ibus_disconnected);
        bus.set_watch_dbus_signal(true);

        /* Should have ibus running already */
        if (bus.is_connected()) {
            this.ibus_connected();
        }
    }

    public signal void ready();

    /**
     * Something on ibus changed so we'll reset our state
     */
    private void reset_ibus()
    {
        this.engines = new HashTable<string,weak IBus.EngineDesc>(str_hash, str_equal);
    }

    private void on_engines_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            this.enginelist = this.bus.list_engines_async_finish(res);
            this.reset_ibus();
            /* Store reference to the engines */
            foreach (var engine in this.enginelist) {
                this.engines[engine.get_name()] = engine;
            }
        } catch (Error e) {
            GLib.message("Failed to get engines: %s", e.message);
            this.reset_ibus();
            return;
        }
        this.ready();
    }

    /**
     * We gained connection to the ibus daemon
     */
    private void ibus_connected()
    {
        /*
         * Init ibus if necessary, to ensure we have the types available to
         * glib. After this, try and gain all the engines
         */
        if (!did_ibus_init) {
            IBus.init();
            did_ibus_init = true;
        }
        this.bus.list_engines_async.begin(-1, null, on_engines_get);
    }

    /**
     * Lost connection to ibus
     */
    private void ibus_disconnected()
    {
        this.reset_ibus();
    }

    /**
     * Attempt to grab the ibus engine for the given name if it
     * exists, or returns null
     */
    public unowned IBus.EngineDesc? get_engine(string name)
    {
        if (this.engines == null) {
            return null;
        }
        return this.engines.lookup(name);
    }
}

class InputSource
{
    public bool xkb = false;
    public string? layout = null;
    public string? variant = null;
    public string? description = null;
    public uint idx = 0;
    public string? ibus_engine = null;

    public InputSource(AppletIBusManager? iman, string id, uint idx, string? layout, string? variant, string? description = null, bool xkb = false) throws Error
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

        /* Attempt to fetch engine in the ibus daemon engine list */
        if (iman == null) {
            return;
        }
        var engine = iman.get_engine(id);
        if (engine == null) {
            if (!xkb) {
                throw new InputMethodError.UNKNOWN_IME("Unknown input method: id");
            }
            return;
        }

        /* Get useful display string */
        string? language = Gnome.get_language_from_code(engine.language, null);
        if (language == null) {
            language = Gnome.get_language_from_locale(engine.language, null);
        }
        this.description = "%s (%s)".printf(language, engine.name);

        string? e_variant = engine.layout_variant;
        if (e_variant != null && e_variant.length > 0) {
            this.variant = e_variant;
        }
        this.layout = engine.language;
        this.ibus_engine = id;
    }
}


class InputSourceMenuItem : Gtk.Button
{

    private Gtk.Label tick_label;
    public uint idx;

    public InputSourceMenuItem(string? description, uint idx)
    {
        Object(can_focus: false);

        this.idx = idx;

        set_relief(Gtk.ReliefStyle.NONE);
        set_halign(Gtk.Align.FILL);

        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(layout);
        Gtk.Label desc_label = new Gtk.Label(description);
        layout.pack_start(desc_label, false, false, 0);
        desc_label.halign = Gtk.Align.START;

        show_all();
        set_no_show_all(true);

        tick_label = new Gtk.Label("  ✓");
        layout.pack_end(tick_label, false, false, 0);
        tick_label.hide();

        get_style_context().add_class("indicator-item");
        get_style_context().add_class("menuitem");

        set_can_focus(false);
    }

    public void set_ticked(bool ticked) {
        if (ticked) {
            tick_label.show();
        } else {
            tick_label.hide();
        }
    }
}

public class KeyboardLayoutApplet : Budgie.Applet
{
    private Gtk.EventBox widget;
    private Gtk.EventBox img_wrap;
    private Gtk.Box layout;
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
    private Budgie.Popover popover;
    private Gtk.ListBox listbox;
    private Budgie.PopoverManager? manager = null;

    /* ibus interfacing */
    private AppletIBusManager? ibus_manager = null;

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
                this.manager.show_popover(widget);
            }
            return Gdk.EVENT_STOP;
        });

        get_style_context().add_class("keyboard-indicator");

        /* Layout */
        layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        widget.add(layout);

        /* Image */
        img = new Gtk.Image.from_icon_name("input-keyboard-symbolic", Gtk.IconSize.MENU);
        img_wrap = new Gtk.EventBox();
        img_wrap.add(img);
        layout.pack_start(img_wrap, false, false, 0);
        add(widget);

        /* Stack o' labels */
        label_stack = new Gtk.Stack();
        label_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_UP_DOWN);
        layout.pack_start(label_stack, false, false, 0);

        /* Popover menu magicks */
        popover = new Budgie.Popover(img_wrap);
        popover.get_style_context().add_class("user-menu");
        listbox = new Gtk.ListBox();
        listbox.set_can_focus(false);
        listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        listbox.get_style_context().add_class("content-box");
        popover.add(listbox);
        popover.get_child().show_all();

        /* Settings/init */
        xkb = new Gnome.XkbInfo();
        settings = new Settings("org.gnome.desktop.input-sources");

        /* Hook up the ibus manager */
        this.ibus_manager = new AppletIBusManager();
        update_fallback();
        this.ibus_manager.ready.connect(this.on_ibus_ready);
        this.ibus_manager.do_init();

        /* Go show up */
        show_all();
    }

    public override void panel_position_changed(Budgie.PanelPosition position)
    {
        Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;
        int margin = 4;
        if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
            orient = Gtk.Orientation.VERTICAL;
            margin = 0;
        }
        img.set_margin_end(margin);
        this.layout.set_orientation(orient);
    }

    /**
     * Only begin listing sources and such when ibus becomes available
     * or we explicitly find it won't work
     */
    private void on_ibus_ready()
    {
        settings.changed.connect(on_settings_changed);

        /* Forcibly init ourselves */
        on_settings_changed("sources");
        on_settings_changed("current");
    }

    /**
     * Tell the WM to change the keyboard to the current selection
     */
    private void on_row_activate(Gtk.Button item)
    {
        var btn = item as InputSourceMenuItem;
        uint idx = btn.idx;

        this.settings.set_uint("current", idx);
        popover.hide();
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
            Gtk.Label displ_label = new Gtk.Label(kbinfo.layout.up());
            wrap.add(displ_label);
            displ_label.set_halign(Gtk.Align.FILL);
            wrap.get_style_context().add_class("keyboard-label");

            /* Pack the display label */
            label_stack.add_named(wrap, kbinfo.idx.to_string());
            wrap.show_all();

            /* Add a menu item in the popover.. */
            InputSourceMenuItem menu_label = new InputSourceMenuItem(kbinfo.description, kbinfo.idx);
            menu_label.clicked.connect(on_row_activate);
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
                source = new InputSource(this.ibus_manager, type, (uint)i, spl[0], variant, desc, true);
                sources.append_val(source);
            } else {
                try {
                    source = new InputSource(this.ibus_manager, type, (uint)i, null, null, null, false);
                    sources.append_val(source);
                } catch (Error e) {
                    message("Error adding source %s|%s: %s", id, type, e.message);
                }
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
            fallback = new InputSource(this.ibus_manager, id, 0, xkb_layout, xkb_variant, display_name, true);
        } else {
            fallback = new InputSource(this.ibus_manager, id, 0, DEFAULT_LAYOUT, DEFAULT_VARIANT, null, true);
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

        /* Use fake menu item selection effect */
        foreach (Gtk.Widget? row in listbox.get_children()) {
            InputSourceMenuItem item = ((Gtk.Bin)row).get_child() as InputSourceMenuItem;
            if (item.idx == id) {
                item.set_ticked(true);
            } else {
                item.set_ticked(false);
            }
        }
        /* Update to the new kid */
        label_stack.set_visible_child(child);
    }

    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        this.manager = manager;
        manager.register_popover(widget, popover);
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

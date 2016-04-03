/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 * Copyright (C) GNOME Shell Developers (Heavy inspiration, logic theft)
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

public static const string DEFAULT_LOCALE = "en_US";
public static const string DEFAULT_LAYOUT = "us";
public static const string DEFAULT_VARIANT = "";

class InputSource
{
    public bool xkb = false;
    public string? layout = null;
    public string? variant = null;
    public uint idx = 0;

    public InputSource(uint idx, string? layout, string? variant, bool xkb = false)
    {
        this.idx = idx;
        this.layout = layout;
        this.variant = variant;
        this.xkb = xkb;
    }
}

public class KeyboardManager : GLib.Object
{
    public unowned Budgie.BudgieWM? wm { construct set ; public get; }
    private Gnome.XkbInfo? xkb;
    string[] options = {};

    Settings? settings = null;
    Array<InputSource> sources;
    InputSource fallback;

    uint current_source = 0;

    public KeyboardManager(Budgie.BudgieWM? wm)
    {
        Object(wm: wm);

        xkb = new Gnome.XkbInfo();

        settings = new Settings("org.gnome.desktop.input-sources");
        settings.changed.connect(on_settings_changed);
        update_fallback();

        on_settings_changed("xkb-options");
        on_settings_changed("sources");
    }

	public delegate void KeyHandlerFunc (Meta.Display display, Meta.Screen screen, Meta.Window? window, Clutter.KeyEvent? event, Meta.KeyBinding binding);

    void switch_input_source(Meta.Display display, Meta.Screen screen,
                             Meta.Window? window, Clutter.KeyEvent? event,
                             Meta.KeyBinding binding)
    {
        current_source = (current_source+1) % sources.length;
        this.apply_layout(current_source);
    }

    void switch_input_source_backward(Meta.Display display, Meta.Screen screen,
                                      Meta.Window? window, Clutter.KeyEvent? event,
                                      Meta.KeyBinding binding)
    {
        current_source = (current_source-1) % sources.length;
        this.apply_layout(current_source);
    }

    public void hook_extra()
    {
        var screen = wm.get_screen();
        var display = screen.get_display();

        /* Hook into GNOME defaults */
        var schema = new Settings("org.gnome.desktop.wm.keybindings");
        display.add_keybinding("switch-input-source", schema, Meta.KeyBindingFlags.NONE, switch_input_source);
        display.add_keybinding("switch-input-source-backward", schema, Meta.KeyBindingFlags.NONE, switch_input_source_backward);
    }

    void on_settings_changed(string key)
    {
        switch (key) {
            case "sources":
                /* Update our sources. */
                update_sources();
                break;
            case "xkb-options":
                /* Update our xkb-options */
                this.options = settings.get_strv(key);
                break;
        }
    }

    /* Reset InputSource list and produce something consumable by xkb */
    void update_sources()
    {
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
                source = new InputSource((uint)i, spl[0], variant, true);
                sources.append_val(source);
            } else {
                warning("FIXME: Budgie does not yet support IBUS!");
                continue;
            }
        }

        /* Always add fallback last, at the very worst it's the only available
         * source and we use the locale guessed source */
        fallback.idx = sources.length;
        sources.append_val(fallback);

        this.apply_layout_group();
        this.apply_layout(0);
    }

    /* Apply our given layout groups to mutter */
    void apply_layout_group()
    {
        unowned InputSource? source;
        string[] layouts = {};
        string[] variants = {};

        for (uint i = 0; i < sources.length; i++) {
            source = sources.index(i);
            layouts += source.layout;
            variants += source.variant;
        }

        string? slayouts = string.joinv(",", layouts);
        string? svariants = string.joinv(",", variants);
        string? options = string.joinv(",", this.options);

        Meta.Backend.get_backend().set_keymap(slayouts, svariants, options);
    }

    /* Apply an indexed layout, i.e. 0 for now */
    void apply_layout(uint idx)
    {
        if (idx > sources.length) {
            idx = 0;
        }
        this.current_source = idx;
        Meta.Backend.get_backend().lock_layout_group(idx);
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
            fallback = new InputSource(0, xkb_layout, xkb_variant, true);
        } else {
            fallback = new InputSource(0, DEFAULT_LAYOUT, DEFAULT_VARIANT, true);
        }
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

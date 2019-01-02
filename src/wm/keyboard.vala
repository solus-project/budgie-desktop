/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2019 Budgie Desktop Developers
 * Copyright (C) GNOME Shell Developers (Heavy inspiration, logic theft)
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

public const string DEFAULT_LOCALE = "en_US";
public const string DEFAULT_LAYOUT = "us";
public const string DEFAULT_VARIANT = "";
/* Default ibus engine to use */
public const string DEFAULT_ENGINE = "xkb:us::eng";

errordomain InputMethodError {
    UNKNOWN_IME
}

class InputSource
{
    public bool xkb = false;
    public string? layout = null;
    public string? variant = null;
    public uint idx = 0;
    public string? ibus_engine = null;

    public InputSource(Budgie.IBusManager? iman, string id, uint idx, string? layout, string? variant, bool xkb = false) throws Error
    {
        this.idx = idx;
        this.layout = layout;
        this.variant = variant;
        this.xkb = xkb;
        weak IBus.EngineDesc? engine = null;

        /* Attempt to fetch engine in the ibus daemon engine list */
        if (iman != null) {
            engine = iman.get_engine(id);
            if (engine == null) {
                if (!xkb) {
                    throw new InputMethodError.UNKNOWN_IME("Unknown input method: id");
                }
                return;
            }
        }

        string? e_variant = engine.layout_variant;
        if (e_variant != null && e_variant.length > 0) {
            this.variant = e_variant;
        }
        this.layout = engine.layout;
        this.ibus_engine = id;
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
    ulong sig_id = 0;

    /* Used to spawn and manage ibus */
    IBusManager? ibus_manager;

    /* Guard ourselves from any future potential derps */
    private bool is_keyboard_held = false;

    public KeyboardManager(Budgie.BudgieWM? wm)
    {
        Object(wm: wm);

        xkb = new Gnome.XkbInfo();

        /* Only hook things up when ibus is setup, whether it failed or not */
        ibus_manager = new IBusManager(this);
        ibus_manager.ready.connect(on_ibus_ready);
        ibus_manager.do_init();
    }

    private void on_ibus_ready()
    {
        settings = new Settings("org.gnome.desktop.input-sources");

        /* Special handling of the current source. */
        sig_id = settings.changed["current"].connect(on_current_source_changed);

        settings.changed.connect(on_settings_changed);
        update_fallback();

        on_settings_changed("xkb-options");
        on_settings_changed("sources");
    }

	public delegate void KeyHandlerFunc (Meta.Display display, Meta.Window? window, Clutter.KeyEvent? event, Meta.KeyBinding binding);

    void switch_input_source(Meta.Display display,
                             Meta.Window? window, Clutter.KeyEvent? event,
                             Meta.KeyBinding binding)
    {
        current_source = (current_source+1) % sources.length;
        this.hold_keyboard();
        this.apply_layout(current_source);
        this.apply_ibus();
    }

    void switch_input_source_backward(Meta.Display display,
                                      Meta.Window? window, Clutter.KeyEvent? event,
                                      Meta.KeyBinding binding)
    {
        current_source = (current_source-1) % sources.length;
        this.hold_keyboard();
        this.apply_layout(current_source);
        this.apply_ibus();
    }

    public void hook_extra()
    {
        var display = wm.get_display();

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
            default:
                return;
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

                try {
                    source = new InputSource(this.ibus_manager, type, (uint)i, spl[0], variant, true);
                    sources.append_val(source);
                } catch (Error e) {
                    warning("Failed to create InputSource: %s", e.message);
                }
            } else {
                try {
                    source = new InputSource(this.ibus_manager, type, (uint)i, null, null, false);
                } catch (Error e) {
                    message("Error adding source %s|%s: %s", id, type, e.message);
                    continue;
                }
                sources.append_val(source);
            }
        }

        if (sources.length == 0) {
            /* Always add fallback last, at the very worst it's the only available
             * source and we use the locale guessed source */
            fallback.idx = sources.length;
            sources.append_val(fallback);
        }

        this.hold_keyboard();
        this.apply_layout_group();

        /* Always start up with the last selected index if possible */
        var default_idx = this.settings.get_uint("current");
        this.apply_layout(default_idx);
        this.apply_ibus();
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
        /* Send this off to gsettings so that clients know what our idx is */
        this.write_source_index(idx);
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
            try {
                fallback = new InputSource(this.ibus_manager, id, 0, xkb_layout, xkb_variant, true);
            } catch (Error e) {
                warning("Failed to create InputSource: %s", e.message);
            }
        } else {
            try {
                fallback = new InputSource(this.ibus_manager, id, 0, DEFAULT_LAYOUT, DEFAULT_VARIANT, true);
            } catch (Error e) {
                warning("Failed to create InputSource: %s", e.message);
            }
        }
    }

    /**
     * Update the index in gsettings so that clients know the current
     */
    private void write_source_index(uint index)
    {
        SignalHandler.block(this.settings, this.sig_id);
        this.settings.set_uint("current", index);
        this.settings.apply();
        SignalHandler.unblock(this.settings, this.sig_id);
    }

    /**
     * Someone else changed the current source, do somethin' about it
     */
    private void on_current_source_changed()
    {
        uint new_source = this.settings.get_uint("current");
        this.hold_keyboard();
        apply_layout(new_source);
        this.apply_ibus();
    }

    /**
     * Apply the ibus engine and then release the keyboard
     */
    private void apply_ibus()
    {
        string engine_name;
        InputSource? current = sources.index(current_source);
        if (current != null && current.ibus_engine != null) {
            engine_name = current.ibus_engine;
        } else {
            engine_name = DEFAULT_ENGINE;
        }
        this.ibus_manager.set_engine(engine_name);
    }

    /**
     * Unfreeze the keyboard
     */
    public void release_keyboard()
    {
        if (!is_keyboard_held) {
            return;
        }
        wm.get_display().ungrab_keyboard(wm.get_display().get_current_time());
        is_keyboard_held = false;
    }

    /**
     * Freeze the keyboard so we don't loose input events
     */
    public void hold_keyboard()
    {
        if (is_keyboard_held) {
            return;
        }
        wm.get_display().freeze_keyboard(wm.get_display().get_current_time());
        is_keyboard_held = true;
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

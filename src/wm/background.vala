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

namespace Budgie {


public const string BACKGROUND_SCHEMA      = "org.gnome.desktop.background";
public const string PICTURE_URI_KEY        = "picture-uri";
public const string PRIMARY_COLOR_KEY      = "primary-color";
public const string SECONDARY_COLOR_KEY    = "secondary-color";
public const string COLOR_SHADING_TYPE_KEY = "color-shading-type";
public const string BACKGROUND_STYLE_KEY   = "picture-options";
public const string GNOME_COLOR_HACK       = "gnome-control-center/pixmaps/noise-texture-light.png";
public const string ACCOUNTS_SCHEMA        = "org.freedesktop.Accounts";

public class BudgieBackground : Meta.BackgroundGroup
{

    public unowned Meta.Display? display { construct set ; public get; }
    public int index { construct set ; public get; }

    private Settings? settings = null;


    private Clutter.Actor? bg = null;
    private Clutter.Actor? old_bg = null;
    Meta.BackgroundImageCache? cache = null;

    const int BACKGROUND_TIMEOUT = 850;


    /* Ensure we're efficient with changed queries and dont update the WP
     * a bunch of times
     */
    Gnome.BG? gnome_bg;

    /**
     * Determine if the wallpaper is a colour wallpaper or not
     */
    private bool is_color_wallpaper(string bg_filename)
    {
        if (gnome_bg.get_placement() == GDesktop.BackgroundStyle.NONE || bg_filename.has_suffix(GNOME_COLOR_HACK)) {
            return true;
        }
        return false;
    }

    public BudgieBackground(Meta.Display? display, int index)
    {
        Object(display: display, index: index);
        Meta.Rectangle rect;

        cache = Meta.BackgroundImageCache.get_default();

        settings = new Settings("org.gnome.desktop.background");
        gnome_bg = new Gnome.BG();

        rect = display.get_monitor_geometry(this.index);
        this.set_position(rect.x, rect.y);
        this.set_size(rect.width, rect.height);

        /* If the background keys change, proxy it to libgnomedesktop */
        settings.change_event.connect(()=> {
            gnome_bg.load_from_preferences(this.settings);
            return false;
        });

        gnome_bg.changed.connect(()=> {
            this.update();
        });
        this.set_background_color(Clutter.Color.get_static(Clutter.StaticColor.BLACK));

        /* Do the initial load */
        gnome_bg.load_from_preferences(this.settings);
    }

    void remove_old(Clutter.Actor? actor)
    {
        File? bwm_file = actor.get_data("_bwm_uri");
        if (bwm_file != null) {
            cache.purge(bwm_file);
            images.remove(bwm_file.get_uri());
            bwm_file = null;
        }

        actor.destroy();
        this.old_bg = null;
    }

    private HashTable<string,Meta.BackgroundImage?> images = null;

    /**
     * Load the image from the meta background cache
     *
     * Note we purposefully load the image into the cache manually, as this will
     * enable smooth background transitions
     */
    private async void load_uri(string uri)
    {
        if (images == null) {
            images = new HashTable<string,Meta.BackgroundImage>(str_hash, str_equal);
        }

        File f = File.new_for_uri(uri);
        bg.set_data("_bwm_uri", f);

        Meta.BackgroundImage? image = cache.load(f);
        if (image.is_loaded()) {
            return;
        }
        images.insert(uri, image);
        ulong rid = 0;
        rid = image.loaded.connect(()=> {
            image.disconnect(rid);
            Idle.add(load_uri.callback);
        });
        yield;
        return;
    }

    /**
     * Remove the old wallpaper during the new wallpaper update
     */
    void begin_remove_old(Clutter.Actor? actor)
    {
        if (old_bg != null && old_bg != this.bg) {
            old_bg.transitions_completed.connect(remove_old);
            old_bg.save_easing_state();
            old_bg.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);
            old_bg.set_easing_duration(BACKGROUND_TIMEOUT);
            old_bg.set("opacity", 0);
            old_bg.restore_easing_state();
        }
    }

    /**
     * call accountsservice dbus with the background file name
     * to update the greeter background if the display
     * manager supports the dbus call.
     */
    void set_accountsservice_user_bg(string background) {
        DBusConnection bus;
        Variant        variant;

        try {
            bus = Bus.get_sync(BusType.SYSTEM);
        } catch (IOError e) {
            warning("Failed to get system bus: %s", e.message);
            return;
        }

        try {
            variant = bus.call_sync(ACCOUNTS_SCHEMA, "/org/freedesktop/Accounts", ACCOUNTS_SCHEMA, "FindUserByName",
                new Variant("(s)", Environment.get_user_name()), new VariantType("(o)"), DBusCallFlags.NONE, -1, null);
        } catch (Error e) {
            warning("Could not contact accounts service to look up '%s': %s", Environment.get_user_name(), e.message);
            return;
        }

        string object_path = variant.get_child_value(0).get_string();

        try {
            bus.call_sync(ACCOUNTS_SCHEMA, object_path, "org.freedesktop.DBus.Properties", "Set",
                new Variant("(ssv)", "org.freedesktop.DisplayManager.AccountsService", "BackgroundFile",
                    new Variant.string(background)
                ), new VariantType("()"), DBusCallFlags.NONE, -1, null);
        } catch (Error e) {
            warning("Failed to set the background '%s': %s", background, e.message);
        }
    }

    /**
     * Wallpaper updated, begin modifying the new one
     */
    void on_update()
    {
        bg.save_easing_state();
        bg.transitions_completed.connect(begin_remove_old);
        bg.set_easing_mode(Clutter.AnimationMode.EASE_IN_EXPO);
        bg.set_easing_duration(BACKGROUND_TIMEOUT);
        bg.set("opacity", 255);
        bg.restore_easing_state();
    }

    void update()
    {
        string? bg_filename = gnome_bg.get_filename();;
        GDesktop.BackgroundShading shading_direction;
        Meta.Rectangle rect;
        Clutter.Color? primary_color = Clutter.Color();
        Clutter.Color? secondary_color = Clutter.Color();

        var actor = new Meta.BackgroundActor(display, index);
        var background = new Meta.Background(display);
        actor.set_background(background);

        rect = display.get_monitor_geometry(index);
        actor.set_size(rect.width, rect.height);
        actor.set("opacity", 0);
        actor.show();

        insert_child_at_index(actor, -1);
        if (this.bg != null) {
            this.old_bg = bg;
        }
        this.bg = actor;


        shading_direction = (GDesktop.BackgroundShading)settings.get_enum(COLOR_SHADING_TYPE_KEY);
        var color_str = settings.get_string(PRIMARY_COLOR_KEY);
        if (color_str != null && color_str != "") {
            primary_color = Clutter.Color.from_string(color_str);
            color_str = null;
        }

        color_str = settings.get_string(SECONDARY_COLOR_KEY);
        if (color_str != null && color_str != "") {
            secondary_color = Clutter.Color.from_string(color_str);
            color_str = null;
        }

        /* Set colour where appropriate, and for now dont parse .xml files */
        if (this.is_color_wallpaper(bg_filename) || bg_filename.has_suffix(".xml")) {
            background.changed.connect(on_update);
            if (shading_direction == GDesktop.BackgroundShading.SOLID) {
                background.set_color(primary_color);
            } else {
                background.set_gradient(shading_direction, primary_color, secondary_color);
            }
        } else {
            var bg_file = File.new_for_uri("file://" + bg_filename);
            /* Once we know the image is in the image cache, set the background */

            load_uri.begin("file://" + bg_filename, ()=> {
                background.set_file(bg_file, gnome_bg.get_placement());
                on_update();
                set_accountsservice_user_bg(bg_filename);
            });
        }
    }
} /* End BudgieBackground */

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

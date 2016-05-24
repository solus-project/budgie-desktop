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

namespace Budgie {

 
public static const string BACKGROUND_SCHEMA      = "org.gnome.desktop.background";
public static const string PICTURE_URI_KEY        = "picture-uri";
public static const string PRIMARY_COLOR_KEY      = "primary-color";
public static const string SECONDARY_COLOR_KEY    = "secondary-color";
public static const string COLOR_SHADING_TYPE_KEY = "color-shading-type";
public static const string BACKGROUND_STYLE_KEY   = "picture-options";
public static const string GNOME_COLOR_HACK       = "gnome-control-center/pixmaps/noise-texture-light.png";

public class BudgieBackground : Meta.BackgroundGroup
{

    public unowned Meta.Screen? screen { construct set ; public get; }
    public int index { construct set ; public get; }

    private Settings? settings = null;


    private Clutter.Actor? bg = null;
    private Clutter.Actor? old_bg = null;

    static const int BACKGROUND_TIMEOUT = 850;


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

    public BudgieBackground(Meta.Screen? screen, int index)
    {
        Object(screen: screen, index: index);
        Meta.Rectangle rect;

        settings = new Settings("org.gnome.desktop.background");
        gnome_bg = new Gnome.BG();

        rect = screen.get_monitor_geometry(this.index);
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

        unowned Meta.BackgroundImageCache? cache = Meta.BackgroundImageCache.get_default();
        File f = File.new_for_uri(uri);
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

        var actor = new Meta.BackgroundActor(screen, index);
        var background = new Meta.Background(screen);
        actor.set_background(background);

        rect = screen.get_monitor_geometry(index);
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

/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
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

    public BudgieBackground(Meta.Screen? screen, int index)
    {
        Object(screen: screen, index: index);
        Meta.Rectangle rect;

        settings = new Settings("org.gnome.desktop.background");

        rect = screen.get_monitor_geometry(this.index);
        this.set_position(rect.x, rect.y);
        this.set_size(rect.width, rect.height);

        settings.changed.connect(on_key_change);

        this.set_background_color(Clutter.Color.get_static(Clutter.StaticColor.BLACK));
        this.update();
    }

    void on_key_change()
    {
        update();
    }

    void remove_old(Clutter.Actor? actor)
    {
        actor.destroy();
        this.old_bg = null;
    }

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
        string? bg_filename = settings.get_string(PICTURE_URI_KEY);
        GDesktop.BackgroundStyle style;
        GDesktop.BackgroundShading shading_direction;
        Meta.Rectangle rect;
        Clutter.Color primary_color = Clutter.Color();
        Clutter.Color secondary_color = Clutter.Color();


        style = (GDesktop.BackgroundStyle)settings.get_enum(BACKGROUND_STYLE_KEY);
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

        background.changed.connect(on_update);

        shading_direction = (GDesktop.BackgroundShading)settings.get_enum(COLOR_SHADING_TYPE_KEY);
        var color_str = settings.get_string(PRIMARY_COLOR_KEY);
        if (color_str != null && color_str != "") {
            primary_color.from_string(color_str);
            color_str = null;
        }

        color_str = settings.get_string(SECONDARY_COLOR_KEY);
        if (color_str != null && color_str != "") {
            secondary_color.from_string(color_str);
            color_str = null;
        }

        if (style == GDesktop.BackgroundStyle.NONE || bg_filename.has_prefix(GNOME_COLOR_HACK)) {
            if (shading_direction == GDesktop.BackgroundShading.SOLID) {
                background.set_color(primary_color);
            } else {
                background.set_gradient(shading_direction, primary_color, secondary_color);
            }
        } else {
            var bg_file = File.new_for_uri(bg_filename);

            background.set_file(bg_file, style);
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

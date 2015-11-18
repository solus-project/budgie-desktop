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

namespace Arc
{

/**
 * Alternative to a separator, gives a shadow effect
 */
public class ShadowBlock : Gtk.EventBox
{

    private int size;
    private PanelPosition pos;
    private bool horizontal = false;
    int rm = 0;

    public PanelPosition position {
        public set {
            var old = pos;
            pos = value;
            update_position(old);
        }
        public get {
            return pos;
        }
    }

    public int required_size {
        public set {
            size = value;
            queue_resize();
        }
        public get {
            return size;
        }
    }

    public int removal {
        public set {
            rm = value;
            queue_resize();
        }
        public get {
            return rm;
        }
    }

    void update_position(PanelPosition? old)
    {
        if (pos == PanelPosition.TOP || pos == PanelPosition.BOTTOM) {
            horizontal = true;
        } else {
            horizontal = false;
        }
        queue_resize();
    }

    public ShadowBlock(PanelPosition position)
    {
        get_style_context().add_class("shadow-block");
        get_style_context().remove_class("background");
        this.position = position;
    }

    public override void get_preferred_height(out int min, out int nat)
    {
        if (horizontal) {
            min = 5;
            nat = 5;
            return;
        };
        min = nat = required_size - rm;
    }

    public override void get_preferred_height_for_width(int width, out int min, out int nat)
    {
        if (horizontal) {
            min = 5;
            nat = 5;
            return;
        }
        min = nat = required_size - rm;
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        if (horizontal) {
            min = nat = required_size - rm;
            return;
        }
        min = nat = 5;
    }

    public override void get_preferred_width_for_height(int height, out int min, out int nat)
    {
        if (horizontal) {
            min = nat = required_size - rm;
            return;
        }
        min = nat = 5;
    }
}

}

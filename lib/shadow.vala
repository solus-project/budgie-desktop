/*
 * This file is part of budgie-desktop.
 *
 * Copyright (C) 2015 Ikey Doherty
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Budgie
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

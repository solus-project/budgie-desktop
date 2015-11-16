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

public abstract class Toplevel : Gtk.Window
{

    /**
     * Length of our shadow component, to enable Raven blending
     */
    public int shadow_width { public set ; public get; }

    /**
     * Depth of our shadow component, to enable Raven blending
     */
    public int shadow_depth { public set ; public get; default = 5; }

    /**
     * Our required size (height or width dependening on orientation
     */
    public int intended_size { public set ; public get; }
}


[Flags]
public enum PanelPosition {
    NONE        = 1 << 0,
    BOTTOM      = 1 << 1,
    TOP         = 1 << 2,
    LEFT        = 1 << 3,
    RIGHT       = 1 << 4
}

[Flags]
public enum AppletPackType {
    START       = 1 << 0,
    END         = 1 << 2
}

[Flags]
public enum AppletAlignment {
    START       = 1 << 0,
    CENTER      = 1 << 1,
    END         = 1 << 2
}

} /* End namespace */

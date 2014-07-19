/*
 * BudgiePlugin.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public enum PanelPosition
{
    BOTTOM = 0,
    TOP,
    LEFT,
    RIGHT
}

public interface Plugin : Peas.ExtensionBase
{
    /**
     * budgie_plugin_get_panel_widget:
     * 
     * Returns: (transfer none): A Gtk+ widget for use on the BudgiePanel
     */
    public abstract Gtk.Widget get_panel_widget();

    /**
     * budgie_plugin_orientation_changed:
     *
     * Informs Plugin's that their parent layout has been altered and should accomodate
     *
     * @param orientation: (transfer none): The orientation of the applet
     */
    public signal void orientation_changed(Gtk.Orientation orientation);

    /**
     * budgie_plugin_position_changed:
     *
     * Informs Plugin's that their parent container has moved on screen
     * i.e. the panel has moved to a different screen edge
     *
     * @param position: (transfer none): Position of the container's screen-edge
     */
    public signal void position_changed(Budgie.PanelPosition position);
}

}

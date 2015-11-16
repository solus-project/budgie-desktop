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

public interface PopoverManager : GLib.Object
{
    /**
     * arc_popover_manager_register_popover:
     * @widget: Widget that the popover is associated with
     * @popover: a #GtkPopover to assicate with @widget
     * 
     * Register a popover with this manager instance
     */
    public abstract void register_popover(Gtk.Widget? widget, Gtk.Popover? popover);

    /**
     * arc_popover_manager_unregister_popover:
     * @widget: Widget that the popover is associated with
     *
     * Unregister a widget that was previously registered
     */
    public abstract void unregister_popover(Gtk.Widget? widget);
}

/**
 * ArcPlugin
 */
public interface Plugin : GLib.Object
{
    /**
     * arc_plugin_get_panel_widget:
     * 
     * Returns: (transfer full): A Gtk+ widget for use on the ArcPanel
     */
    public abstract Arc.Applet get_panel_widget();
}

/**
 * ArcApplet
 */
public class Applet : Gtk.Bin
{

    /**
     * arc_applet_construct:
     *
     * Construct a new BudgieApplet
     *
     * Returns: (transfer full): A new BudgieApplet instance
     */
    public Applet() { }

    /**
     * arc_applet_update_popovers:
     * @manager: a valid #ArcPopoverManager
     *
     * Inform the applet it needs to register it's popovers. The #PopoverManager
     * is always valid
     */
    public virtual void update_popovers(Arc.PopoverManager? manager) { }
}

}

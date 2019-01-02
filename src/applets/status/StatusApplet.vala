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
public class StatusPlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new StatusApplet();
    }
}

public class StatusApplet : Budgie.Applet
{

    protected Gtk.Box widget;
#if WITH_BLUETOOTH
    protected BluetoothIndicator blue;
#endif
    protected SoundIndicator sound;
    protected PowerIndicator power;
    protected Gtk.EventBox? wrap;
    private Budgie.PopoverManager? manager = null;

    /**
     * Set up an EventBox for popovers
     */
    private void setup_popover(Gtk.Widget? parent_widget, Budgie.Popover? popover)
    {
        parent_widget.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (popover.get_visible()) {
                popover.hide();
            } else {
                this.manager.show_popover(parent_widget);
            }
            return Gdk.EVENT_STOP;
        });
    }

    public StatusApplet()
    {
        wrap = new Gtk.EventBox();
        add(wrap);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        wrap.add(widget);

        show_all();

        power = new PowerIndicator();
        widget.pack_start(power, false, false, 0);
        /* Power shows itself - we dont control that */

        sound = new SoundIndicator();
        widget.pack_start(sound, false, false, 2);
        sound.show_all();

        /* Hook up the popovers */
        this.setup_popover(power.ebox, power.popover);
        this.setup_popover(sound.ebox, sound.popover);

#if WITH_BLUETOOTH
        blue = new BluetoothIndicator();
        widget.pack_start(blue, false, false, 2);
        blue.show_all();
        this.setup_popover(blue.ebox, blue.popover);
#endif
    }

    public override void panel_position_changed(Budgie.PanelPosition position)
    {
        Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;
        if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
            orient = Gtk.Orientation.VERTICAL;
        }
        this.widget.set_orientation(orient);
        this.power.change_orientation(orient);
    }

    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        this.manager = manager;
        manager.register_popover(power.ebox, power.popover);
        manager.register_popover(sound.ebox, sound.popover);
#if WITH_BLUETOOTH
        manager.register_popover(blue.ebox, blue.popover);
#endif
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(StatusPlugin));
}

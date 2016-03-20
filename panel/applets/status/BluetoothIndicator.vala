/*
 * BluetoothIndicator.vala
 *
 * Copyright 2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class BluetoothIndicator : Gtk.Bin
{
    public Gtk.Image? image = null;

    public BluetoothIndicator()
    {
        image = new Gtk.Image.from_icon_name("bluetooth-disabled-symbolic", Gtk.IconSize.MENU);

        add(image);

        show_all();
    }
} // End class

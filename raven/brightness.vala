/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2016 Gregor Müller-Riederer
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class BrightnessWidget : Gtk.Box
{
    private Gtk.Scale? scale = null;
    private ulong scale_id = 0;
    private const string backlight_path = "/sys/class/backlight";
    private string backlight_controller;
    private int max_brightness;

    private Budgie.HeaderWidget? header = null;

    
    public BrightnessWidget()
    {
        Object(orientation: Gtk.Orientation.VERTICAL);

        get_style_context().add_class("brightness-widget");

        /* TODO: Fix icon */
        scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale.set_draw_value(false);
        scale_id = scale.value_changed.connect(on_bightness_scale_change);

        header = new Budgie.HeaderWidget("", "display-brightness-symbolic", false, scale);
        pack_start(header, false, false);

        backlight_controller = ""; 

        /* Default value for max brightness in case there's no max_brightness file present */
         max_brightness = 976; 

        /* Try to find a controller */
        get_controller();      
    }

    /**
     * New brightness from our scale
     */
    private void on_bightness_scale_change()
    {
        write_brightness((int)scale.get_value());
    }

    public void update_scale()
    {
        var brightness = read_brightness();
        scale.set_value(brightness);        
    }

    public bool has_controller()
    {
        return backlight_controller != "";
    }

    public bool get_controller()
    {
        bool controller_found = false;
        var directory = File.new_for_path (backlight_path);
        var enumerator = directory.enumerate_children("standard::*",FileQueryInfoFlags.NONE);
        FileInfo info;
        while((info = enumerator.next_file()) != null)
        {
            stdout.printf("File: "+info.get_name()+" Filetype:"+info.get_file_type().to_string());
            if(info.get_file_type() == FileType.DIRECTORY)
            {

                /* Controller found, check if it contains a brightness file */
                var bright_file = File.new_for_path(backlight_path+"/"+info.get_name()+"/brightness");
                if(bright_file.query_exists())
                {
                    
                    backlight_controller = backlight_path+"/"+info.get_name();
                    controller_found = true;

                    /* Check permissions, read and write brightness */
                    var brightness = read_brightness();
                    try
                    {
                        write_brightness(brightness);
                    }
                    catch(IOError e)
                    {
                        /* No permissions */
                        backlight_controller = "";
                        controller_found = false;
                    }

                    if(controller_found) break;
                }
            }        
        }

        if(controller_found)
        {
            SignalHandler.block(scale, scale_id);

            scale.set_value(read_brightness()); 

            /* Try to get the maximum brightness */
            var max_bright_file = File.new_for_path(backlight_controller+"/max_brightness");
            if(max_bright_file.query_exists())
            {
                /* read the value */
                var dis = new DataInputStream(max_bright_file.read());
                var line = dis.read_line(null);
                max_brightness = int.parse(line);

                /* Each scroll increments by 5% */
                var step_size = max_brightness / 20;
                /* Set minimal brightness to first step */
                scale.set_range(step_size, max_brightness);
                scale.set_increments(step_size, step_size);
            }
            
            SignalHandler.unblock(scale, scale_id);
        }

        return controller_found;
    }

    /**
     * Read the brightness value
     */
    private int read_brightness()
    {
        if(backlight_controller != "")
        {
            var file = File.new_for_path(backlight_controller+"/brightness");
            var dis = new DataInputStream(file.read());
            var line = dis.read_line(null);
            return(int.parse(line));
        }

        return 0;
    }

    /**
     * Write the new brightness value
     */
    private void write_brightness(int brightness) throws IOError
    {
        if(backlight_controller != "")
        {

            var file = File.new_for_path(backlight_controller+"/brightness");
            var dis = new DataOutputStream(file.append_to(0));
            dis.put_string(brightness.to_string());
        }
    }

    

} // End class

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

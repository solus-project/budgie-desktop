/*
 * This file is part of budgie-desktop
 *
 * Copyright(C) 2014-2016 Mike Krüger <mikekrueger81@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 *(at your option) any later version.
 */

public class SensorsPlugin: Budgie.Plugin, Peas.ExtensionBase 
{
    public Budgie.Applet get_panel_widget(string uuid) 
    {
        return new SensorsApplet(uuid);
    }
}

public class SensorsSettings: Gtk.Grid 
{
    public SensorsSettings(Settings? settings) 
    {
        set_column_spacing(10);
        set_margin_top(10);
        set_margin_end(10);
        set_margin_bottom(10);
        set_margin_start(10);

        Gtk.Label label = new Gtk.Label("Fahrenheit");
        attach(label, 0, 0, 1, 1);

        Gtk.Switch fahrenheitSwitch = new Gtk.Switch();
        attach(fahrenheitSwitch, 1, 0, 2, 1);

        settings.bind("fahrenheit", fahrenheitSwitch, "active", SettingsBindFlags.DEFAULT);
    }
}

public class SensorsApplet: Budgie.Applet 
{
    protected Gtk.EventBox widget;
    protected Gtk.Label label;
    protected bool fahrenheit = false;
    protected Settings? settings;

    public string uuid { public set; public get; }

    public SensorsApplet(string uuid) 
    {
        Object(uuid: uuid);

        settings_schema = "com.solus-project.sensors";
        settings_prefix = "/com/solus-project/budgie-panel/instance/sensors";
        settings = this.get_applet_settings(uuid);
        settings.changed.connect(on_settings_change);

        widget = new Gtk.EventBox();
        label = new Gtk.Label("Sensors");
        widget.add(label);
        label.show();

        getSensors();
        add(widget);
        show_all();

        Timeout.add_seconds_full(GLib.Priority.LOW, 1, getSensors);
    }

    public override Gtk.Widget? get_settings_ui()
    {
        return new SensorsSettings(this.get_applet_settings(uuid));
    }

    public override bool supports_settings() 
    {
        return true;
    }

    void on_settings_change(string key) 
    {
        if("fahrenheit" == key) {
            fahrenheit = settings.get_boolean(key);
        }
    }

    private bool getSensors() 
    {
        string edit = "";
        string output = "";
        string error = "";
        string result = "";

        int status = -1;

        string[] lines;
        string[] editlines;
        string[] subeditlines;

        try 
        {
            if(fahrenheit)
            {
                Process.spawn_command_line_sync("sensors -f",
                                                 out output,
                                                 out error,
                                                 out status);
            }
            else 
            {
                Process.spawn_command_line_sync("sensors",
                                                 out output,
                                                 out error,
                                                 out status);
            }
            // check the output and create the result
            lines = output.split("\n");
            for(int i = 0; i < lines.length; i++)
            {
                if("Core" in lines[i])
                {
                    if(lines[i] != null)
                    {
                        editlines = lines[i].split(":");

                        if(editlines.length >= 1 && 
                           editlines[1] != null)
                        {
                            editlines[1] = editlines[1].strip();
                            subeditlines = editlines[1].split("  ");

                            if(subeditlines.length >= 1 &&
                               subeditlines[0] != null)
                            {
                                edit = edit + subeditlines[0] + " ";
                                result = edit.replace("+", "");
                                result = result.strip();
                            }
                        }
                    }
                }
            }

            // unload variables
            edit = null;
            output = null;
            error = null;

            lines = null;
            editlines = null;
            subeditlines = null;

            if("" == result){
               result = "No sensors found!";
            }

            label.set_text(result);
            label.show();

        }
        catch(Error e)
        {
            message("Unable to get sensors informations %s", e.message);
        }
        return true;
    }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(SensorsPlugin));
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

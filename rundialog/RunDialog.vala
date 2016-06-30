/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

/**
 * The meat of the operation
 */
public class RunDialog : Gtk.ApplicationWindow
{

    public RunDialog(Gtk.Application app)
    {
        Object(application: app);
        set_keep_above(true);
        set_skip_pager_hint(true);
        set_skip_taskbar_hint(true);
        set_resizable(false);
        set_position(Gtk.WindowPosition.CENTER);
    }
}

/**
 * GtkApplication for single instance wonderness
 */
public class RunDialogApp : Gtk.Application
{

    private RunDialog? rd = null;

    public RunDialogApp()
    {
        Object(application_id: "com.solus_project.BudgieRunDialog", flags: 0);
    }

    public override void activate()
    {
        if (rd == null) {
            rd = new RunDialog(this);
        }
        rd.present();
    }
}

} /* End namespace */

public static int main(string[] args)
{
    Budgie.please_link_me_libtool_i_have_great_themes();
    Budgie.RunDialogApp rd = new Budgie.RunDialogApp();
    return rd.run(args);
}

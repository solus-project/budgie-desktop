/*
 * RunDialog.vala
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

public class RunDialog : Gtk.Window
{

    private Gtk.Image side_image;
    private Gtk.SearchEntry entry;
    private GMenu.Tree tree;

    private Gee.HashMap<string,GLib.DesktopAppInfo> mapping;

    private static string default_icon = "system-run-symbolic";

    public RunDialog()
    {
        side_image = new Gtk.Image.from_icon_name(default_icon, Gtk.IconSize.INVALID);
        side_image.pixel_size = 96;
        side_image.halign = Gtk.Align.START;
        side_image.valign = Gtk.Align.START;
        entry = new Gtk.SearchEntry();

        // Initialisation stuffs
        window_position = Gtk.WindowPosition.CENTER;
        destroy.connect(() => Gtk.main_quit());
        set_keep_above(true);

        // Enable RGBA for transparent window background
        var visual = screen.get_rgba_visual();
        if (visual != null) {
            set_visual(visual);
        } else {
            GLib.warning("Unable to set RGBA visual: RunDialog will look ugly");
        }
        var main_layout = new Gtk.Overlay();
        add(main_layout);
        var layout = new Gtk.EventBox();
        layout.get_style_context().add_class("budgie-run-dialog-content");

        /* Window sizing hacks relating to the image size */
        main_layout.add(layout);
        main_layout.add_overlay(side_image);
        side_image.show_all();
        side_image.margin = 15;
        entry.margin_left = side_image.pixel_size-side_image.margin;
        entry.margin_right = 10;
        layout.add(entry);
        layout.margin = 22;
        layout.margin_left = side_image.margin+layout.margin;
        layout.margin_right = 0;

        set_size_request(350+(side_image.margin), side_image.pixel_size+side_image.margin);

        this.set_decorated(false);

        // Load our default styling
        try {
            var prov = new Gtk.CssProvider();
            var file = File.new_for_uri("resource://com/evolve-os/budgie/run-dialog/rundialog-style.css");
            prov.load_from_file(file);

            Gtk.StyleContext.add_provider_for_screen(this.screen, prov,
                Gtk.STYLE_PROVIDER_PRIORITY_USER);
        } catch (GLib.Error e) {
            stderr.printf("CSS loading issue: %s\n", e.message);
        }

        // Set up auto-complete
        var store = new Gtk.ListStore(1, typeof(string));
        Gtk.TreeIter iter;

        load_menus();

        // Shove this back into a model
        if (mapping != null) {
            foreach (var entry in mapping.entries) {
                store.append(out iter);
                store.set(iter, 0, entry.key);
            }
        }

        // Nice auto-completion, based on command lines (executables)
        var completion = new Gtk.EntryCompletion();
        completion.set_model(store);
        completion.set_text_column(0);
        entry.completion = completion;
        completion.inline_completion = true;

        entry.changed.connect(entry_changed);
        entry.activate.connect(entry_activated);

        /* Finally, handle ESC */
        key_press_event.connect((w,e) => {
            if (e.keyval == Gdk.Key.Escape) {
                this.destroy();
                return true;
            }
            return false;
        });

        show_all();
    }

    /**
     * Load "menus" (.desktop's) recursively
     * 
     * @param tree_root Initialised GMenu.TreeDirectory, or null
     */
    private void load_menus(GMenu.TreeDirectory? tree_root = null)
    {
        GMenu.TreeDirectory root;
    
        // Load the tree for the first time
        if (tree_root == null) {
            tree = new GMenu.Tree("gnome-applications.menu", GMenu.TreeFlags.SORT_DISPLAY_NAME);

            try {
                tree.load_sync();
            } catch (Error e) {
                stderr.printf("Error: %s\n", e.message);
                return;
            }
            root = tree.get_root_directory();
            mapping = new Gee.HashMap<string,GLib.DesktopAppInfo>();
        } else {
            root = tree_root;
        }

        var it = root.iter();
        GMenu.TreeItemType type;

        while ((type = it.next()) != GMenu.TreeItemType.INVALID) {
            if (type == GMenu.TreeItemType.DIRECTORY) {
                var dir = it.get_directory();
                load_menus(dir);
            } else if (type == GMenu.TreeItemType.ENTRY) {
                // store the entry by its command line (without path)
                var appinfo = it.get_entry().get_app_info();
                var cmd = appinfo.get_executable();
                var splits = cmd.split("/");
                var cmdline = splits[splits.length-1];
                mapping[cmdline] = appinfo;
            }
        }
    }

    /**
     * Handle changes to the text entry, update the icon if we can
     */
    protected void entry_changed()
    {
        if (entry.text.length < 0) {
            return;
        }
        if (mapping.has_key(entry.text)) {
                var appinfo = mapping[entry.text];
                side_image.set_from_gicon(appinfo.get_icon(), Gtk.IconSize.INVALID);
                return;
        } else {
            side_image.set_from_icon_name(default_icon, Gtk.IconSize.INVALID);
        }
    }

    /**
     * Handle activation of the entry
     */
     protected void entry_activated()
     {
            if (entry.text.length == 0) {
                return;
            }
            /* Go ahead and try to launch the command given */
            try {
                if (!Process.spawn_command_line_async(entry.text)) {
                    side_image.set_from_icon_name("dialog-error", Gtk.IconSize.INVALID);
                } else {
                    this.destroy();
                }
            } catch (Error e) {
                    side_image.set_from_icon_name("dialog-error", Gtk.IconSize.INVALID);
            }
    }

} // End RunDialog

class RunDialogMain : GLib.Application
{

    static Budgie.RunDialog dialog;

    public override void activate()
    {
        if (dialog == null) {
            dialog = new Budgie.RunDialog();
            Gtk.main();
        }
        dialog.present();
    }

    private RunDialogMain()
    {
		Object (application_id: "com.evolve_os.BudgieRunDialog", flags: 0);
    }
    /**
     * Main entry
     */

    public static int main(string[] args)
    {
        Budgie.RunDialogMain app;
        Gtk.init(ref args);

        app = new Budgie.RunDialogMain();

        return app.run(args);
    }
} // End RunDialogMain

} // End Budgie namespace

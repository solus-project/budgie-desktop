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

    private static string DEFAULT_ICON = "system-run-symbolic";
    private static string ERROR_ICON   = "dialog-error-symbolic";

    public RunDialog()
    {
        side_image = new Gtk.Image.from_icon_name(DEFAULT_ICON, Gtk.IconSize.INVALID);
        side_image.pixel_size = 64;
        side_image.halign = Gtk.Align.START;
        side_image.valign = Gtk.Align.CENTER;
        side_image.margin_right = 15;
        entry = new Gtk.SearchEntry();
        entry.margin_right = 15;

        // Initialisation stuffs
        window_position = Gtk.WindowPosition.CENTER;
        destroy.connect(() => Gtk.main_quit());
        set_keep_above(true);
        set_skip_taskbar_hint(true);
        set_skip_pager_hint(true);
        title = "Run Program...";
        icon_name = DEFAULT_ICON;


        var main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        /* Window sizing hacks relating to the image size */
        main_layout.pack_start(side_image, false, false, 0);
        main_layout.pack_start(entry, true, true, 0);
        add(main_layout);

        set_size_request(350+(side_image.margin), side_image.pixel_size+side_image.margin);
        border_width = 4;

        get_style_context().add_class("budgie-run-dialog");

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

        var empty = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        empty.draw.connect((c)=> {
            return true;
        });
        set_titlebar(empty);
        empty.get_style_context().add_class("invisi-header");
        empty.get_style_context().remove_class("titlebar");

        show_all();

        get_settings().set_property("gtk-application-prefer-dark-theme", true);
        GLib.Idle.add(init_menus);
    }

    /**
     * Load our menu entries
     */
    private bool init_menus()
    {
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

        return false;
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
            mapping = new Gee.HashMap<string,GLib.DesktopAppInfo>(null,null,null);
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
            side_image.set_from_icon_name(DEFAULT_ICON, Gtk.IconSize.INVALID);
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
            if (mapping.has_key(entry.text)) {
                /* Better to launch via the API */
                var appinfo = mapping[entry.text];
                try {
                    appinfo.launch(null, null);
                    this.destroy();
                } catch (Error e) {
                    side_image.set_from_icon_name(ERROR_ICON, Gtk.IconSize.INVALID);
                }
                return;
            }
            /* Otherwise go ahead and try to launch the command given */
            try {
                if (!Process.spawn_command_line_async(entry.text)) {
                    side_image.set_from_icon_name(ERROR_ICON, Gtk.IconSize.INVALID);
                } else {
                    this.destroy();
                }
            } catch (Error e) {
                    side_image.set_from_icon_name(ERROR_ICON, Gtk.IconSize.INVALID);
            }
    }

} // End RunDialog

class RunDialogMain : GLib.Application
{

    static Budgie.RunDialog dialog;

    public override void activate()
    {
        hold();
        if (dialog == null) {
            dialog = new Budgie.RunDialog();
            Gtk.main();
        }
        dialog.present();
        release();
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

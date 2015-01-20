/*
 * MenubarApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class MenubarApplet: Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new MenubarAppletImpl();
    }
}
const string APPS_ID = "gnome-applications.menu";
const int MENU_ICON_SIZE = 22;

public class MenubarAppletImpl : Budgie.Applet
{

    protected Gtk.MenuBar widget;
    protected Settings settings;
    Gtk.Image img;
    protected HashTable<GMenu.TreeDirectory?,Gtk.Menu?> mapping;
    GMenu.Tree? tree = null;
    Gtk.Menu apps_menu;
    Gtk.Menu places_menu;
    Gtk.Menu system_menu;

    Gtk.ImageMenuItem? apps_menu_item;

    /* This may seem totally redundant right now. Well. it kinda is
     * but in future the option will exist to enable/disable symbolic
     * icons across Budgie.
     */
    protected string corrected_icon(string icon) {
        return icon.split("-symbolic")[0];
    }

    /**
     * Get the icon associated with a special directory
     */
    protected string get_special_icon(UserDirectory d)
    {
        switch (d) {
            case UserDirectory.DESKTOP:
                return corrected_icon("user-desktop-symbolic");
            case UserDirectory.DOCUMENTS:
                return corrected_icon("folder-documents-symbolic");
            case UserDirectory.DOWNLOAD:
                return corrected_icon("folder-download-symbolic");
            case UserDirectory.MUSIC:
                return corrected_icon("folder-music-symbolic");
            case UserDirectory.PICTURES:
                return corrected_icon("folder-pictures-symbolic");
            case UserDirectory.PUBLIC_SHARE:
                return corrected_icon("folder-publicshare-symbolic");
            case UserDirectory.TEMPLATES:
                return corrected_icon("folder-templates-symbolic");
            case UserDirectory.VIDEOS:
                return corrected_icon("folder-videos-symbolic");
            default:
                return corrected_icon("folder-symbolic");
        }
    }

    protected void refresh_tree()
    {
        apps_menu.destroy();
        apps_menu = new Gtk.Menu();

        try {
            tree.load_sync();
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }

        load_menus(null);
        apps_menu.show_all();
        apps_menu_item.set_submenu(apps_menu);
    }

    /**
     * Load "menus" (.desktop's) recursively (ripped from our RunDialog)
     * 
     * @param tree_root Initialised GMenu.TreeDirectory, or null
     */
    private void load_menus(GMenu.TreeDirectory? tree_root = null)
    {
        GMenu.TreeDirectory root;

        // Load the tree for the first time
        if (tree == null) {
            tree = new GMenu.Tree(APPS_ID, GMenu.TreeFlags.SORT_DISPLAY_NAME);

            try {
                tree.load_sync();
            } catch (Error e) {
                stderr.printf("Error: %s\n", e.message);
                return;
            }
            tree.changed.connect(refresh_tree);
        }
        if (tree_root == null) {
            root = tree.get_root_directory();
        } else {
            root = tree_root;
        }

        var it = root.iter();
        GMenu.TreeItemType? type;

        while ((type = it.next()) != GMenu.TreeItemType.INVALID) {
            if (type == GMenu.TreeItemType.DIRECTORY) {
                var dir = it.get_directory();
                var btn = new Gtk.ImageMenuItem.with_label(dir.get_name());
                var img = new Gtk.Image.from_gicon(dir.get_icon(), Gtk.IconSize.INVALID);
                img.pixel_size = MENU_ICON_SIZE;
                btn.set_image(img);
                var menu = new Gtk.Menu();
                btn.set_submenu(menu);
                mapping[dir] = menu;
                apps_menu.add(btn);
                load_menus(dir);
            } else if (type == GMenu.TreeItemType.ENTRY) {
                // store the entry by its command line (without path)
                var appinfo = it.get_entry().get_app_info();
                if (tree_root == null) {
                    warning("%s has no parent directory, not adding to menu\n", appinfo.get_display_name());
                } else {
                    var btn = new Gtk.ImageMenuItem.with_label(appinfo.get_name());
                    var img = new Gtk.Image.from_gicon(appinfo.get_icon(), Gtk.IconSize.INVALID);
                    img.pixel_size = MENU_ICON_SIZE;
                    btn.set_image(img);
                    Gtk.Menu menu = mapping[tree_root];
                    btn.set_data("__ainfo", appinfo);
                    menu.add(btn);

                    btn.activate.connect(() => {
                        var ctx = get_screen().get_display().get_app_launch_context();
                        ctx.set_timestamp(Gdk.CURRENT_TIME);
                        AppInfo ainfo = btn.get_data("__ainfo");
                        try {
                            ainfo.launch(null, ctx);
                        } catch (Error e) {
                            message("Unable to launch: %s\n", ainfo.get_name());
                        }
                    });
                }
            }
        }
    }

    protected Gtk.MenuItem? create_item(string path, string? icon, string? fname = null)
    {
        File f = File.new_for_uri(path);
        string name = path;
        if (fname != null) {
            name = fname;
        } else {
            try {
                var info = f.query_info(FileAttribute.STANDARD_DISPLAY_NAME, FileQueryInfoFlags.NONE, null);
                if (!f.query_exists(null)) {
                    return null;
                }
                name = info.get_display_name();
            } catch (Error e) { }
        }

        Gtk.ImageMenuItem m = new Gtk.ImageMenuItem.with_label(name);
        m.set_data("__uri", path);
        var img = new Gtk.Image.from_icon_name(icon, Gtk.IconSize.INVALID);
        img.pixel_size = MENU_ICON_SIZE;
        m.set_image(img);

        m.activate.connect(() => {
            var ctx = get_screen().get_display().get_app_launch_context();
            ctx.set_timestamp(Gdk.CURRENT_TIME);
            string uri = m.get_data("__uri");
            try {
                AppInfo.launch_default_for_uri(uri, ctx);
            } catch (Error e) {
                message("Unable to launch: %s\n", uri);
            }
        });

        return m;
    }

    protected Gtk.Menu? create_places_menu()
    {
        Gtk.Menu ret = new Gtk.Menu();
        var home = "file://" + Environment.get_home_dir();

        // home icon
        var item = create_item(home, corrected_icon("user-home-symbolic"), "Home Folder");
        if (item != null) {
            item.show_all();
            ret.add(item);
        }

        // special user dirs
        for (int i = 0; i < UserDirectory.N_DIRECTORIES; i++) {
            UserDirectory dir = (UserDirectory)i;
            var path = Environment.get_user_special_dir(dir);
            // Skip when HOME == DESKTOP
            if (path == home && dir == UserDirectory.DESKTOP) {
                continue;
            }
            var icon = get_special_icon(dir);
            var m = create_item("file://" + path, icon);
            if (m == null) {
                continue;
            }
            m.show_all();
            ret.add(m);
        }

        // networking
        var sep = new Gtk.SeparatorMenuItem();
        sep.show_all();
        ret.add(sep);

        item = create_item("network://", corrected_icon("network-workgroup-symbolic"), "Network");
        item.show_all();
        ret.add(item);

        return ret;
    }

    protected Gtk.MenuItem? create_exec_item(string name, string icon)
    {
        Gtk.ImageMenuItem m = new Gtk.ImageMenuItem.with_label(name);
        var img = new Gtk.Image.from_icon_name(icon, Gtk.IconSize.INVALID);
        img.pixel_size = MENU_ICON_SIZE;
        m.set_image(img);

        m.show_all();

        return m;
    }

    protected Gtk.Menu? create_system_menu()
    {
        Gtk.Menu ret = new Gtk.Menu();

        /* We MAY eventually decide on shifting other menus into here, like
         * you once saw in GNOME 2. Let's see if its a demand and actually
         * even worth it first... */

        var item = create_exec_item("About Budgie...", "help-about");
        item.activate.connect(()=> {
            Gtk.License license = Gtk.License.GPL_2_0;
            string[] authors = {
                "Ikey Doherty <ikey@evolve-os.com>",
                "Josh Klar <j@iv597.com>",
                "Emanuel Fernandes <efernandes@tektorque.com>",
                "Elias Aebi <user142@hotmail.com>",
                "yomi0 <abyomi0@gmail.com>",
                "Ricardo Vieira <ricardo.vieira@tecnico.ulisboa.pt>",
                "Matias Linares <matiaslina@gmail.com>"
            };

            string comments = "Simple, yet elegant, desktop environment designed for Evolve OS";
            Gtk.show_about_dialog(null,
                "program-name", "Budgie Desktop",
                "copyright", "Copyright © 2014 Evolve OS",
                "website", Budgie.WEBSITE,
                "license-type", license,
                "authors", authors,
                "version", Budgie.VERSION,
                "comments", comments,
                "logo_icon_name", "help-about",
                "website-label", "Evolve OS");
        });
        ret.add(item);

        var sep = new Gtk.SeparatorMenuItem();
        sep.show_all();
        ret.add(sep);

        item = create_exec_item("End session...", corrected_icon("system-shutdown-symbolic"));
        item.activate.connect(()=> {
            Idle.add(()=> {
                Process.spawn_command_line_async("budgie-session-dialog --logout");
                return false;
            });
        });
        ret.add(item);

        return ret;
    }

    public MenubarAppletImpl()
    {
        settings = new Settings("com.evolve-os.budgie.panel");
        settings.changed.connect(on_settings_changed);

        get_settings().set_property("gtk-menu-images", true);

        widget = new Gtk.MenuBar();
        add(widget);

        apps_menu_item = new Gtk.ImageMenuItem.with_label("Applications");
        img = new Gtk.Image.from_icon_name("start-here-symbolic", Gtk.IconSize.MENU);
        apps_menu_item.set_image(img);

        apps_menu = new Gtk.Menu();
        apps_menu_item.set_submenu(apps_menu);

        widget.add(apps_menu_item);

        var item = new Gtk.MenuItem.with_label("Places");
        places_menu = create_places_menu();
        item.set_submenu(places_menu);
        widget.add(item);

        item = new Gtk.MenuItem.with_label("System");
        system_menu = create_system_menu();
        item.set_submenu(system_menu);
        widget.add(item);

        show_all();
        on_settings_changed("menu-icon");

        mapping = new HashTable<GMenu.TreeDirectory?,Gtk.Menu?>(direct_hash, direct_equal);

        /* Kinda required. We can't become a menubar. */
        widget.get_style_context().add_class("gnome-panel-menu-bar");

        Idle.add(()=> {
            load_menus(null);
            apps_menu.show_all();
            return false;
        });
    }

    protected void on_settings_changed(string key)
    {
        if (key != "menu-icon") {
            return;
        }
        img.set_from_icon_name(settings.get_string(key), Gtk.IconSize.INVALID);
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(MenubarApplet));
}

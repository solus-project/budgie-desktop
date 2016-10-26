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

const string APPS_ID = "gnome-applications.menu";
const string LOGOUT_BINARY = "budgie-session-dialog";

/**
 * Factory widget to represent a category
 */
public class CategoryButton : Gtk.RadioButton
{

    public new GMenu.TreeDirectory? group { public get ; protected set; }

    public CategoryButton(GMenu.TreeDirectory? parent)
    {
        Gtk.Label lab;

        if (parent != null) {
            lab = new Gtk.Label(parent.get_name());
        } else {
            // Special case, "All"
            lab = new Gtk.Label(_("All"));
        }
        lab.halign = Gtk.Align.START;
        lab.valign = Gtk.Align.CENTER;
        lab.margin_start = 10;
        lab.margin_end = 15;

        var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.pack_start(lab, true, true, 0);
        add(layout);

        get_style_context().add_class("flat");
        get_style_context().add_class("category-button");
        // Makes us look like a normal button :)
        set_property("draw-indicator", false);
        set_can_focus(false);
        group = parent;
    }
}

/**
 * Factory widget to represent a menu item
 */
public class MenuButton : Gtk.Button
{

    public DesktopAppInfo info { public get ; protected set ; }
    public GMenu.TreeDirectory parent_menu { public get ; protected set ; }

    public int score { public set ; public get; }

    public MenuButton(DesktopAppInfo parent, GMenu.TreeDirectory directory, int icon_size)
    {
        var img = new Gtk.Image.from_gicon(parent.get_icon(), Gtk.IconSize.INVALID);
        img.pixel_size = icon_size;
        img.margin_end = 7;
        var lab = new Gtk.Label(parent.get_display_name());
        lab.halign = Gtk.Align.START;
        lab.valign = Gtk.Align.CENTER;

        var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.pack_start(img, false, false, 0);
        layout.pack_start(lab, true, true, 0);
        add(layout);

        this.info = parent;
        this.parent_menu = directory;
        set_tooltip_text(parent.get_description());

        score = 0;

        get_style_context().add_class("flat");
    }
}

public class BudgieMenuWindow : Gtk.Popover
{
    protected Gtk.SearchEntry search_entry;
    protected Gtk.Box categories;
    protected Gtk.ListBox content;
    private GMenu.Tree tree;
    protected Gtk.ScrolledWindow categories_scroll;
    protected Gtk.ScrolledWindow content_scroll;
    protected CategoryButton all_categories;

    // The current group 
    protected GMenu.TreeDirectory? group = null;
    protected bool compact_mode;

    /* Whether we allow rollover category switch */
    protected bool rollover_menus = true;

    // Current search term
    protected string search_term = "";

    protected int icon_size = 24;

    public unowned Settings settings { public get; public set; }

    private bool reloading = false;

    /* Reload menus, essentially. */
    public void refresh_tree()
    {
        lock (reloading) {
            if (reloading) {
                return;
            }
            reloading = true;
        }
        foreach (var child in content.get_children()) {
            child.destroy();
        }
        foreach (var child in categories.get_children()) {
            if (child != all_categories) {
                SignalHandler.disconnect_by_func(child, (void*)on_mouse_enter, this);
                child.destroy();
            }
        }
        SignalHandler.disconnect_by_func(tree, (void*)refresh_tree, this);
        this.tree = null;
        Idle.add(()=> { 
            load_menus(null);
            apply_scores();
            return false;
        });
        lock (reloading) {
            reloading = false;
        }
    }

    /**
     * Permits "rolling" over categories
     */
    private bool on_mouse_enter(Gtk.Widget source_widget, Gdk.EventCrossing e)
    {
        if (!this.rollover_menus) {
            return Gdk.EVENT_PROPAGATE;
        }
        /* If it's not valid, don't use it. */
        Gtk.ToggleButton? b = source_widget as Gtk.ToggleButton;
        if (!b.get_sensitive() || !b.get_visible()) {
            return Gdk.EVENT_PROPAGATE;
        }

        /* Activate the source_widget category */
        (source_widget as Gtk.ToggleButton).set_active(true);
        return Gdk.EVENT_PROPAGATE;
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
                lock (reloading) {
                    reloading = false;
                }
                return;
            }
            /* Think of deferred routines.. */
            Idle.add(()=> {
                tree.changed.connect(refresh_tree);
                return false;
            });
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
                var btn = new CategoryButton(dir);
                btn.join_group(all_categories);
                btn.enter_notify_event.connect(this.on_mouse_enter);
                categories.pack_start(btn, false, false, 0);

                // Ensures we find the correct button
                btn.toggled.connect(()=>{
                    update_category(btn);
                });

                load_menus(dir);
            } else if (type == GMenu.TreeItemType.ENTRY) {
                // store the entry by its command line (without path)
                var appinfo = it.get_entry().get_app_info();
                if (tree_root == null) {
                    warning("%s has no parent directory, not adding to menu\n", appinfo.get_display_name());
                } else {
                    var btn = new MenuButton(appinfo, tree_root, icon_size);
                    btn.clicked.connect(()=> {
                        hide();
                        btn.score++;
                        launch_app(btn.info);
                        content.invalidate_sort();
                        content.invalidate_headers();
                        save_scores();
                    });
                    content.add(btn);
                }
            }
        }
    }

    protected void unwrap_score(Variant v, out string s, out int i)
    {
        Variant t = v.get_child_value(0);
        s = t.get_string();
        t = v.get_child_value(1);
        i = t.get_int32();
    }

    /* Apply "scores" to enable usage-sorting */
    protected void apply_scores()
    {
        var scores = settings.get_value("app-scores");

        HashTable<string,int> m = new HashTable<string,int>(str_hash, str_equal);

        /* Prevent large loops by caching score items */
        for (int i = 0; i < scores.n_children(); i++) {
            var tupe = scores.get_child_value(i);
            string dname; int score;
            unwrap_score(tupe, out dname, out score);

            m.insert(dname, score);
        }

        foreach (var sprog in content.get_children()) {
            MenuButton child = (sprog as Gtk.Bin).get_child() as MenuButton;
            var key = child.info.get_filename();
            if (m.contains(key)) {
                child.score = m.get(key);
            }
        }

        content.invalidate_sort();
    }

    protected Variant mktuple(string text, int val)
    {
        Variant l = new Variant.string(text);
        Variant r = new Variant.int32(val);
        Variant t = new Variant.tuple(new Variant[] { l, r});

        return t;
    }

    /* Save "scores" (usage-sorting */
    protected void save_scores()
    {

        Variant[] children = null;

        foreach (var sprog in content.get_children()) {
            MenuButton child = (sprog as Gtk.Bin).get_child() as MenuButton;
            if (child.score == 0) {
                continue;
            }
            var key = child.info.get_filename();
            var tuple = mktuple(key, child.score);
            if (children == null) {
                children = new Variant[] { tuple };
            } else {
                children += tuple;
            }
        }

        if (children == null) {
            return;
        }
        var arr = new Variant.array(null, children);
        settings.set_value("app-scores", arr);

    }

    public BudgieMenuWindow(Settings? settings, Gtk.Widget? leparent)
    {
        Object(settings: settings, relative_to: leparent);
        get_style_context().add_class("budgie-menu");
        var master_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(master_layout);

        icon_size = settings.get_int("menu-icons-size");

        // search entry up north
        search_entry = new Gtk.SearchEntry();
        master_layout.pack_start(search_entry, false, false, 0);

        // middle holds the categories and applications
        var middle = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        master_layout.pack_start(middle, true, true, 0);

        // clickable categories
        categories = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        categories.margin_top = 3;
        categories.margin_bottom = 3;
        categories_scroll = new Gtk.ScrolledWindow(null, null);
        categories_scroll.set_overlay_scrolling(false);
        categories_scroll.set_shadow_type(Gtk.ShadowType.ETCHED_IN);
        categories_scroll.get_style_context().add_class("categories");
        categories_scroll.get_style_context().add_class("sidebar");
        categories_scroll.add(categories);
        categories_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER);
        middle.pack_start(categories_scroll, false, false, 0);

        // "All" button"
        all_categories = new CategoryButton(null);
        all_categories.enter_notify_event.connect(this.on_mouse_enter);
        all_categories.toggled.connect(()=> {
            update_category(all_categories);
        });
        categories.pack_start(all_categories, false, false, 0);

        var right_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        middle.pack_start(right_layout, true, true, 0);

        // holds all the applications
        content = new Gtk.ListBox();
        content.row_activated.connect(on_row_activate);
        content.set_selection_mode(Gtk.SelectionMode.NONE);
        content_scroll = new Gtk.ScrolledWindow(null, null);
        content_scroll.set_overlay_scrolling(false);
        content_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        content_scroll.add(content);
        right_layout.pack_start(content_scroll, true, true, 0);

        // placeholder in case of no results
        var placeholder = new Gtk.Label("<big>Sorry, no items found</big>");
        placeholder.use_markup = true;
        placeholder.get_style_context().add_class("dim-label");
        placeholder.show();
        placeholder.margin = 6;
        content.valign = Gtk.Align.START;
        content.set_placeholder(placeholder);

        settings.changed.connect(on_settings_changed);
        on_settings_changed("menu-compact");
        on_settings_changed("menu-headers");
        on_settings_changed("menu-categories-hover");

        // management of our listbox
        content.set_filter_func(do_filter_list);
        content.set_sort_func(do_sort_list);

        // searching functionality :)
        search_entry.changed.connect(()=> {
            search_term = search_entry.text.down();
            content.invalidate_headers();
            content.invalidate_filter();
        });

        //search_entry.set_can_default(true);
        //search_entry.grab_default();
        //this.set_default(search_entry);
        search_entry.grab_focus();
        //this.set_focus_on_map(true);

        // Enabling activation by search entry
        search_entry.activate.connect(on_entry_activate);
        // sensible vertical height
        set_size_request(300, 510);
        // load them in the background
        Idle.add(()=> {
            load_menus(null);
            apply_scores();
            queue_resize();
            if (!get_realized()) {
                realize();
            }
            return false;
        });
    }

    protected void on_settings_changed(string key)
    {
        switch (key) {
            case "menu-compact":
                var vis = settings.get_boolean(key);
                categories_scroll.no_show_all = vis;
                categories_scroll.set_visible(vis);
                compact_mode = vis;
                break;
            case "menu-headers":
                if (settings.get_boolean(key)) {
                    content.set_header_func(do_list_header);
                } else {
                    content.set_header_func(null);
                }
                content.invalidate_headers();
                break;
            case "menu-categories-hover":
                /* Category hover */
                this.rollover_menus = settings.get_boolean(key);
                break;
            default:
                // not interested
                break;
        }
    }


    protected void on_entry_activate()
    {
        Gtk.ListBoxRow? selected = null;

        var rows = content.get_selected_rows();
        if (rows != null) {
            selected = rows.data;
        } else {
            foreach (var child in content.get_children()) {
                if (child.get_visible() && child.get_child_visible()) {
                    selected = child as Gtk.ListBoxRow;
                    break;
                }
            }
        }
        if (selected == null) {
            return;
        }

        MenuButton btn = selected.get_child() as MenuButton;
        btn.score++;
        launch_app(btn.info);
        content.invalidate_sort();
        content.invalidate_headers();
        save_scores();
    }

    protected void on_row_activate(Gtk.ListBoxRow? row)
    {
        if (row == null) {
            return;
        }
        /* Launch this item, i.e. keyboard access. */
        MenuButton btn = row.get_child() as MenuButton;
        btn.score++;
        launch_app(btn.info);
        content.invalidate_sort();
        content.invalidate_headers();
        save_scores();
    }

    /**
     * Provide category headers in the "All" category
     */
    protected void do_list_header(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after)
    {
        MenuButton? child = null;
        string? prev = null;
        string? next = null;

        // In a category listing, kill headers
        if (group != null) {
            if (before != null) {
                before.set_header(null);
            }
            if (after != null) {
                after.set_header(null);
            }
            return;
        }

        // Just retrieve the category names
        if (before != null) {
            child = before.get_child() as MenuButton;
            prev = child.parent_menu.get_name();
        }

        if (after != null) {
            child = after.get_child() as MenuButton;
            next = child.parent_menu.get_name();
        }
        
        // Only add one if we need one!
        if (before == null || after == null || prev != next) {
            var label = new Gtk.Label(Markup.printf_escaped("<big>%s</big>", prev));
            label.get_style_context().add_class("dim-label");
            label.halign = Gtk.Align.START;
            label.use_markup = true;
            before.set_header(label);
            label.margin = 6;
        } else {
            before.set_header(null);
        }
    }

    /**
     * Filter out results in the list according to whatever the current filter is,
     * i.e. group based or search based
     */
    protected bool do_filter_list(Gtk.ListBoxRow row)
    {
        MenuButton child = row.get_child() as MenuButton;

        if (search_term.length > 0) {
            string? app_name, desc, name, exec;

            // "disable" categories while searching
            categories.sensitive = false;

            // Ugly and messy but we need to ensure we're not dealing with NULL strings
            app_name = child.info.get_display_name();
            if (app_name != null) {
                app_name = app_name.down();
            } else {
                app_name = "";
            }
            desc = child.info.get_description();
            if (desc != null) {
                desc = desc.down();
            } else {
                desc = "";
            }
            name = child.info.get_name();
            if (name != null) {
                name = name.down();
            } else {
                name = "";
            };
            exec = child.info.get_executable();
            if (exec != null) {
                exec = exec.down();
            } else {
                exec = "";
            }
            return (search_term in app_name || search_term in desc ||
                    search_term in name || search_term in exec);
        }

        // "enable" categories if not searching
        categories.sensitive = true;

        // No more filtering, show all
        if (group == null) {
            return true;
        }
        // If the GMenu.TreeDirectory isn't the same as the current filter, hide it
        if (child.parent_menu != group) {
            return false;
        }
        return true;
    }

    protected int do_sort_list(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2)
    {
        MenuButton child1 = row1.get_child() as MenuButton;
        MenuButton child2 = row2.get_child() as MenuButton;

        int run = 0;
        if (child1.score > child2.score) {
            run = -1;
        } else if (child2.score > child1.score) {
            run = 1;
        }

        return run;
    }


    /**
     * Change the current group/category
     */
    protected void update_category(CategoryButton btn)
    {
        if (btn.active) {
            group = btn.group;
            content.invalidate_filter();
            content.invalidate_headers();
        }
    }

    /**
     * Launch an application
     */
    protected void launch_app(DesktopAppInfo info)
    {
        hide();
        // Do it on the idle thread to make sure we don't have focus wars
        Idle.add(()=> {
            try {
                info.launch(null,null);
            } catch (Error e) {
                stdout.printf("Error launching application: %s\n", e.message);
            }
            return false;
        });
    }

    /**
     * We need to make some changes to our display before we go showing ourselves
     * again! :)
     */
    public override void show()
    {
        search_term = "";
        search_entry.text = "";
        group = null;
        all_categories.set_active(true);
        content.select_row(null);
        content_scroll.get_vadjustment().set_value(0);
        categories_scroll.get_vadjustment().set_value(0);
        categories.sensitive = true;
        Idle.add(()=> {
            /* grab focus when we're not busy, ensuring it works.. */
            search_entry.grab_focus();
            return false;
        });
        base.show();
        if (!compact_mode) {
            categories_scroll.show_all();
        } else {
            categories_scroll.hide();
        }
    }

}// End BudgieMenuWindow class

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

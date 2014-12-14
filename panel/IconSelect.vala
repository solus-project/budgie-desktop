/*
 * IconSelect.vala
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

/**
 * Allows selection of an Icon
 */
public class IconSelect : GLib.Object
{

    private static Gtk.ListStore icon_list;
    private Gtk.TreeModelFilter icon_list_filtered;
    private Gtk.IconView icon_view;
    private Gtk.Button ok_button;
    private Gtk.Button cancel_button;
    private Gtk.FileChooserWidget file_chooser;
    private Gtk.Notebook tabs;
    private Gtk.Window window;
    private Gtk.HeaderBar header;
    private Gtk.ScrolledWindow scroll;
    private Gtk.ComboBoxText context_combo;

    private string active_icon = "";
    private static bool loading = false;
    private static bool need_reload = true;
    private const string disabled_contexts = "Animations, FileSystems";

    public signal void on_ok(string icon_name);

    private class ListEntry {
        public string name;
        public IconContext context;
        public Gdk.Pixbuf pixbuf;
    }

    private GLib.AsyncQueue<ListEntry?> load_queue;

    private enum IconContext {
        ALL,
        APPS,
        ACTIONS,
        PLACES,
        FILES,
        EMOTES,
        OTHER,
        IMAGE
    }

    public IconSelect(Gtk.Window parent)
    {
        try {
            this.load_queue = new GLib.AsyncQueue<ListEntry?>();

            if (icon_list == null) {
                icon_list = new Gtk.ListStore(3, typeof(string),      // name
                                                 typeof(IconContext), // type
                                                 typeof(Gdk.Pixbuf)); // image

                /**
                 * disable sorting until all icons are loaded
                 * else loading becomes horribly slow
                 */
                icon_list.set_default_sort_func(() => {return 0;});

                Gtk.IconTheme.get_default().changed.connect(() => {
                    if (this.window.visible) load_icons();
                    else IconSelect.need_reload = true;
                });
            }

        this.icon_list_filtered = new Gtk.TreeModelFilter(icon_list, null);

        this.window = new Gtk.Window();
        this.window.set_size_request(625, 525);
        this.window.set_border_width(10);
        this.window.set_type_hint(Gdk.WindowTypeHint.DIALOG);
        this.window.set_destroy_with_parent(true);
        this.window.set_transient_for(parent);
        this.window.set_modal(true);
        this.window.set_resizable(false);

        this.header = new Gtk.HeaderBar();
        this.header.set_show_close_button(true);
        this.window.set_titlebar(header);
        this.header.set_title("Select an icon:");

        this.tabs = new Gtk.Notebook();

        this.ok_button = new Gtk.Button.with_label("Ok");
        this.ok_button.clicked.connect(on_ok_button_clicked);

        this.cancel_button = new Gtk.Button.with_label("Cancel");
        this.cancel_button.clicked.connect(on_cancel_button_clicked);

        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        this.window.add(box);

        this.context_combo = new Gtk.ComboBoxText();
        this.scroll = new Gtk.ScrolledWindow(null, null);

        this.context_combo.append_text("All icons");
        this.context_combo.append_text("Applications");
        this.context_combo.append_text("Actions");
        this.context_combo.append_text("Places");
        this.context_combo.append_text("File types");
        this.context_combo.append_text("Emotes");
        this.context_combo.append_text("Miscellaneous");
        this.context_combo.append_text("Image file [..]");

        this.context_combo.set_active(0);

        this.context_combo.changed.connect(() => {
            this.icon_list_filtered.refilter();
            this.check_visible_widgets();
        });

        box.pack_start(this.context_combo, false, false);

        Gtk.Entry filter = new Gtk.Entry();

        this.icon_list_filtered.set_visible_func((model, iter) => {
            string name = "";
            IconContext context = IconContext.ALL;
            model.get(iter, 0, out name);
            model.get(iter, 1, out context);

            if (name == null) return false;

            return (this.context_combo.get_active() == context ||
                    this.context_combo.get_active() == IconContext.ALL) &&
                    name.down().contains(filter.text.down());
        });

        // clear
        filter.icon_release.connect((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY)
                filter.text = "";
        });

        // refilter on input
        filter.notify["text"].connect(() => {
            this.icon_list_filtered.refilter();
        });

        box.pack_start(this.scroll, true, true);

        this.icon_view = new Gtk.IconView.with_model(this.icon_list_filtered);
        this.icon_view.item_width = 32;
        this.icon_view.item_padding = 2;
        this.icon_view.pixbuf_column = 2;
        this.icon_view.tooltip_column = 0;

        // set active_icon if selection changes
        this.icon_view.selection_changed.connect(() => {
            foreach (var path in this.icon_view.get_selected_items()) {
                Gtk.TreeIter iter;
                this.icon_list_filtered.get_iter(out iter, path);
                this.icon_list_filtered.get(iter, 0, out this.active_icon);
            }
        });

        // hide this window when the user activates an icon
        this.icon_view.item_activated.connect((path) => {
            Gtk.TreeIter iter;
            this.icon_list_filtered.get_iter(out iter, path);
            this.icon_list_filtered.get(iter, 0, out this.active_icon);
            this.on_ok(this.active_icon);
            this.window.hide();
        });

        this.scroll.add(this.icon_view);

        // file chooser widget
        this.file_chooser = new Gtk.FileChooserWidget(Gtk.FileChooserAction.OPEN);
        this.file_chooser.set_border_width(6);
        box.pack_start(this.file_chooser, true, true);

        Gtk.FileFilter file_filter = new Gtk.FileFilter();
        file_filter.add_pixbuf_formats();
        file_filter.set_filter_name("All supported image formats");
        file_chooser.add_filter(file_filter);

        // set active_icon if the user selected a file
        file_chooser.selection_changed.connect(() => {
            if (file_chooser.get_filename() != null &&
                GLib.FileUtils.test(file_chooser.get_filename(),
                                    GLib.FileTest.IS_REGULAR))

                this.active_icon = file_chooser.get_filename();
        });

        // hide this window when the user activates a file
        file_chooser.file_activated.connect(() => {
            this.active_icon = file_chooser.get_filename();
            this.on_ok(this.active_icon);
            this.window.hide();
        });

        this.window.set_focus(this.icon_view);
        this.window.delete_event.connect(this.window.hide_on_delete);

        Gtk.Box button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        ok_button.set_size_request(70,30);
        cancel_button.set_size_request(70,30);
        button_box.pack_end(ok_button, false, false);
        button_box.pack_end(cancel_button, false, false);
        box.pack_start(button_box, false, true);

        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }

    private void check_visible_widgets()
    {
        if (this.context_combo.get_active() == IconContext.IMAGE) {
            this.scroll.hide();
            this.file_chooser.show();
        } else {
            this.scroll.show();
            this.file_chooser.hide();
        }
    }

    public void show()
    {
        this.window.show_all();
        this.check_visible_widgets();

        if (IconSelect.need_reload) {
            IconSelect.need_reload = false;
            this.load_icons();
        }
    }

    public static void clear_icons()
    {
        if (icon_list != null) {
            IconSelect.need_reload = true;
            icon_list.clear();
        }
    }

    private void on_ok_button_clicked()
    {
        this.on_ok(this.active_icon);
        this.window.hide();
    }

    private void on_cancel_button_clicked()
    {
        this.window.hide();
    }

    private void load_icons()
    {
        if (!loading)
        {
            loading = true;
            icon_list.clear();

            // See line 67
            icon_list.set_sort_column_id(-1, Gtk.SortType.ASCENDING);

            this.load_all.begin();

            Timeout.add(200, () => {
                while (this.load_queue.length() > 0) {
                    var new_entry = this.load_queue.pop();
                    Gtk.TreeIter current;
                    icon_list.append(out current);
                    icon_list.set(current, 0, new_entry.name,
                                                1, new_entry.context,
                                                2, new_entry.pixbuf);
                }

                // enable sorting of the icon_view if loading finished
                if (!loading)
                {
                    icon_list.set_sort_column_id(0, Gtk.SortType.ASCENDING);
                }

                return loading;
            });
        }
    }


    private async void load_all()
    {
        var icon_theme = Gtk.IconTheme.get_default();

        foreach (var context in icon_theme.list_contexts())
        {
            if (!disabled_contexts.contains(context)) {
                foreach (var icon in icon_theme.list_icons(context)) {

                    IconContext icon_context = IconContext.OTHER;
                    switch(context) {
                        case "Apps": case "Applications":
                            icon_context = IconContext.APPS; break;
                        case "Emotes":
                            icon_context = IconContext.EMOTES; break;
                        case "Places": case "Devices":
                            icon_context = IconContext.PLACES; break;
                        case "Mimetypes":
                            icon_context = IconContext.FILES; break;
                        case "Actions":
                            icon_context = IconContext.ACTIONS; break;
                        default: break;
                    }

                    Idle.add(load_all.callback);
                    yield;

                    try {
                        var new_entry = new ListEntry();
                        new_entry.name = icon;
                        new_entry.context = icon_context;
                        new_entry.pixbuf = icon_theme.load_icon(icon, 32, 0);

                        /**
                         * check if icon size is correct
                         */
                        if (new_entry.pixbuf.width == 32)
                            this.load_queue.push(new_entry);

                    } catch (GLib.Error e) {
                        warning("Failed to load image " + icon);
                    }
                }
            }
        }
        loading = false;
    }
}

}

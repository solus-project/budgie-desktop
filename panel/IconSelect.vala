/*
 * IconSelect.vala
 *
 * Copyright 2014 Lara Maia <lara@craft.net.br>
 * Copyright (c) 2011 by Simon Schneegans:
 *
 * Icon select window code used with kind permission of Simon Schneegans:
 * https://github.com/evolve-os/budgie-desktop/pull/134#issuecomment-70007104
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public class IconSelect : Gtk.Window
{
    // our editor reference
    unowned Budgie.PanelEditor panel_editor;

    Gtk.ListStore icon_model;
    Gtk.ComboBoxText category_select_box;
    Gtk.FileChooserWidget file_chooser;
    Gtk.ScrolledWindow scroll;

    public IconSelect(Budgie.PanelEditor parent_panel_editor)
    {
        this.panel_editor = parent_panel_editor;

        /**
         * Window
         */

        window_position = Gtk.WindowPosition.CENTER;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        transient_for = panel_editor;
        title = "Select an Icon:";
        destroy_with_parent = true;
        default_height = 500;
        default_width = 670;

        Gtk.HeaderBar header = new Gtk.HeaderBar();
        header.set_show_close_button(true);
        header.set_title(title);
        set_titlebar(header);

        Gtk.Box main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        this.add(main_box);

        /**
         * Widgets
         */

        // Icon categories select (combobox)
        category_select_box = new Gtk.ComboBoxText();
        category_select_box.append_text("All Icons");
        category_select_box.append_text("Image file [..]");
        category_select_box.append_text("Actions");
        category_select_box.append_text("Applications");
        category_select_box.append_text("Categories");
        category_select_box.append_text("Devices");
        category_select_box.append_text("Emblems");
        category_select_box.append_text("Emotes");
        category_select_box.append_text("MimeTypes");
        category_select_box.append_text("Places");
        category_select_box.append_text("Status");
        category_select_box.set_active(0);
        main_box.pack_start(category_select_box, false, false);

        // Icon model
        icon_model = new Gtk.ListStore(3, typeof(string),
                                          typeof(string),
                                          typeof(Gdk.Pixbuf));

        // Icon view
        scroll = new Gtk.ScrolledWindow(null, null);
        Gtk.IconView icon_view = new Gtk.IconView.with_model(icon_model);
        icon_view.set_selection_mode(Gtk.SelectionMode.SINGLE);
        icon_view.item_width = 32;
        icon_view.item_padding = 2;
        icon_view.pixbuf_column = 2;
        scroll.add(icon_view);
        main_box.pack_start(scroll);

        // File chooser
        file_chooser = new Gtk.FileChooserWidget(Gtk.FileChooserAction.OPEN);
        Gtk.FileFilter image_filter = new Gtk.FileFilter();
        image_filter.add_pixbuf_formats();
        image_filter.set_filter_name("All supported image formats");
        file_chooser.add_filter(image_filter);
        file_chooser.select_multiple = false;
        main_box.pack_start(file_chooser);

        // buttons (Ok, Cancel)
        Gtk.Box button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        Gtk.Button button_ok = new Gtk.Button.with_label("Ok");
        Gtk.Button button_cancel = new Gtk.Button.with_label("Cancel");
        button_ok.set_size_request(70, 30);
        button_cancel.set_size_request(70, 30);
        button_box.pack_end(button_ok, false, false);
        button_box.pack_end(button_cancel, false, false);
        main_box.pack_start(button_box, false, true);

        /**
         * Callbacks
         */

        // Load icons based on the category selected
        category_select_box.changed.connect(on_category_select_box_changed);

        // Set icon
        button_ok.clicked.connect(() => {
            if(category_select_box.get_active() == 1) {
                panel_editor.menu_icon_entry.set_text(file_chooser.get_filename());
            } else {
                Gtk.TreePath item = icon_view.get_selected_items().data;
                Gtk.TreeIter iter;
                Value name;

                icon_model.get_iter(out iter, item);
                icon_model.get_value(iter, 0, out name);
                panel_editor.menu_icon_entry.set_text((string)name);
            }

            this.hide();
        });

        button_cancel.clicked.connect(() => this.hide());

        this.delete_event.connect(this.hide_on_delete);
    }


    /**
     * Load Requested Icons
     */
    public async void load_icons()
    {
        Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
        Gtk.TreeIter iter;
        Gdk.Pixbuf icon;
        string category;

        // Clear old list
        icon_model.clear();

        // if user request all icons, unset category
        if (category_select_box.get_active() == 0)
            category = null;
        else
            category = category_select_box.get_active_text();

        foreach (var icon_name in icon_theme.list_icons(category))
        {
            // Prevent duplicate load when user change category before previous call end
            if(category == null && category_select_box.get_active() != 0) break;
            if(category != null && category_select_box.get_active_text() != category) break;

            GLib.Idle.add(load_icons.callback);
            yield;

            try {
                icon_model.append(out iter);
                icon = icon_theme.load_icon(icon_name, 32, 0);
                if (icon.width == 32)
                    icon_model.set(iter,
                                   0, icon_name,
                                   1, category,
                                   2, icon);
            } catch (Error e) {
                warning(e.message);
            }
        }

    }

    public void on_category_select_box_changed()
    {
        if (category_select_box.get_active_text() == "Image file [..]") {
            scroll.hide();
            file_chooser.show();
        } else {
            file_chooser.hide();
            scroll.show();
            load_icons.begin();
        }
    }

}

}

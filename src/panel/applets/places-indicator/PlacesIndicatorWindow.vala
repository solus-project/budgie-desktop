/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2015-2016 Solus Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class PlacesIndicatorWindow : Gtk.Popover {
    private GLib.VolumeMonitor volume_monitor;

    private MessageRevealer message_bar;
    private PlacesSection places_section;

    private Gtk.ListBox mounts_listbox;
    private Gtk.ListBox networks_listbox;
    private Gtk.Box placeholder;

    private GLib.GenericSet<string> places_list;

    private bool _show_places = false;
    private bool _show_drives = false;
    private bool _show_networks = false;

    private bool only_places = true;

    private GLib.FileMonitor bookmarks_monitor;

    public bool show_places {
        get { return _show_places; }
        set {
            _show_places = value;
            toggle_section_visibility("places");
        }
    }

    public bool show_drives {
        get { return _show_drives; }
        set {
            _show_drives = value;
            toggle_section_visibility("drives");
        }
    }

    public bool show_networks {
        get { return _show_networks; }
        set {
            _show_networks = value;
            toggle_section_visibility("networks");
        }
    }

    private GLib.UserDirectory[] DEFAULT_DIRECTORIES = {
        GLib.UserDirectory.DOCUMENTS,
        GLib.UserDirectory.DOWNLOAD,
        GLib.UserDirectory.MUSIC,
        GLib.UserDirectory.PICTURES,
        GLib.UserDirectory.VIDEOS
    };

    public PlacesIndicatorWindow(Gtk.Widget? window_parent) {
        Object(relative_to: window_parent);
        set_size_request(280, 0);
        get_style_context().add_class("places-menu");

        places_list = new GLib.GenericSet<string>(str_hash, str_equal);

        Gtk.Box main_content = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(main_content);

        message_bar = new MessageRevealer();
        message_bar.set_no_show_all(true);
        main_content.pack_start(message_bar, false, true, 0);

        places_section = new PlacesSection();
        main_content.pack_start(places_section, false, true, 0);

        mounts_listbox = new Gtk.ListBox();
        mounts_listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        mounts_listbox.set_header_func(list_header_func);
        main_content.pack_start(mounts_listbox, true, true, 0);

        networks_listbox = new Gtk.ListBox();
        networks_listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        networks_listbox.set_header_func(list_header_func);
        main_content.pack_start(networks_listbox, true, true, 0);

        placeholder = set_up_placeholder();
        main_content.pack_start(placeholder, true, true, 0);
        placeholder.hide();

        volume_monitor = GLib.VolumeMonitor.get();

        connect_signals();

        refresh_special_dirs();
        refresh_mounts();

        this.closed.connect(on_popover_closed);

        main_content.show_all();
    }

    private void on_popover_closed()
    {
        foreach (Gtk.Widget item in mounts_listbox.get_children()) {
            ListItem list_item = (ListItem) (item as Gtk.ListBoxRow).get_child();
            list_item.cancel_operation();
        }

        foreach (Gtk.Widget item in networks_listbox.get_children()) {
            ListItem list_item = (ListItem) (item as Gtk.ListBoxRow).get_child();
            list_item.cancel_operation();
        }

        places_section.reveal(false);
        message_bar.hide_it();
    }

    /**
     * Provide section headers in the mounts list
     * Ripped out of budgie-menu
     */
    private void list_header_func(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after)
    {
        ListItem? child = null;
        string? prev = null;
        string? next = null;

        if (before != null) {
            child = before.get_child() as ListItem;
            prev = child.get_item_category();
        }

        if (after != null) {
            child = after.get_child() as ListItem;
            next = child.get_item_category();
        }

        if (before == null || after == null || prev != next) {
            Gtk.Label label = new Gtk.Label(GLib.Markup.printf_escaped("<span font=\"11\">%s</span>", prev));
            label.get_style_context().add_class("dim-label");
            label.set_halign(Gtk.Align.START);
            label.set_use_markup(true);
            before.set_header(label);
            label.margin = 3;
        } else {
            before.set_header(null);
        }
    }

    /*
     * Construct the listbox placeholder
     */
    private Gtk.Box set_up_placeholder()
    {
        Gtk.Box placeholder_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
        placeholder_box.margin = 20;
        placeholder_box.set_halign(Gtk.Align.CENTER);
        placeholder_box.set_valign(Gtk.Align.CENTER);

        Gtk.Image placeholder_image = new Gtk.Image.from_icon_name(
            "drive-harddisk-symbolic", Gtk.IconSize.DIALOG);
        placeholder_image.pixel_size = 64;
        placeholder_box.pack_start(placeholder_image, false, false, 6);

        Gtk.Label placeholder_label = new Gtk.Label(
            "<span font=\"11\">%s</span>".printf(_("Nothing to display right now")));
        placeholder_label.use_markup = true;
        placeholder_box.pack_start(placeholder_label, false, false, 0);
        Gtk.Label placeholder_label1 = new Gtk.Label(
            "<span font=\"10\">%s\n%s</span>".printf(_("Mount some drives"), _("Enable more sections")));
        placeholder_label1.use_markup = true;
        placeholder_label1.set_justify(Gtk.Justification.LEFT);
        placeholder_label1.get_style_context().add_class("dim-label");
        placeholder_box.pack_start(placeholder_label1, false, false, 0);

        placeholder_box.show_all();

        return placeholder_box;
    }

    /*
     * Returns a GLib.File for the bookmarks file location
     */
    private GLib.File get_bookmarks_file()
    {
        string path = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), "gtk-3.0", "bookmarks");
        return GLib.File.new_for_path(path);
    }

    /*
     * Sets up a file monitor for the bookmarks file and listens for changes
     */
    private void connect_bookmarks_monitor()
    {
        GLib.File bookmarks_file = get_bookmarks_file();
        if (!bookmarks_file.query_exists()) {
            return;
        }

        try {
            bookmarks_monitor = bookmarks_file.monitor_file(GLib.FileMonitorFlags.NONE, null);
            bookmarks_monitor.set_rate_limit(1000);

            // Refresh special directories (including the bookmarks) when the file changes
            bookmarks_monitor.changed.connect(on_bookmarks_change);
        } catch (GLib.IOError e) {
            warning(e.message);
        }
    }

    private void on_bookmarks_change(GLib.File src, GLib.File? dest, GLib.FileMonitorEvent event)
    {
        if (event == GLib.FileMonitorEvent.CHANGES_DONE_HINT) {
            refresh_special_dirs();
        }
    }

    /*
     * Connect all the signals
     */
    private void connect_signals()
    {
        connect_bookmarks_monitor();
        volume_monitor.volume_added.connect(refresh_mounts);
        volume_monitor.volume_removed.connect(refresh_mounts);
        volume_monitor.drive_connected.connect(refresh_mounts);
        volume_monitor.drive_disconnected.connect(refresh_mounts);
        volume_monitor.mount_added.connect(refresh_mounts);
        volume_monitor.mount_removed.connect(refresh_mounts);
    }

    /*
     * Figures out if we should expand the places section
     * (Expand if it's the only enabled (populated) section)
     */
    private void check_expand()
    {
        if (mounts_listbox.get_visible()) {
            mounts_listbox.set_visible(mounts_listbox.get_children().length() != 0);
        }

        if (networks_listbox.get_visible()) {
            networks_listbox.set_visible(networks_listbox.get_children().length() != 0);
        }

        if (places_section.get_visible()) {
            if (!mounts_listbox.get_visible() && !networks_listbox.get_visible()) {
                places_section.reveal(true);
                only_places = true;
            } else if (only_places) {
                places_section.reveal(false);
                only_places = false;
            }
        }

        placeholder.hide();
        placeholder.set_no_show_all(true);

        if (!places_section.get_visible() &&
            !mounts_listbox.get_visible() &&
            !networks_listbox.get_visible())
        {
            placeholder.set_no_show_all(false);
            placeholder.show();
        }
    }

    /*
     * Figures out which stuff should be visible
     * Called when a setting changes
     */
    private void toggle_section_visibility(string section)
    {
        switch (section) {
            case "places":
                places_section.set_no_show_all(!show_places);
                places_section.set_visible(show_places);
                break;
            case "drives":
                mounts_listbox.set_no_show_all(!show_drives);
                mounts_listbox.set_visible(show_drives);
                break;
            case "networks":
                networks_listbox.set_no_show_all(!show_networks);
                networks_listbox.set_visible(show_networks);
                break;
            default:
                break;
        }

        check_expand();
    }

    /*
     * Reads the bookmarks file and adds all of the bookmarks to the view
     */
    private void refresh_bookmarks()
    {
        GLib.File bookmarks_file = get_bookmarks_file();
        if (!bookmarks_file.query_exists()) {
            return;
        }
        try {
            var dis = new GLib.DataInputStream(bookmarks_file.read());
            string line;
            while ((line = dis.read_line(null)) != null) {
                add_place(line, "bookmark");
            }
        } catch (GLib.Error e) {
            warning(e.message);
        }
    }

    /*
     * Adds special dirs to the view
     */
    private void refresh_special_dirs()
    {
        places_list.remove_all();
        places_section.clear();

        // Add home dir
        string path = GLib.Environment.get_home_dir();
        add_place(@"file://$path", "place");

        foreach (var special_dir in DEFAULT_DIRECTORIES) {
            path = GLib.Environment.get_user_special_dir(special_dir);
            add_place(@"file://$path", "place");
        }

        refresh_bookmarks();
    }

    /*
     * Finds all relevant mounts and adds them to the view
     */
    private void refresh_mounts()
    {
        foreach (Gtk.Widget item in mounts_listbox.get_children()) {
            item.destroy();
        }

        foreach (Gtk.Widget item in networks_listbox.get_children()) {
            item.destroy();
        }

        // Add volumes connected with a drive
        foreach (GLib.Drive drive in volume_monitor.get_connected_drives()) {
            foreach (GLib.Volume volume in drive.get_volumes()) {
                GLib.Mount mount = volume.get_mount();
                if (mount == null) {
                    add_volume(volume);
                } else {
                    add_mount(mount, volume.get_identifier("class"));
                }
            }
        }

        // Add volumes not connected with a drive
        foreach (GLib.Volume volume in volume_monitor.get_volumes()) {
            if (volume.get_drive() != null) {
                continue;
            }
            GLib.Mount mount = volume.get_mount();
            if (mount == null) {
                add_volume(volume);
            } else {
                add_mount(mount, volume.get_identifier("class"));
            }
        }

        // Add mounts without volumes
        foreach (GLib.Mount mount in volume_monitor.get_mounts()) {
            if (mount.is_shadowed() || mount.get_volume() != null) {
                continue;
            }

            GLib.File root = mount.get_default_location();

            if (!root.is_native()) {
                add_mount(mount, "network");
            } else {
                add_mount(mount, "device");
            }
        }

        get_child().show_all();
        check_expand();
    }

    /*
     * Adds a volume to the view
     */
    private void add_volume(GLib.Volume volume)
    {
        string? volume_class = volume.get_identifier("class");

        VolumeItem volume_item = new VolumeItem(volume);

        if (volume_class == "network") {
            networks_listbox.add(volume_item);
        } else {
            mounts_listbox.add(volume_item);
        }

        volume_item.get_parent().set_can_focus(false);

        volume_item.send_message.connect(set_message);
    }

    /*
     * Adds a mount to the view
     */
    private void add_mount(GLib.Mount mount, string? mount_class)
    {
        if (!mount.can_unmount() && !mount.can_eject()) {
            return;
        }

        if (mount.is_shadowed()) {
            return;
        }

        MountItem mount_item = new MountItem(mount, mount_class);

        if (mount_class == "network") {
            networks_listbox.add(mount_item);
        } else {
            mounts_listbox.add(mount_item);
        }

        mount_item.get_parent().set_can_focus(false);

        mount_item.send_message.connect(set_message);
    }

    /*
     * Add a place item to the places view
     */
    private void add_place(string path, string class)
    {
        string place = path.split(" ")[0];
        string unescaped_path = GLib.Uri.unescape_string(place);

        if (places_list.contains(unescaped_path)) {
            return;
        }

        GLib.File file = GLib.File.new_for_uri(unescaped_path);

        PlaceItem place_item = new PlaceItem(file, "place");
        places_list.add(unescaped_path);
        places_section.add_item(place_item);

        place_item.send_message.connect(set_message);
    }

    private void set_message(string message) {
        message_bar.set_content(message);
    }
}

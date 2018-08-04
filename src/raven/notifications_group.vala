/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2018 Budgie Desktop Developers
 * Copyright 2014 Josh Klar <j@iv597.com> (original Budgie work, prior to Budgie 10)
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

    /**
     * NotificationGroup is a group of notifications.
     */
    public class NotificationGroup : Gtk.Box {
        public int? count = 0;
        private HashTable<uint, NotificationClone>? notifications = null;
        private Gtk.ListBox? list = null;
        private Gtk.Box? header = null;
        private Gtk.Image? app_image = null;
        private Gtk.Label? app_label = null;
        private string? app_name;
        private Gtk.EventBox? close_button = null;

        /**
         * Signals
         */
        public signal void dismissed_group(string app_name);
        public signal void dismissed_notification(uint id);

        public NotificationGroup(string c_app_icon, string c_app_name) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 10);
            margin = 5;
            app_name = c_app_name;

            notifications = new HashTable<uint, NotificationClone>(direct_hash, direct_equal);
            list = new Gtk.ListBox();

            /**
             * Header creation
             */
            header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0); // Create our Notification header

            app_image = new Gtk.Image.from_icon_name(c_app_icon, Gtk.IconSize.DND);
            app_image.halign = Gtk.Align.START;
            app_image.margin_end = 5;

            app_label = new Gtk.Label(app_name);
            app_label.ellipsize = Pango.EllipsizeMode.END;
            app_label.halign = Gtk.Align.START;
            app_label.justify = Gtk.Justification.LEFT;
            app_label.use_markup = true;

            close_button = new Gtk.EventBox();
            close_button.halign = Gtk.Align.END;
            var exit_icon = new Gtk.Image.from_icon_name("list-remove-all-symbolic", Gtk.IconSize.MENU);
            close_button.add(exit_icon);
            close_button.button_release_event.connect((e) => {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }
    
                dismiss_all();
    
                return Gdk.EVENT_STOP;
            });

            header.pack_start(app_image, false, false, 0);
            header.pack_start(app_label, false, false, 0);
            header.pack_end(close_button, false, false, 0);

            pack_start(header);
            pack_start(list);
        }

        /**
         * add_notification is responsible for adding a notification (if it doesn't exist) and updating our counter
         */
        public void add_notification(uint id, NotificationClone notification) {
            if (notification == null) {
                return;
            }

            if (notifications.contains(id)) { // If this id already exists
                remove_notification(id); // Remove the current one first
            }

            notifications.insert(id, notification);
            list.add(notification);
            update_count();

            notification.closed_individually.connect(() => { // When this notification is closed
                uint n_id = (uint) notification.id;
                remove_notification(n_id);
                dismissed_notification(n_id);
            });
        }

        /**
         * dismiss_all is responsible for dismissing all notifications
         */
        public void dismiss_all() {
            notifications.foreach((id, notification) => { // For reach notification
                remove_notification(id); // Remove this notification
            });

            notifications.steal_all();
            update_count();
            dismissed_group(app_name);
        }

        /**
         * remove_notification is responsible for removing a notification (if it exists) and updating our counter
         */
        public void remove_notification(uint id) {
            var notification = notifications.lookup(id); // Get our notification

            if (notification != null) { // If this notification exists
                notifications.steal(id);
                list.remove(notification.get_parent());
                notification.destroy(); // Nuke the notification
                update_count(); // Update our counter
                dismissed_notification(id); // Notify anything listening

                if (count == 0) { // This was the last notification
                    dismissed_group(app_name); // Dismiss the group
                }
            }
        }

        /**
         * update_count updates our notifications count for this group
         */
        public void update_count() {
            count = (int) list.get_children().length();
            app_label.set_markup("<b>%s (%i)</b>".printf(app_name, count));
        }
    }
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

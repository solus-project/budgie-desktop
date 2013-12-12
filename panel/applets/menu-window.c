/*
 * menu-window.c - Provides a SolusOS-style menu
 *
 * Heavily based on designs and ideas from previous SolusOS iterations
 * and the Cardapio Menu design.
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */

#include <gmenu-tree.h>

#include "menu-window.h"

G_DEFINE_TYPE(MenuWindow, menu_window, GTK_TYPE_WINDOW)

/* Boilerplate GObject code */
static void menu_window_class_init(MenuWindowClass *klass);
static void menu_window_init(MenuWindow *self);
static void menu_window_dispose(GObject *object);

static void populate_menu(MenuWindow *self, GMenuTreeDirectory *directory);
static GtkWidget* new_image_button(const gchar *text,
                                   GIcon *icon,
                                   gboolean radio);
static void toggled_cb(GtkWidget *widget, gpointer userdata);
static gboolean filter_list(GtkListBoxRow *row, gpointer userdata);
static void list_header(GtkListBoxRow *before,
                        GtkListBoxRow *after,
                        gpointer userdata);

/* Initialisation */
static void menu_window_class_init(MenuWindowClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &menu_window_dispose;
}

static void menu_window_init(MenuWindow *self)
{
        GtkWidget *scroll, *list, *sep;
        GtkWidget *layout, *box, *all_button;
        GdkScreen *screen;
        GdkVisual *visual;

        /* Sensible default size */
        gtk_window_set_default_size(GTK_WINDOW(self), 470, 510);
        gtk_container_set_border_width(GTK_CONTAINER(self), 3);

        /* Skip, no decorations, etc */
        gtk_window_set_decorated(GTK_WINDOW(self), FALSE);
        gtk_window_set_skip_taskbar_hint(GTK_WINDOW(self), TRUE);
        gtk_window_set_skip_pager_hint(GTK_WINDOW(self), TRUE);

        /* Use an RGBA visual to allow rounded windows, etc. */
        screen = gtk_widget_get_screen(GTK_WIDGET(self));
        visual = gdk_screen_get_rgba_visual(screen);
        gtk_widget_set_visual(GTK_WIDGET(self), visual);

        /* Main layout */
        layout = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_container_add(GTK_CONTAINER(self), layout);

        /* Left hand side is just a scroller for categories */
        scroll = gtk_scrolled_window_new(NULL, NULL);
        g_object_set(scroll, "margin", 4, NULL);
        box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
        gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll),
                GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
        self->group_box = box;
        gtk_container_add(GTK_CONTAINER(scroll), box);
        gtk_box_pack_start(GTK_BOX(layout), scroll, FALSE, FALSE, 0);

        /* Initial category item is also used as radio group leader */
        all_button = new_image_button("All", NULL, TRUE);
        self->all_button = all_button;
        gtk_box_pack_start(GTK_BOX(box), all_button, FALSE, FALSE, 0);
        g_signal_connect(all_button, "toggled", G_CALLBACK(toggled_cb),
                (gpointer)self);
        /* Visual separation */
        sep = gtk_separator_new(GTK_ORIENTATION_VERTICAL);
        gtk_box_pack_start(GTK_BOX(layout), sep, FALSE, FALSE, 0);

        /* Right hand side is similar, just applications */
        scroll = gtk_scrolled_window_new(NULL, NULL);
        g_object_set(scroll, "margin", 4, NULL);
        gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll),
                GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
        list = gtk_list_box_new();
        gtk_list_box_set_filter_func(GTK_LIST_BOX(list), filter_list,
                (gpointer)self, NULL);
        gtk_list_box_set_header_func(GTK_LIST_BOX(list), list_header,
                (gpointer)self, NULL);

        self->app_box = list;
        gtk_container_add(GTK_CONTAINER(scroll), list);
        gtk_box_pack_start(GTK_BOX(layout), scroll, TRUE, TRUE, 0);

        /* Load the menus */
        populate_menu(self, NULL);
}

static void menu_window_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (menu_window_parent_class)->dispose (object);
}

/* Utility; return a new MenuWindow */
GtkWidget* menu_window_new(void)
{
        MenuWindow *self;

        self = g_object_new(MENU_WINDOW_TYPE, NULL);
        return GTK_WIDGET(self);
}

static void populate_menu(MenuWindow *self, GMenuTreeDirectory *directory)
{
        GMenuTree *tree = NULL;
        GMenuTreeIter *iter;
        GMenuTreeDirectory *dir, *nextdir;
        __attribute__ ((unused)) GMenuTreeEntry *entry;
        GError *error = NULL;
        GMenuTreeItemType type;
        GtkWidget *button;
        const gchar *name;
        const gchar *dirname;
        __attribute__ ((unused)) GDesktopAppInfo *info;
        GIcon *icon = NULL;

        if (!directory) {
                tree = gmenu_tree_new("gnome-applications.menu", GMENU_TREE_FLAGS_SORT_DISPLAY_NAME);

                gmenu_tree_load_sync(tree, &error);
                if (error) {
                        g_warning("Failed to load menu: %s\n", error->message);
                        g_error_free(error);
                        return;
                }
                dir = gmenu_tree_get_root_directory(tree);
        } else {
                dir = directory;
        }
        dirname = gmenu_tree_directory_get_name(dir);
        iter = gmenu_tree_directory_iter(dir);

        while ((type = gmenu_tree_iter_next(iter)) != GMENU_TREE_ITEM_INVALID) {
                switch (type) {
                        case GMENU_TREE_ITEM_DIRECTORY:
                                nextdir = gmenu_tree_iter_get_directory(iter);
                                name = gmenu_tree_directory_get_name(nextdir);
                                icon = gmenu_tree_directory_get_icon(nextdir);
                                button = new_image_button(name, icon, TRUE);
                                gtk_box_pack_start(GTK_BOX(self->group_box), button,
                                        FALSE, FALSE, 0);
                                gtk_radio_button_join_group(GTK_RADIO_BUTTON(button),
                                        GTK_RADIO_BUTTON(self->all_button));
                                g_object_set_data_full(G_OBJECT(button), "group",
                                        g_strdup(name), &g_free);
                                g_signal_connect(button, "toggled", G_CALLBACK(toggled_cb),
                                        (gpointer)self);
                                populate_menu(self, nextdir);
                                break;
                        case GMENU_TREE_ITEM_ENTRY:
                                entry = gmenu_tree_iter_get_entry(iter);
                                info = gmenu_tree_entry_get_app_info(entry);
                                name = g_app_info_get_name(G_APP_INFO(info));
                                icon = g_app_info_get_icon(G_APP_INFO(info));
                                button = new_image_button(name, icon, FALSE);
                                g_object_set_data_full(G_OBJECT(button), "group",
                                        g_strdup(dirname), &g_free);
                                gtk_container_add(GTK_CONTAINER(self->app_box),
                                        button);
                                break;
                        default:
                                break;
                }
        }

        gmenu_tree_iter_unref(iter);
        if (tree)
                g_object_unref(tree);
}

static void toggled_cb(GtkWidget *widget, gpointer userdata)
{
        MenuWindow *self;
        if (!gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(widget)))
                return;

        self = MENU_WINDOW(userdata);
        self->group = g_object_get_data(G_OBJECT(widget), "group");
        gtk_list_box_invalidate_filter(GTK_LIST_BOX(self->app_box));
        gtk_list_box_invalidate_headers(GTK_LIST_BOX(self->app_box));
}

static gboolean filter_list(GtkListBoxRow *row, gpointer userdata)
{
        MenuWindow *self;
        GtkWidget *child;
        gchar *data = NULL;

        /* If no group is set, don't filter */
        self = MENU_WINDOW(userdata);
        if (self->group == NULL)
                return TRUE;

        child = gtk_bin_get_child(GTK_BIN(row));
        data = g_object_get_data(G_OBJECT(child), "group");
        if (data == NULL)
                return TRUE;

        if (!g_str_equal(data, self->group))
                return FALSE;

        return TRUE;
}

static void list_header(GtkListBoxRow *before,
                        GtkListBoxRow *after,
                        gpointer userdata)
{
        MenuWindow *self;
        GtkWidget *child, *header;
        gchar *prev = NULL, *next = NULL;
        gchar *displ_name;

        self = MENU_WINDOW(userdata);
        /* Hide headers when inside categories */
        if (self->group) {
                if (before)
                        gtk_list_box_row_set_header(before, NULL);
                if (after)
                        gtk_list_box_row_set_header(after, NULL);
                return;
        }

        if (before) {
                child = gtk_bin_get_child(GTK_BIN(before));
                prev = g_object_get_data(G_OBJECT(child), "group");
        }
        if (after) {
                child = gtk_bin_get_child(GTK_BIN(after));
                next = g_object_get_data(G_OBJECT(child), "group");
        }
        if (!before || !after || !g_str_equal(prev, next)) {
                /* Need a header */
                displ_name = g_markup_printf_escaped("<big>%s</big>", prev);
                header = gtk_label_new(displ_name);
                g_free(displ_name);
                gtk_label_set_use_markup(GTK_LABEL(header), TRUE);
                gtk_list_box_row_set_header(before, header);
                gtk_widget_set_halign(header, GTK_ALIGN_START);
                g_object_set(header, "margin", 3, NULL);
        }
}

static GtkWidget* new_image_button(const gchar *text,
                                   GIcon *icon,
                                   gboolean radio)
{
        GtkWidget *button, *image, *label;
        GtkWidget *box;
        guint icon_size = radio ? GTK_ICON_SIZE_MENU : GTK_ICON_SIZE_BUTTON;

        if (radio) {
                button = gtk_radio_button_new(NULL);
                g_object_set(button, "draw-indicator", FALSE, NULL);
        } else
                button = gtk_button_new();
        box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_container_add(GTK_CONTAINER(button), box);
        if (icon)
                image = gtk_image_new_from_gicon(icon, icon_size);
        else
                image = gtk_image_new_from_icon_name("applications-system",
                        icon_size);

        g_object_set(image, "margin-right", 10, NULL);
        gtk_widget_set_halign(image, GTK_ALIGN_START);
        gtk_box_pack_start(GTK_BOX(box), image, FALSE, FALSE, 0);
        label = gtk_label_new(text);
        gtk_widget_set_halign(label, GTK_ALIGN_START);
        gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0);

        /* No relief style :) */
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        return button;
}

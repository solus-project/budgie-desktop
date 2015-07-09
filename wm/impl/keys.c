/*
 * keys.c - implements a GNOME Shell interface shim
 * 
 * Main purpose is to enable integration with GNOME Settings Daemon's
 * mediakeys plugin, i.e. make shortcuts work within the Budgie Desktop
 * exactly as they would under GNOME Shell. With the stinking exception
 * of the Screenshot action, which is another shell iface that's hardcoded.
 * 
 * In time we'll split this up into a shim and providers, and implement
 * our own Screenshot and Record to integrate further with GNOME Settings
 * Daemon shortcuts (and besides, X11 screenies can invariably tear...)
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
#include <meta/prefs.h>
#include <meta/display.h>
#include <meta/util.h>

#include "impl.h"
#include "shell_proxy.h"

/** Main grab table, action-id -> sender */
static GHashTable *_kgrabs = NULL;

/** Watcher table, i.e. dbus interfaces who might disappear */
static GHashTable *_watches = NULL;

/** Our bus ID */
static guint __id;

/** Kept here because we'll end up doing recycling work in future when
 *  we introduce dynamic session replacement
 */
static ShellKeyGrabber *skel;

/** Avoid the obtuse oop crap and just hold a lifetime reference */
static MetaDisplay *_display;

/* Client (i.e. g-s-d) quit, handle gracefully. */
static void on_disappeared(GDBusConnection *conn, const gchar *name,  gpointer userdata)
{
        guint id;
        GHashTableIter iter;
        const gchar *value;
        guint key;

        if (!g_hash_table_contains(_watches, name)) {
                return;
        }

        id = GPOINTER_TO_UINT(g_hash_table_lookup(_watches, name));
        g_bus_unwatch_name(id);

        g_hash_table_iter_init(&iter, _kgrabs);

        while (g_hash_table_iter_next(&iter, (void**)&key, (void**)&value)) {
                if (!g_str_equal(value, name)) {
                        continue;
                }
                meta_display_ungrab_accelerator(_display, key);
                g_hash_table_remove(_kgrabs, GUINT_TO_POINTER(key));
        }
}

/**
 * Insert a grab into the watchers and grabs table if Mutter accepts them
 */
static guint _grab(const gchar *sender, gchar *seq, guint flag)
{
        guint ret;
        guint id;
        gchar *txt = NULL;
        ret = meta_display_grab_accelerator(_display, seq);
        if (ret != META_KEYBINDING_ACTION_NONE) {
                txt = g_strdup(sender);
                g_hash_table_insert(_kgrabs, GUINT_TO_POINTER(ret), txt);
                /* Make sure we clean up if a client disappears */
                id = g_bus_watch_name(G_BUS_TYPE_SESSION, sender, G_BUS_NAME_WATCHER_FLAGS_NONE,
                        NULL, on_disappeared, NULL, NULL);
                txt = g_strdup(sender);
                g_hash_table_insert(_watches, txt, GUINT_TO_POINTER(id));
        }

        return ret;
}

/**
 * Handle GrabAccelerator dbus interface
 */
static gboolean on_grab_accelerator(ShellKeyGrabber *grab,
                                      GDBusMethodInvocation *i,
                                      gchar *seq, guint flag)
{
        const gchar *sender;
        guint id;

        /* Only really care about this for the sake of keys. */
        sender = g_dbus_method_invocation_get_sender(i);
        id = _grab(sender, seq, flag);
        if (id == META_KEYBINDING_ACTION_NONE) {
                return FALSE;
        }

        shell_key_grabber_complete_grab_accelerator(grab, i, id);
        return TRUE;
}

/**
 * Handle GrabAccelerators dbus interface (batch)
 */
static gboolean on_grab_accelerators(ShellKeyGrabber *grab,
                                       GDBusMethodInvocation *i,
                                       GVariant *vars)
{
        GVariantIter iter;
        gchar *seq = NULL;
        guint flag;
        guint id;
        const gchar *sender;
        GVariantBuilder builder;

        g_variant_iter_init(&iter, vars);
        sender = g_dbus_method_invocation_get_sender(i);
        g_variant_builder_init(&builder, G_VARIANT_TYPE("au"));

        while (g_variant_iter_loop(&iter, "(su)", &seq, &flag, NULL)) {
                id = _grab(sender, seq, flag);
                /* May still result in META_KEYBINDING_ACTION_NONE.. */
                g_variant_builder_add(&builder, "u", id);
        }

        shell_key_grabber_complete_grab_accelerators(grab, i, g_variant_builder_end(&builder));
        return TRUE;
}

/**
 * Unset an accelerator
 */
static gboolean on_ungrab_accelerator(ShellKeyGrabber *grab,
                                        GDBusMethodInvocation *i,
                                        guint id)
{
        gboolean ret = meta_display_ungrab_accelerator(_display, id);
        if (ret) {
                g_hash_table_remove(_kgrabs, GUINT_TO_POINTER(id));
        }

        shell_key_grabber_complete_ungrab_accelerator(grab, i, ret);
        return TRUE;
}

/**
 * Let everyone know about the signal.
 */
static void on_activated(MetaDisplay *display, guint action, guint device_id)
{
        GVariantBuilder *builder = NULL;
        GVariant *params = NULL;

        /* Cheers, flashback guys */
        builder = g_variant_builder_new(G_VARIANT_TYPE("a{sv}"));
        g_variant_builder_add(builder, "{sv}", "device-id", g_variant_new_uint32(device_id));
        g_variant_builder_add(builder, "{sv}", "timestamp", g_variant_new_uint32(0));
        g_variant_builder_add(builder, "{sv}", "action-mode", g_variant_new_uint32(0));

        params = g_variant_new("a{sv}", builder);
        g_variant_builder_unref(builder);

        shell_key_grabber_emit_accelerator_activated(skel, action, params);
}

/**
 * Boilerplate cruft, set up implementation
 */
static void on_bus_acquired(GDBusConnection *conn, const gchar *name, gpointer userdata)
{
        skel = shell_key_grabber_skeleton_new();

        /* God forgive me. */
        if (!g_dbus_interface_skeleton_export(G_DBUS_INTERFACE_SKELETON(skel), conn, "/org/gnome/Shell", NULL)) {
                return;
        }
        g_signal_connect(skel, "handle-grab-accelerator", G_CALLBACK(on_grab_accelerator), NULL);
        g_signal_connect(skel, "handle-grab-accelerators", G_CALLBACK(on_grab_accelerators), NULL);
        g_signal_connect(skel, "handle-ungrab-accelerator", G_CALLBACK(on_ungrab_accelerator), NULL);
        g_signal_connect(_display, "accelerator-activated", G_CALLBACK(on_activated), NULL);
}

/**
 * TODO: Actually handle this gracefully..
 */
static void on_name_lost(GDBusConnection *conn, const gchar *name, gpointer userdata)
{
        g_warning("budgie-wm-keys lost the shell interface");
}

/**
 * Entry point, called from core.c
 */
void budgie_keys_init(MetaDisplay* display)
{
        if (_display) {
                return;
        }
        _display = display;
        _kgrabs = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, g_free);
        _watches = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

        __id = g_bus_own_name(G_BUS_TYPE_SESSION, "org.gnome.Shell",
                G_BUS_NAME_OWNER_FLAGS_ALLOW_REPLACEMENT |
                G_BUS_NAME_OWNER_FLAGS_REPLACE,
                on_bus_acquired,
                NULL,
                on_name_lost,
                NULL,
                NULL);
}

/**
 * Cleanup our tables and stop owning the dbus name
 */
void budgie_keys_end()
{
        _display = NULL;
        if (_kgrabs) {
                g_hash_table_unref(_kgrabs);
                _kgrabs = NULL;
                return;
        }
        if (_watches) {
                g_hash_table_unref(_watches);
                _watches = NULL;
        }
        if (__id > 0) {
                g_bus_unown_name(__id);
                __id = 0;
        }
}

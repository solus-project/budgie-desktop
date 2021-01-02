/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2016-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#define _GNU_SOURCE

#include "theme-manager.h"
#include "theme.h"
#include <gtk/gtk.h>

struct _BudgieThemeManagerClass {
	GObjectClass parent_class;
};

struct _BudgieThemeManager {
	GObject parent;
	GtkCssProvider* css_provider;
	GSettings* desktop_settings;
	gboolean builtin_enabled;
};

static void budgie_theme_manager_set_theme_css(BudgieThemeManager* self, const gchar* theme_portion);
static void budgie_theme_manager_theme_changed(BudgieThemeManager* self, GParamSpec* prop, GtkSettings* settings);
static void budgie_theme_manager_builtin_changed(BudgieThemeManager* self, const gchar* key, GSettings* settings);

G_DEFINE_TYPE(BudgieThemeManager, budgie_theme_manager, G_TYPE_OBJECT)

/**
 * budgie_theme_manager_new:
 *
 * Construct a new BudgieThemeManager object
 */
BudgieThemeManager* budgie_theme_manager_new() {
	return g_object_new(BUDGIE_TYPE_THEME_MANAGER, NULL);
}

/**
 * Handle cleanup
 */
static void budgie_theme_manager_dispose(GObject* obj) {
	BudgieThemeManager* self = BUDGIE_THEME_MANAGER(obj);

	/* Ensure we nuke the style provider */
	budgie_theme_manager_set_theme_css(self, NULL);

	g_clear_object(&self->desktop_settings);

	G_OBJECT_CLASS(budgie_theme_manager_parent_class)->dispose(obj);
}

/**
 * Class initialisation
 */
static void budgie_theme_manager_class_init(BudgieThemeManagerClass* klazz) {
	GObjectClass* obj_class = G_OBJECT_CLASS(klazz);

	/* gobject vtable hookup */
	obj_class->dispose = budgie_theme_manager_dispose;
}

/**
 * Instaniation
 */
static void budgie_theme_manager_init(BudgieThemeManager* self) {
	GtkSettings* settings = NULL;

	/* TODO: Stop using .budgie-panel for desktop-wide schema ! */
	self->desktop_settings = g_settings_new("com.solus-project.budgie-panel");
	self->builtin_enabled = g_settings_get_boolean(self->desktop_settings, "builtin-theme");

	/* Update whether we can use the builtin theme or not */
	g_signal_connect_swapped(self->desktop_settings, "changed::builtin-theme", G_CALLBACK(budgie_theme_manager_builtin_changed), self);

	settings = gtk_settings_get_default();
	g_signal_connect_swapped(settings, "notify::gtk-theme-name", G_CALLBACK(budgie_theme_manager_theme_changed), self);

	/* Bind the dark-theme option for the whole process */
	g_settings_bind(self->desktop_settings, "dark-theme", settings, "gtk-application-prefer-dark-theme", G_SETTINGS_BIND_GET);

	/* Trigger theme changed */
	budgie_theme_manager_theme_changed(self, NULL, settings);
}

/**
 * Set the current process-wide styling to the selected theme portion, i.e.
 * "theme.css" or "theme_hc.css".
 *
 * @note passing NULL to theme_portion will remove any theme providers allowing
 * user themes to completely override the styling.
 */
static void budgie_theme_manager_set_theme_css(BudgieThemeManager* self, const gchar* theme_portion) {
	GdkScreen* screen = NULL;
	GtkCssProvider* css_provider = NULL;
	gchar* theme_uri = NULL;
	GError* error = NULL;
	GFile* file = NULL;

	screen = gdk_screen_get_default();

	/* NULL portion, just remove the CSS provider */
	if (!theme_portion) {
		goto remove_provider;
	}

	/* Setting an invalid theme */
	theme_uri = budgie_form_theme_path(theme_portion);
	if (!theme_uri) {
		g_warning("Requested invalid theme: %s", theme_portion);
		return;
	}

	/* Attempt to load theme for the given URI */
	file = g_file_new_for_uri(theme_uri);
	g_free(theme_uri);
	css_provider = gtk_css_provider_new();
	if (!gtk_css_provider_load_from_file(css_provider, file, &error)) {
		g_warning("Cannot load theme %s: %s\n", theme_uri, error->message);
		g_error_free(error);
		g_object_unref(css_provider);
		g_object_unref(file);
		return;
	}
	g_object_unref(file);

remove_provider:
	if (self->css_provider) {
		gtk_style_context_remove_provider_for_screen(screen, GTK_STYLE_PROVIDER(self->css_provider));
		g_clear_object(&self->css_provider);
	}

	/* No new theme has been set, just bail */
	if (!css_provider) {
		return;
	}
	/* Set the style globally */
	gtk_style_context_add_provider_for_screen(screen, GTK_STYLE_PROVIDER(css_provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
	self->css_provider = css_provider;
}

static void budgie_theme_manager_theme_changed(BudgieThemeManager* self, __attribute__((unused)) GParamSpec* prop, GtkSettings* settings) {
	gchar* theme_name = NULL;
	const gchar* theme_css = NULL;

	/* Set theme_css NULL if internal theming is disabled */
	if (self->builtin_enabled) {
		g_object_get(settings, "gtk-theme-name", &theme_name, NULL);
		if (theme_name && g_str_equal(theme_name, "HighContrast")) {
			theme_css = "theme_hc";
		} else {
			theme_css = "theme";
		}
		g_free(theme_name);
	}

	budgie_theme_manager_set_theme_css(self, theme_css);
}

static void budgie_theme_manager_builtin_changed(BudgieThemeManager* self, const gchar* key, GSettings* settings) {
	self->builtin_enabled = g_settings_get_boolean(settings, key);
	/* Update now based on whether we can use the built-in */
	budgie_theme_manager_theme_changed(self, NULL, gtk_settings_get_default());
}

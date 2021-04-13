/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#include "applet.h"
#include "budgie-enums.h"

/**
 * SECTION:applet
 * @Short_description: Budgie Panel GTK+ Widget
 * @Title: BudgieApplet
 *
 * The BudgieApplet is the main event when it comes to providing a Budgie
 * Panel extension. This is the widget that is visible to the user, and is
 * provided by, and instaniated by, your #BudgiePlugin.
 *
 * Those implementing applets have a specific API available to them in order
 * to achieve better integration with the overall desktop. At the bare minimum
 * you should at least ensure that your applet respects the sizes exposed by
 * the managing panel, via the #BudgieApplet::panel-size-changed signal.
 *
 * BudgieApplet extends #GtkEventBox to leave you free to make your own choices
 * on internal applet layout and configuration. Do note, however, that the
 * panel implementation will not call #gtk_widget_show_all, it is solely
 * your responsibility to ensure all of your contents are displayed. This
 * is to enable applet's to contextually hide part of their user interface
 * when required.
 *
 */
enum {
	PROP_PREFIX = 1,
	PROP_SCHEMA,
	PROP_ACTIONS,
	N_PROPS
};

enum {
	APPLET_SIZE_CHANGED = 0,
	APPLET_POSITION_CHANGED,
	N_SIGNALS
};

struct _BudgieAppletPrivate {
	char* prefix;
	char* schema;
	BudgiePanelAction actions;
};

G_DEFINE_TYPE_WITH_PRIVATE(BudgieApplet, budgie_applet, GTK_TYPE_EVENT_BOX)

static GParamSpec* obj_properties[N_PROPS] = {NULL};
static guint applet_signals[N_SIGNALS] = {0};

static void budgie_applet_set_property(GObject* object, guint id, const GValue* value, GParamSpec* spec) {
	BudgieApplet* self = BUDGIE_APPLET(object);

	switch (id) {
		case PROP_PREFIX:
			budgie_applet_set_settings_prefix(self, g_value_get_string(value));
			break;
		case PROP_SCHEMA:
			budgie_applet_set_settings_schema(self, g_value_get_string(value));
			break;
		case PROP_ACTIONS:
			self->priv->actions = g_value_get_flags(value);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
			break;
	}
}

static void budgie_applet_get_property(GObject* object, guint id, GValue* value, GParamSpec* spec) {
	BudgieApplet* self = BUDGIE_APPLET(object);

	switch (id) {
		case PROP_PREFIX:
			g_value_set_string(value, budgie_applet_get_settings_prefix(self));
			break;
		case PROP_SCHEMA:
			g_value_set_string(value, budgie_applet_get_settings_schema(self));
			break;
		case PROP_ACTIONS:
			g_value_set_flags(value, self->priv->actions);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
			break;
	}
}

/**
 * budgie_applet_invoke_action:
 * @action: Action to invoke
 *
 * Invoke the given action on this applet. This action will only be one
 * that has been declared in supported actions bitmask.
 *
 * To allow better integration between the Budgie Desktop, and the applets
 * that live within it, the panel will relay actions to applets that have
 * set their #BudgieApplet:supported-actions to a matching bitmask.
 *
 * For example, if we wish to listen for Menu Key events, we can simply do
 * the following in C:
 *
 * |[<!-- language="C" -->
 *
 *      static void my_applet_invoke_action(BudgieApplet *applet, BudgiePanelAction action)
 *      {
 *              if (action == BUDGIE_PANEL_ACTION_MENU) {
 *                      my_applet_do_predict_the_lottery(MY_APPLET(applet));
 *              }
 *      }
 *
 *      static void my_class_init(GObjectClass *class)
 *      {
 *              MyClass *mc = MY_CLASS(klass);
 *              ..
 *              mc->invoke_action = my_applet_invoke_action;
 *      }
 * ]|
 *
 * Likewise, a Vala implementation might look like the following:
 * |[<!-- language="Vala" -->
 *
 *      public override void invoke_action(Budgie.PanelAction action)
 *      {
 *          if (action == Budgie.PanelAction.MENU) {
 *              this.predict_the_lottery();
 *          }
 *      }
 * ]|
 */
void budgie_applet_invoke_action(BudgieApplet* self, BudgiePanelAction action) {
	BudgieAppletClass* klazz = NULL;

	if (!BUDGIE_IS_APPLET(self)) {
		return;
	}

	klazz = BUDGIE_APPLET_GET_CLASS(self);

	if (klazz->invoke_action) {
		klazz->invoke_action(self, action);
	}
}

/**
 * budgie_applet_supports_settings:
 *
 * Implementations should override this to return TRUE if they support
 * a settings UI
 *
 * Returns: true if this implementation supports a Settings UI
 */
gboolean budgie_applet_supports_settings(BudgieApplet* self) {
	BudgieAppletClass* klazz = NULL;

	if (!BUDGIE_IS_APPLET(self)) {
		return FALSE;
	}

	klazz = BUDGIE_APPLET_GET_CLASS(self);
	if (!klazz->supports_settings) {
		return FALSE;
	}
	return klazz->supports_settings(self);
}

/**
 * budgie_applet_get_settings_ui:
 *
 * For applets that need to expose settings, they should both override the
 * #BudgieApplet::supports_settings method and return a new widget instance
 * whenever this function is invoked.
 *
 * This UI will live in the Raven sidebar within the Budgie Desktop, and
 * will be destroyed as soon as it's not being used. It's advisable to keep
 * this widget implementation light, and to prefer vertical space.
 *
 * Returns: (transfer full) (nullable): A GTK Settings UI
 */
GtkWidget* budgie_applet_get_settings_ui(BudgieApplet* self) {
	BudgieAppletClass* klazz = NULL;

	if (!BUDGIE_IS_APPLET(self)) {
		return NULL;
	}

	klazz = BUDGIE_APPLET_GET_CLASS(self);
	if (!klazz->get_settings_ui) {
		return NULL;
	}
	return klazz->get_settings_ui(self);
}

/**
 * budgie_applet_get_applet_settings:
 * @uuid: UUID for this instance
 *
 * If your #BudgiePlugin implementation passes the UUID to your BudgieApplet
 * implementation on construction, you can take advantage of per-instance
 * settings.
 *
 * For most applets, global GSettings keys are more than suffice. However,
 * in some situations, it may be beneficial to enable multiple unique instances
 * of your applet, each with their own configuration.
 *
 * To facilitate this, use this function to create a new relocatable settings
 * instance using your UUID. Make sure you set the #BudgieApplet:settings-schema
 * and #BudgieApplet:settings-prefix properties first.
 *
 * Returns: (transfer full): A newly created #GSettings for this applet instance
 */
GSettings* budgie_applet_get_applet_settings(BudgieApplet* self, gchar* uuid) {
	GSettings* settings = NULL;
	gchar* path = NULL;

	if (!self || !self->priv || !self->priv->schema || !self->priv->prefix) {
		return NULL;
	}

	path = g_strdup_printf("%s/{%s}/", self->priv->prefix, uuid);
	if (!path) {
		return NULL;
	}

	settings = g_settings_new_with_path(self->priv->schema, path);
	g_free(path);
	return settings;
}

static void budgie_applet_dispose(GObject* g_object) {
	BudgieApplet* self = BUDGIE_APPLET(g_object);

	g_clear_pointer(&self->priv->prefix, g_free);
	g_clear_pointer(&self->priv->schema, g_free);

	G_OBJECT_CLASS(budgie_applet_parent_class)->dispose(g_object);
}

static void budgie_applet_class_init(BudgieAppletClass* klazz) {
	GObjectClass* obj_class = G_OBJECT_CLASS(klazz);

	obj_class->get_property = budgie_applet_get_property;
	obj_class->set_property = budgie_applet_set_property;
	obj_class->dispose = budgie_applet_dispose;

	klazz->update_popovers = NULL;

	/* Todo, make the PREFIX/SCHEMA G_PARAM_CONSTRUCT_ONLY */

	/**
	 * BudgieApplet:settings-prefix:
	 *
	 * The GSettings schema path prefix for this applet
	 *
	 * For applets that require unique instance configuration, the
	 * panel management must know where to initialise the settings
	 * within the tree. The path takes the form:
	 *
	 * `$SETTINGS_PREFIX/{$UUID}`
	 *
	 * As an example, the Budgie Menu Applet set's the `settings-prefix`
	 * to:
	 * `/com/solus-project/budgie-panel/instance/budgie-menu`.
	 *
	 * This results in relocatable schemas being created at:
	 *
	 * `/com/solus-project/budgie-panel/instance/budgie-menu/{$UUID}`
	 */
	obj_properties[PROP_PREFIX] = g_param_spec_string(
		"settings-prefix", "GSettings schema prefix", "Set the GSettings schema prefix",
		NULL, G_PARAM_READWRITE);

	/**
	 * BudgieApplet:settings-schema:
	 *
	 * The ID of the GSettings schema used by this applet
	 *
	 * This only takes effect when you've also set #BudgieApplet:settings-prefix,
	 * and is used by the panel managemen to both initialise and delete your per-instance
	 * settings, respectively.
	 *
	 * As an example, the Budgie Menu Applet uses the schema:
	 *
	 * `com.solus-project.budgie-menu`
	 *
	 * as defined by the accompanying gschema XML file. Providing an incorrect
	 * schema ID is considered programmer error.
	 */
	obj_properties[PROP_SCHEMA] = g_param_spec_string(
		"settings-schema", "GSettings relocatable schema ID", "Set the GSettings relocatable schema ID",
		NULL, G_PARAM_READWRITE);

	/**
	 * BudgieApplet:supported-actions:
	 *
	 * The actions supported by this applet instance
	 */
	obj_properties[PROP_ACTIONS] = g_param_spec_flags(
		"supported-actions", "Supported panel actions", "Get/set the supported panel actions",
		BUDGIE_TYPE_PANEL_ACTION, BUDGIE_PANEL_ACTION_NONE, G_PARAM_READWRITE);

	/**
	 * BudgieApplet::panel-size-changed:
	 * @applet: The applet receiving the signal
	 * @panel_size: The new panel size
	 * @icon_size: Larget possible icon size for the panel
	 * @small_icon_size: Smaller icon that will still fit on the panel
	 *
	 * Used to notify this applet of a change in the panel size
	 */
	applet_signals[APPLET_SIZE_CHANGED] = g_signal_new(
		"panel-size-changed",
		BUDGIE_TYPE_APPLET,
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET(BudgieAppletClass, panel_size_changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 3, G_TYPE_INT, G_TYPE_INT, G_TYPE_INT);

	/**
	 * BudgieApplet::panel-position-changed:
	 * @applet: The applet receiving the signal
	 * @position: The new position (screen edge)
	 *
	 * Used to notify this applet of a change in the panel's placement
	 * on screen, so that it may adjust its own layout to better suit
	 * the geometry.
	 */
	applet_signals[APPLET_POSITION_CHANGED] = g_signal_new(
		"panel-position-changed",
		BUDGIE_TYPE_APPLET,
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET(BudgieAppletClass, panel_position_changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1, BUDGIE_TYPE_PANEL_POSITION);

	g_object_class_install_properties(obj_class, N_PROPS, obj_properties);
}

/**
 * budgie_applet_set_settings_prefix:
 *
 * Utility function for Python usage. See: #BudgieApplet:settings-prefix
 */
void budgie_applet_set_settings_prefix(BudgieApplet* self, const gchar* prefix) {
	if (!self || !prefix) {
		return;
	}

	BudgieAppletPrivate* priv = self->priv;
	if (priv->prefix) {
		g_free(priv->prefix);
	}
	priv->prefix = g_strdup(prefix);
}

/**
 * budgie_applet_get_settings_prefix:
 *
 * Utility function for Python usage. See: #BudgieApplet:settings-prefix
 */
const gchar* budgie_applet_get_settings_prefix(BudgieApplet* self) {
	if (!self) {
		return NULL;
	}
	return (const gchar*) self->priv->prefix;
}

/**
 * budgie_applet_set_settings_schema:
 *
 * Utility function for Python usage. See #BudgieApplet:settings-schema
 */
void budgie_applet_set_settings_schema(BudgieApplet* self, const gchar* schema) {
	if (!self || !schema) {
		return;
	}

	BudgieAppletPrivate* priv = self->priv;
	;
	if (priv->schema) {
		g_free(priv->schema);
	}
	priv->schema = g_strdup(schema);
}

/**
 * budgie_applet_get_settings_schema:
 *
 * Utility function for Python usage. See #BudgieApplet:settings-schema
 */
const gchar* budgie_applet_get_settings_schema(BudgieApplet* self) {
	if (!self) {
		return NULL;
	}
	return (const gchar*) self->priv->schema;
}

/**
 * budgie_applet_update_popovers:
 * @manager: (nullable)
 *
 * This virtual method should be implemented by panel applets that wish
 * to support #GtkPopover's natively. As each Budgie Panel may house multiple
 * GtkPopover widgets, each one must be registered with the @manager.
 *
 * During this call, it is safe to store a reference to the @manager. In
 * this call you should invoke #BudgiePopoverManager::register_popover to
 * register your popover with the panel manager.
 *
 * Each registered popover joins the global menu system of popovers in the
 * panel. It is a requirement to register, otherwise the panel will not
 * know when to expand and collapse the main panel harness to accommodate
 * the GtkPopover.
 *
 */
void budgie_applet_update_popovers(BudgieApplet* self, BudgiePopoverManager* manager) {
	if (!self) {
		return;
	}
	BudgieAppletClass* klazz = BUDGIE_APPLET_GET_CLASS(self);

	if (klazz->update_popovers) {
		klazz->update_popovers(self, manager);
	}
}

/**
 * budgie_applet_get_supported_actions:
 *
 * Utility function for Python bindings. See #BudgieApplet:supported-actions
 */
BudgiePanelAction budgie_applet_get_supported_actions(BudgieApplet* self) {
	if (!self) {
		return BUDGIE_PANEL_ACTION_NONE;
	}
	return self->priv->actions;
}

static void budgie_applet_init(BudgieApplet* self) {
	self->priv = budgie_applet_get_instance_private(self);

	gtk_widget_set_can_focus(GTK_WIDGET(self), FALSE);
}

/**
 * budgie_applet_new:
 *
 * Returns: (transfer full): A new BudgieApplet
 */
BudgieApplet* budgie_applet_new() {
	return g_object_new(BUDGIE_TYPE_APPLET, NULL);
}

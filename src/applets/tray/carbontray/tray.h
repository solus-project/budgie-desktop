#ifndef __CARBONTRAY_TRAY_H__
#define __CARBONTRAY_TRAY_H__

#include <gtk/gtk.h>
#include <gtk/gtkx.h>
#include <X11/Xatom.h>
#include <stdbool.h>
#include "child.h"

typedef struct {
	GObject parent_instance;

	GtkBox *box;
	int iconSize;

	GHashTable *socketTable;
	GtkWidget *invisible;

	GdkAtom selectionAtom;
	Atom opcodeAtom;
	Atom dataAtom;
	GSList *messages;
} CarbonTray;

typedef struct {
	GObjectClass parent_class;

	void (*message_sent)(CarbonTray *manager, CarbonChild *child, char *message, long id, long timeout);
} CarbonTrayClass;

typedef struct {
    char *string;

    long id;
    long length;
    long remainingLength;
    long timeout;

    Window window;
} CarbonMessage;

typedef struct {
	GtkWidget *box;
	cairo_t *cr;
} CarbonDrawData;



#define CARBON_TYPE_TRAY carbon_tray_get_type()
#define CARBON_TRAY(obj) G_TYPE_CHECK_INSTANCE_CAST((obj), CARBON_TYPE_TRAY, CarbonTray)
#define CARBON_IS_TRAY(obj) G_TYPE_CHECK_INSTANCE_TYPE((obj), CARBON_TYPE_TRAY)
#define CARBON_TRAY_CLASS(klass) G_TYPE_CHECK_CLASS_CAST((klass), CARBON_TYPE_TRAY, CarbonTrayClass))



GType carbon_tray_get_type(void);

CarbonTray* carbon_tray_new(GtkOrientation, int, int);

void carbon_tray_add_to_container(CarbonTray*, GtkContainer*);

void carbon_tray_remove_from_container(CarbonTray*, GtkContainer*);

bool carbon_tray_register(CarbonTray*, GdkScreen*);

void carbon_tray_unregister(CarbonTray*);

void carbon_tray_set_spacing(CarbonTray*, int spacing);

void carbon_tray_unref(CarbonTray*);

#endif

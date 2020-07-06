#include "tray.h"
#include "child.h"
#include "marshal.h"

/*
  this file's contents largely use xfce4-panel as a reference, which is licensed under the terms of the GNU GPL v2
  
  additional notes were taken from na-tray, the previous system tray for Budgie, which is part of MATE Desktop 
  and licensed under the terms of the GNU GPL v2
*/



// global declarations

#define TRAY_REQUEST_DOCK   0
#define TRAY_BEGIN_MESSAGE  1
#define TRAY_CANCEL_MESSAGE 2

static unsigned int message_sent_signal;



// static method header

static void carbon_tray_init(CarbonTray*);
static void carbon_tray_class_init(CarbonTrayClass*);
static void carbon_tray_finalize(GObject*);
static int carbon_tray_draw(GtkWidget*, cairo_t*);

static GdkFilterReturn window_filter(GdkXEvent*, GdkEvent*, void*);
static void handle_message_data(CarbonTray*, XClientMessageEvent*);
static void handle_message_begin(CarbonTray*, XClientMessageEvent*);
static void handle_message_cancel(CarbonTray*, XClientMessageEvent*);
static void handle_dock_request(CarbonTray*, XClientMessageEvent*);
static bool handle_undock_request(GtkSocket*, void*);

static void remove_message(CarbonTray*, XClientMessageEvent*);
static void free_message(CarbonMessage*);
static void set_xproperties(CarbonTray*);
static void draw_child(GtkWidget*, void*);



// define our type with the macro

G_DEFINE_TYPE(CarbonTray, carbon_tray, G_TYPE_OBJECT)



// public methods

CarbonTray* carbon_tray_new(GtkOrientation orientation, int iconSize, int spacing) {
	CarbonTray *self = g_object_new(CARBON_TYPE_TRAY, NULL);
	self->box = GTK_BOX(gtk_box_new(orientation, spacing));
	GtkWidget *boxWidget = GTK_WIDGET(self->box);

	self->iconSize = iconSize;

	if (orientation == GTK_ORIENTATION_HORIZONTAL) {
		gtk_widget_set_halign(boxWidget, GTK_ALIGN_START);
		gtk_widget_set_valign(boxWidget, GTK_ALIGN_FILL);
	} else {
		gtk_widget_set_halign(boxWidget, GTK_ALIGN_FILL);
		gtk_widget_set_valign(boxWidget, GTK_ALIGN_START);
	}

	gtk_widget_set_hexpand(boxWidget, FALSE);
	gtk_widget_set_vexpand(boxWidget, FALSE);
	gtk_widget_set_size_request(boxWidget, -1, -1);

	return self;
}

void carbon_tray_add_to_container(CarbonTray *tray, GtkContainer *container) {
	gtk_container_add(container, GTK_WIDGET(tray->box));
}

void carbon_tray_remove_from_container(CarbonTray *tray, GtkContainer *container) {
	gtk_container_remove(container, GTK_WIDGET(tray->box));
}

bool carbon_tray_register(CarbonTray *tray, GdkScreen *screen) {
	g_signal_connect(tray->box, "draw", G_CALLBACK(carbon_tray_draw), NULL);

	GtkWidget *invisible = gtk_invisible_new_for_screen(screen);
	gtk_widget_realize(invisible);
	gtk_widget_add_events(invisible, GDK_PROPERTY_CHANGE_MASK | GDK_STRUCTURE_MASK);

	int screen_number = gdk_screen_get_number(screen);
	char *selection_name = g_strdup_printf("_NET_SYSTEM_TRAY_S%d", screen_number);
	tray->selectionAtom = gdk_atom_intern(selection_name, FALSE);
	g_free(selection_name);

	GdkDisplay *display = gdk_screen_get_display(screen);

	tray->invisible = GTK_WIDGET(g_object_ref(G_OBJECT(invisible)));
	set_xproperties(tray);

	unsigned int timestamp = gdk_x11_get_server_time(gtk_widget_get_window(invisible));

	bool succeed = gdk_selection_owner_set_for_display(display, gtk_widget_get_window(invisible), tray->selectionAtom, timestamp, TRUE);

	if (succeed) {
		Window root_window = RootWindowOfScreen(GDK_SCREEN_XSCREEN(screen));

		XClientMessageEvent xevent;

		/* send a message to x11 that we're going to handle this display */
		xevent.type = ClientMessage;
		xevent.window = root_window;
		xevent.message_type = gdk_x11_get_xatom_by_name_for_display(display, "MANAGER");
		xevent.format = 32;
		xevent.data.l[0] = timestamp;
		xevent.data.l[1] = (long) gdk_x11_atom_to_xatom_for_display(display, tray->selectionAtom);
		xevent.data.l[2] = (long) GDK_WINDOW_XID(gtk_widget_get_window(GTK_WIDGET(invisible)));
		xevent.data.l[3] = 0;
		xevent.data.l[4] = 0;

		XSendEvent(GDK_DISPLAY_XDISPLAY(display), root_window, False, StructureNotifyMask,(XEvent*) &xevent);

		gdk_window_add_filter(gtk_widget_get_window(invisible), window_filter, tray);

		GdkAtom opcode_atom = gdk_atom_intern("_NET_SYSTEM_TRAY_OPCODE", FALSE);
		tray->opcodeAtom = gdk_x11_atom_to_xatom_for_display(display, opcode_atom);

		GdkAtom data_atom = gdk_atom_intern("_NET_SYSTEM_TRAY_MESSAGE_DATA", FALSE);
		tray->dataAtom = gdk_x11_atom_to_xatom_for_display(display, data_atom);
	} else {
	  	g_object_unref(G_OBJECT(tray->invisible));
	  	tray->invisible = NULL;
		gtk_widget_destroy(invisible);
	}

  	return succeed;
}

void carbon_tray_unregister(CarbonTray *tray) {
	GtkWidget *invisible = tray->invisible;
	GdkDisplay *display = gtk_widget_get_display(invisible);
	GdkWindow *owner = gdk_selection_owner_get_for_display(display, tray->selectionAtom);

	if (owner == gtk_widget_get_window(invisible)) {
      	gdk_selection_owner_set_for_display(display, NULL, tray->selectionAtom, gdk_x11_get_server_time(gtk_widget_get_window(invisible)), TRUE);
    }

	gdk_window_remove_filter(gtk_widget_get_window(invisible), window_filter, tray);

	tray->invisible = NULL;
	gtk_widget_destroy(invisible);
	g_object_unref(G_OBJECT(invisible));
}

void carbon_tray_set_spacing(CarbonTray *tray, int spacing) {
	gtk_box_set_spacing(tray->box, spacing);
}



// static methods

static void carbon_tray_init(CarbonTray* self) {
	self->socketTable = g_hash_table_new(NULL, NULL);
	self->invisible = NULL;

	self->selectionAtom = NULL;
	self->opcodeAtom = 0;
	self->dataAtom = 0;
	self->messages = NULL;
}

static void carbon_tray_class_init(CarbonTrayClass *klass) {
	GObjectClass *gobjectClass = G_OBJECT_CLASS(klass);
	gobjectClass->finalize = carbon_tray_finalize;

	g_signal_new("message-sent", G_OBJECT_CLASS_TYPE (klass), G_SIGNAL_RUN_LAST,
		  G_STRUCT_OFFSET (CarbonTrayClass, message_sent), NULL, NULL,
		  g_cclosure_user_marshal_VOID__OBJECT_STRING_LONG_LONG,
		  G_TYPE_NONE, 4,
		  GTK_TYPE_SOCKET,
		  G_TYPE_STRING,
		  G_TYPE_LONG,
		  G_TYPE_LONG);
}

static void carbon_tray_finalize(GObject *object) {
	CarbonTray *tray = CARBON_TRAY(object);

	g_hash_table_destroy(tray->socketTable);

	if (tray->messages) {
		g_slist_foreach(tray->messages,(GFunc)(void(*)(void)) free_message, NULL);
		g_slist_free(tray->messages);
	}

	G_OBJECT_CLASS(carbon_tray_parent_class)->finalize(object);
}

static int carbon_tray_draw(GtkWidget *widget, cairo_t *cr) {
	CarbonDrawData data;
	data.box = widget;
	data.cr = cr;
	
	gtk_container_foreach(GTK_CONTAINER(widget), draw_child, &data);

	return TRUE;
}

static GdkFilterReturn window_filter(GdkXEvent *xev, GdkEvent *event, void *userData) {
	// event goes unused
	(void) event;

	XEvent *xevent =(XEvent*) xev;
	CarbonTray *tray =(CarbonTray*) userData;

	if (xevent->type == ClientMessage) {
		XClientMessageEvent *xclient =(XClientMessageEvent*) xevent;

		if (xclient->message_type == tray->opcodeAtom) {
			switch(xclient->data.l[1]) {
				case TRAY_REQUEST_DOCK:
					handle_dock_request(tray, xclient);
					return GDK_FILTER_REMOVE;
				case TRAY_BEGIN_MESSAGE:
					handle_message_begin(tray, xclient);
					return GDK_FILTER_REMOVE;
				case TRAY_CANCEL_MESSAGE:
					handle_message_cancel(tray, xclient);
					return GDK_FILTER_REMOVE;
			}
		} else if (xclient->message_type == tray->dataAtom) {
			handle_message_data(tray, xclient);
			return GDK_FILTER_REMOVE;
		}
	} else if (xevent->type == SelectionClear) {
		carbon_tray_unregister(tray);
	}

	return GDK_FILTER_CONTINUE;
}

static void handle_dock_request(CarbonTray *tray, XClientMessageEvent *xevent) {
	Window window =(unsigned long) xevent->data.l[2];

	/* check if we already have this window */
	if (g_hash_table_lookup(tray->socketTable, GUINT_TO_POINTER(window)) != NULL) {
		handle_undock_request(g_hash_table_lookup(tray->socketTable, GUINT_TO_POINTER(window)), tray);
	}

	/* create the socket */
	GdkScreen *screen = gtk_widget_get_screen(tray->invisible);
	CarbonChild *child = carbon_child_new(tray->iconSize, screen, window);
	GtkWidget *socket = GTK_WIDGET(child);
	if (socket == NULL)
		return;

	// networkmanager applet should be packed at the end
	if (strcmp(child->wmclass, "Nm-applet") == 0) {
		gtk_box_pack_end(GTK_BOX(tray->box), socket, FALSE, FALSE, 0);
	} else {
		gtk_box_pack_start(GTK_BOX(tray->box), socket, FALSE, FALSE, 0);
		gtk_box_reorder_child(GTK_BOX(tray->box), socket, 0);
	}
	
	if (GTK_IS_WINDOW(gtk_widget_get_toplevel(socket))) {
		g_signal_connect(G_OBJECT(socket), "plug-removed", G_CALLBACK(handle_undock_request), tray);
		gtk_socket_add_id(GTK_SOCKET(socket), window);
		g_hash_table_insert(tray->socketTable, GUINT_TO_POINTER(window), socket);
		gtk_widget_show_all(GTK_WIDGET(socket));
	} else {
		g_warning("No parent window set, destroying socket");
		gtk_container_remove(GTK_CONTAINER(tray->box), GTK_WIDGET(socket));
		gtk_widget_destroy(socket);
	}

	// if embedding failed, just destroy the socket
	if (!gtk_socket_get_plug_window(GTK_SOCKET(socket))) {
		handle_undock_request(GTK_SOCKET(socket), tray);
	}
}

static bool handle_undock_request(GtkSocket *socket, void *userData) {
	CarbonTray *tray = CARBON_TRAY(userData);
	Window window = CARBON_CHILD(socket)->iconWindow;

	gtk_container_remove(GTK_CONTAINER(tray->box), GTK_WIDGET(socket));
	g_hash_table_remove(tray->socketTable, GUINT_TO_POINTER(window));

	// destroys the socket
	return FALSE;
}

static void handle_message_begin(CarbonTray *tray, XClientMessageEvent *xevent) {
	GtkSocket *socket = g_hash_table_lookup(tray->socketTable, GUINT_TO_POINTER(xevent->window));
	if (socket == NULL)
		return;

	remove_message(tray, xevent);

	long timeout = xevent->data.l[2];
	long length = xevent->data.l[3];
	long id = xevent->data.l[4];

	if (length == 0) {
		g_signal_emit(tray, message_sent_signal, 0, socket, "", id, timeout);
	} else {
		CarbonMessage *message = &(CarbonMessage) {
			.window = xevent->window,
			.timeout = timeout,
			.length = length,
			.id = id,
			.remainingLength = length,
			.string = g_malloc((unsigned long) length + 1)
		};
		message->string[length] = '\0'; // always remember to null terminate

		tray->messages = g_slist_prepend(tray->messages, message);
	}
}

static void handle_message_data(CarbonTray *tray, XClientMessageEvent *xevent) {
	CarbonMessage *message;
	GSList *it;

	for(it = tray->messages; it != NULL; it = it->next) {
		message = it -> data;

		if (xevent->window == message->window) {
			long length = MIN(message->remainingLength, 20);
			memcpy((message->string + message->length - message->remainingLength), &xevent->data,(unsigned long) length);
			message->remainingLength -= length;

			if (message->remainingLength == 0) {
				GtkSocket *socket = g_hash_table_lookup(tray->socketTable, GUINT_TO_POINTER(message->window));

				if (socket != NULL) {
					g_signal_emit(tray, message_sent_signal, 0, socket, message->string, message->id, message->timeout);
				}

				tray->messages = g_slist_delete_link(tray->messages, it);
				free_message(message);
			}
		}
	}
}

static void handle_message_cancel(CarbonTray *tray, XClientMessageEvent *xevent) {
	remove_message(tray, xevent);
}

static void remove_message(CarbonTray *tray, XClientMessageEvent *xevent) {
	CarbonMessage *message;
	GSList *it;
	for(it = tray->messages; it != NULL; it = it->next) {
		message = it->data;

		if (xevent->window == message->window && xevent->data.l[4] == message->id) {
			tray->messages = g_slist_delete_link(tray->messages, it);
			free_message(message);
			break;
		}
	}
}

static void free_message(CarbonMessage *message) {
	g_free(message->string);
	g_slice_free(CarbonMessage, message);
}

static void set_xproperties(CarbonTray *tray) {
	GdkDisplay *display = gtk_widget_get_display(tray->invisible);
	GdkScreen *screen = gtk_invisible_get_screen(GTK_INVISIBLE(tray->invisible));	

	// set the visual

	GdkVisual *visual = gdk_screen_get_rgba_visual(screen);

	Visual *xvisual;
	if (visual != NULL) {
		xvisual = GDK_VISUAL_XVISUAL(visual);
	} else {
		xvisual = GDK_VISUAL_XVISUAL(gdk_screen_get_system_visual(screen));
	}

	unsigned long data[1] = { XVisualIDFromVisual(xvisual) };
	Atom atom = gdk_x11_get_xatom_by_name_for_display(display, "_NET_SYSTEM_TRAY_VISUAL");
	XChangeProperty(GDK_DISPLAY_XDISPLAY(display),
					GDK_WINDOW_XID(gtk_widget_get_window(tray->invisible)),
					atom,
					XA_VISUALID, 32,
					PropModeReplace,
					(guchar*) &data, 1);

	// set the icon size

	data[0] = (unsigned int) tray->iconSize;
	atom = gdk_x11_get_xatom_by_name_for_display(display, "_NET_SYSTEM_TRAY_ICON_SIZE");
	XChangeProperty(GDK_DISPLAY_XDISPLAY(display),
                   	GDK_WINDOW_XID(gtk_widget_get_window(tray->invisible)),
                   	atom,
                   	XA_CARDINAL, 32,
                   	PropModeReplace,
                   	(guchar*) &data, 1);

	// set orientation

	data[0] = (unsigned int) gtk_orientable_get_orientation(GTK_ORIENTABLE(tray->box)) == GTK_ORIENTATION_HORIZONTAL ? 0 : 1;
	atom = gdk_x11_get_xatom_by_name_for_display(display, "_NET_SYSTEM_TRAY_ORIENTATION");
	XChangeProperty(GDK_DISPLAY_XDISPLAY(display),
					GDK_WINDOW_XID(gtk_widget_get_window(tray->invisible)),
					atom,
					XA_CARDINAL, 32,
					PropModeReplace,
					(guchar*) &data, 1);
}

static void draw_child(GtkWidget *widget, void *data) {
	CarbonDrawData *dt = (CarbonDrawData*) data;
	CarbonChild *child = CARBON_CHILD(widget);
	carbon_child_draw_on_tray(child, GTK_WIDGET(dt->box), dt->cr);
}

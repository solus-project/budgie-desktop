#ifndef __CARBONTRAY_CHILD_H__
#define __CARBONTRAY_CHILD_H__

#include <gtk/gtk.h>
#include <gtk/gtkx.h>
#include <stdbool.h>

typedef struct _CarbonChild {
	GtkSocket parent;

	int preferredWidth;
	int preferredHeight;
	Window iconWindow;

	char *wmclass;

	bool parentRelativeBg;
	bool isComposited;
} CarbonChild;

typedef struct _CarbonChildClass {
	GtkSocketClass parent_class;
} CarbonChildClass;



#define CARBON_TYPE_CHILD (carbon_child_get_type())
#define CARBON_CHILD(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), CARBON_TYPE_CHILD, CarbonChild))
#define CARBON_IS_CHILD(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CARBON_TYPE_CHILD))



GType carbon_child_get_type(void);

CarbonChild* carbon_child_new(int, GdkScreen*, Window);

void carbon_child_draw_on_tray(CarbonChild*, GtkWidget*, cairo_t*);

#endif

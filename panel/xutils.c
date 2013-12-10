#include "xutils.h"

static Atom
panel_atom_get (const char *atom_name)
{
	static GHashTable *atom_hash;
	Display           *xdisplay;
	Atom               retval;

	g_return_val_if_fail (atom_name != NULL, None);

	xdisplay = GDK_DISPLAY_XDISPLAY (gdk_display_get_default ());

	if (!atom_hash)
		atom_hash = g_hash_table_new_full (
				g_str_hash, g_str_equal, g_free, NULL);

	retval = GPOINTER_TO_UINT (g_hash_table_lookup (atom_hash, atom_name));
	if (!retval) {
		retval = XInternAtom (xdisplay, atom_name, FALSE);

		if (retval != None)
			g_hash_table_insert (atom_hash, g_strdup (atom_name),
					     GUINT_TO_POINTER (retval));
	}

	return retval;
}

void
xstuff_set_wmspec_strut (GdkWindow *window,
			 int        left,
			 int        right,
			 int        top,
			 int        bottom)
{
	long vals [4];
        
	vals [0] = left;
	vals [1] = right;
	vals [2] = top;
	vals [3] = bottom;

        XChangeProperty (GDK_WINDOW_XDISPLAY (window),
                         GDK_WINDOW_XID (window),
			 panel_atom_get ("_NET_WM_STRUT"),
                         XA_CARDINAL, 32, PropModeReplace,
                         (unsigned char *) vals, 4);
}

void
xstuff_delete_property (GdkWindow *window, const char *name)
{
	Display *xdisplay = GDK_WINDOW_XDISPLAY (window);
	Window   xwindow  = GDK_WINDOW_XID (window);

        XDeleteProperty (xdisplay, xwindow,
			 panel_atom_get (name));
}

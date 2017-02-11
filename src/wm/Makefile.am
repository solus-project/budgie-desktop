include $(top_srcdir)/common.mk

EXTRA_DIST = \
	budgie-wm.desktop.in \
	com.solus-project.budgie.wm.gschema.xml

gsettings_SCHEMAS = com.solus-project.budgie.wm.gschema.xml
@GSETTINGS_RULES@

applicationsdir = $(datadir)/applications
applications_DATA = \
	budgie-wm.desktop

bin_PROGRAMS = budgie-wm

budgie_wm_SOURCES = \
	core.c \
	main.c \
	plugin.h \
	plugin.c \
	plugin-private.h \
	util.h \
	impl/minimize.c \
	impl/unminimize.c \
	impl/map.c \
	impl/destroy.c \
	impl/workspaces.c \
	impl/tiling.c \
	impl/menus.c

budgie_wm_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_WM_CFLAGS) \
	$(DECLARATIONS) \
	$(AM_CFLAGS) \
	-DGNOME_DESKTOP_USE_UNSTABLE_API

if HAVE_CRANKY_MUTTER
budgie_wm_LDFLAGS = \
	-rpath $(MUTTER_TYPELIB_DIR)
endif

budgie_wm_LDADD = \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_WM_LIBS)

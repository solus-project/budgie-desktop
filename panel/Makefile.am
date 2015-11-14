-include $(top_srcdir)/common.mk

EXTRA_DIST =

panel_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/data --generate-dependencies $(top_srcdir)/data/arc-panel.gresource.xml)

BUILT_SOURCES = \
	arc-panel-resources.h \
	arc-panel-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# resources
arc-panel-resources.h: $(top_srcdir)/data/arc-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-header --c-name arc_panel $<

arc-panel-resources.c: $(top_srcdir)/data/arc-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-source --c-name arc_panel $<

bin_PROGRAMS = arc-panel

arc_panel_SOURCES = \
	arc-panel-resources.h \
	arc-panel-resources.c \
	main.vala \
	panel.vala \
	utils.vala \
	manager.vala 

arc_panel_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(GIO_UNIX_CFLAGS)

arc_panel_LDADD = \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS)

arc_panel_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	$(VALAFLAGS)

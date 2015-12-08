-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	panelconfig.h \
	panelconfig.vapi \
	arc-panel.desktop.in

SUBDIRS = \
	applets

applicationsdir = $(datadir)/applications
applications_DATA = \
	arc-panel.desktop

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
	manager.vala \
	panel.vala \
	popovers.vala \
	uuid.vala

arc_panel_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(UUID_CFLAGS) \
	$(DECLARATIONS)

arc_panel_LDADD = \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS) \
	$(LIBPEAS_LIBS) \
	$(UUID_LIBS) \
	${top_builddir}/plugin/libarc-plugin.la \
	${top_builddir}/lib/libtoplevel.la \
	${top_builddir}/raven/libraven.la

arc_panel_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libuuid \
	--pkg libpeas-gtk-1.0 \
	--pkg arc-1.0 \
	--pkg panelconfig \
	--pkg raven \
	--pkg toplevel \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/plugin \
	--vapidir=${top_srcdir}/panel \
	--vapidir=${top_srcdir}/raven \
	--vapidir=${top_srcdir}/lib \
	$(VALAFLAGS)

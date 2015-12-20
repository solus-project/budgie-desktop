-include $(top_srcdir)/common.mk

%.desktop: %.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

EXTRA_DIST = \
	panelconfig.h \
	panelconfig.vapi \
	arc-panel.desktop.in.in

@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_XML_NOMERGE_RULE@

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
	$(BUILT_SOURCES) \
	arc-panel.desktop \
	arc-panel.desktop.in

DISTCLEANFILES = \
	arc-panel.desktop \
	arc-panel.desktop.in

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
	$(ARC_BASE_CFLAGS) \
	$(ARC_PLUGIN_CFLAGS) \
	$(UUID_CFLAGS) \
	$(DECLARATIONS)

arc_panel_LDADD = \
	$(ARC_BASE_LIBS) \
	$(ARC_PLUGIN_LIBS) \
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

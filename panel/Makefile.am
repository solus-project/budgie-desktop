-include $(top_srcdir)/common.mk

%.desktop: %.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

EXTRA_DIST = \
	budgie-panel.desktop.in.in

@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_XML_NOMERGE_RULE@

SUBDIRS = \
	applets

applicationsdir = $(datadir)/applications
applications_DATA = \
	budgie-panel.desktop

panel_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/data --generate-dependencies $(top_srcdir)/data/budgie-panel.gresource.xml)

BUILT_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c

CLEANFILES = \
	$(BUILT_SOURCES) \
	budgie-panel.desktop \
	budgie-panel.desktop.in

DISTCLEANFILES = \
	budgie-panel.desktop \
	budgie-panel.desktop.in

# resources
budgie-panel-resources.h: $(top_srcdir)/data/budgie-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-header --c-name budgie_panel $<

budgie-panel-resources.c: $(top_srcdir)/data/budgie-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-source --c-name budgie_panel $<

bin_PROGRAMS = budgie-panel

budgie_panel_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c \
	main.vala \
	manager.vala \
	panel.vala \
	popovers.vala \
	uuid.vala \
	endsession.vala

budgie_panel_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(UUID_CFLAGS) \
	$(DECLARATIONS)

budgie_panel_LDADD = \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(UUID_LIBS) \
	${top_builddir}/config/libbudgie-config.la \
	${top_builddir}/plugin/libbudgie-plugin.la \
	${top_builddir}/lib/libtoplevel.la \
	${top_builddir}/libsession/libsession.la \
	${top_builddir}/raven/libraven.la \
	${top_builddir}/theme/libbudgietheme.la

budgie_panel_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libuuid \
	--pkg libpeas-gtk-1.0 \
	--pkg budgie-1.0 \
	--pkg budgie-config \
	--pkg raven \
	--pkg toplevel \
	--pkg libsession \
	--vapidir=${top_srcdir}/config \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/plugin \
	--vapidir=${top_srcdir}/panel \
	--vapidir=${top_srcdir}/raven \
	--vapidir=${top_srcdir}/lib \
	--vapidir=${top_srcdir}/libsession \
	--target-glib=2.38 \
	--gresources=${top_srcdir}/data/budgie-panel.gresource.xml \
	$(VALAFLAGS)

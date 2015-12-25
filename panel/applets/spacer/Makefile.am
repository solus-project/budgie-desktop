-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =

plugin_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/panel/applets/spacer  --generate-dependencies $(top_srcdir)/panel/applets/spacer/plugin.gresource.xml)

# resources
plugin-resources.h: $(top_srcdir)/panel/applets/spacer/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/panel/applets/spacer --generate-header --c-name budgie_menu $<

plugin-resources.c: $(top_srcdir)/panel/applets/spacer/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/panel/applets/spacer --generate-source --c-name budgie_menu $<

BUILT_SOURCES = \
	plugin-resources.h \
	plugin-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)


plugin_DATA += \
	SpacerApplet.plugin \
	com.solus-project.spacer.gschema.xml \
	plugin.gresource.xml

EXTRA_DIST += \
	$(plugin_DATA)

plugin_LTLIBRARIES = libspacerapplet.la

libspacerapplet_la_SOURCES = \
	SpacerApplet.vala \
	plugin-resources.h \
	plugin-resources.c

libspacerapplet_la_CFLAGS = \
	$(ARC_BASE_CFLAGS) \
	$(ARC_PLUGIN_CFLAGS) \
	$(DECLARATIONS)

libspacerapplet_la_LIBADD = \
	${top_builddir}/plugin/libarc-plugin.la \
	$(ARC_BASE_LIBS) \
	$(ARC_PLUGIN_LIBS) \
	$(TASKLIST_PLUGIN_LIBS)

libspacerapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libspacerapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg arc-1.0 \
	--vapidir=${top_srcdir}/plugin \
	--target-glib=2.38 \
	--gresources=${srcdir}/plugin.gresource.xml

gsettings_SCHEMAS = \
	com.solus-project.spacer.gschema.xml

@GSETTINGS_RULES@

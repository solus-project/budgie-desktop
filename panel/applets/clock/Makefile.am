-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =

%.plugin: %.plugin.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache


plugin_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/panel/applets/clock  --generate-dependencies $(top_srcdir)/panel/applets/clock/plugin.gresource.xml)

# resources
plugin-resources.h: $(top_srcdir)/panel/applets/clock/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/panel/applets/clock --generate-header --c-name budgie_menu $<

plugin-resources.c: $(top_srcdir)/panel/applets/clock/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/panel/applets/clock --generate-source --c-name budgie_menu $<

BUILT_SOURCES = \
	plugin-resources.h \
	plugin-resources.c

CLEANFILES = \
	$(BUILT_SOURCES) \
	ClockApplet.plugin

DISTCLEANFILES = \
	ClockApplet.plugin

plugin_DATA += \
	ClockApplet.plugin

EXTRA_DIST += \
	ClockApplet.plugin.in \
	com.solus-project.clock.gschema.xml \
	plugin.gresource.xml \
	settings.ui

plugin_LTLIBRARIES = libclockapplet.la

libclockapplet_la_SOURCES = \
	ClockApplet.vala \
	plugin-resources.h \
	plugin-resources.c

libclockapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(DECLARATIONS)

libclockapplet_la_LIBADD = \
	${top_builddir}/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS)

libclockapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libclockapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/plugin \
	--target-glib=2.38 \
	--gresources=${srcdir}/plugin.gresource.xml

gsettings_SCHEMAS = \
	com.solus-project.clock.gschema.xml

@GSETTINGS_RULES@

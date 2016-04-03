if ENABLE_ICON_TASKLIST_PLUGIN

-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =

%.plugin: %.plugin.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache


plugin_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/panel/applets/icon-tasklist  --generate-dependencies $(top_srcdir)/panel/applets/icon-tasklist/plugin.gresource.xml)

# resources
plugin-resources.h: $(top_srcdir)/panel/applets/icon-tasklist/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/panel/applets/icon-tasklist --generate-header --c-name budgie_menu $<

plugin-resources.c: $(top_srcdir)/panel/applets/icon-tasklist/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/panel/applets/icon-tasklist --generate-source --c-name budgie_menu $<

BUILT_SOURCES = \
	plugin-resources.h \
	plugin-resources.c

CLEANFILES = \
	$(BUILT_SOURCES) \
	IconTasklistApplet.plugin

DISTCLEANFILES = \
	IconTasklistApplet.plugin

plugin_DATA += \
	IconTasklistApplet.plugin

EXTRA_DIST += \
	IconTasklistApplet.plugin.in \
	com.solus-project.icon-tasklist.gschema.xml \
	plugin.gresource.xml \
	settings.ui

plugin_LTLIBRARIES = libicontasklistapplet.la

libicontasklistapplet_la_SOURCES = \
	IconTasklistApplet.vala \
	Buttons.vala \
	plugin-resources.h \
	plugin-resources.c

libicontasklistapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(ICON_TASKLIST_PLUGIN_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS)

libicontasklistapplet_la_LIBADD = \
	${top_builddir}/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(ICON_TASKLIST_PLUGIN_LIBS)

libicontasklistapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libicontasklistapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/plugin \
	--target-glib=2.38 \
	--gresources=${srcdir}/plugin.gresource.xml

gsettings_SCHEMAS = \
	com.solus-project.icon-tasklist.gschema.xml

@GSETTINGS_RULES@

endif

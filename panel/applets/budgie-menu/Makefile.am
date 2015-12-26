-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =


plugin_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/panel/applets/budgie-menu  --generate-dependencies $(top_srcdir)/panel/applets/budgie-menu/plugin.gresource.xml)

# resources
plugin-resources.h: $(top_srcdir)/panel/applets/budgie-menu/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/panel/applets/budgie-menu --generate-header --c-name budgie_menu $<

plugin-resources.c: $(top_srcdir)/panel/applets/budgie-menu/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/panel/applets/budgie-menu --generate-source --c-name budgie_menu $<

BUILT_SOURCES = \
	plugin-resources.h \
	plugin-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

plugin_DATA += \
	BudgieMenu.plugin

EXTRA_DIST += \
	$(plugin_DATA) \
	com.solus-project.budgie-menu.gschema.xml \
	plugin.resource.xml \
	settings.ui


plugin_LTLIBRARIES = libbudgiemenuapplet.la

libbudgiemenuapplet_la_SOURCES = \
	BudgieMenu.vala \
	BudgieMenuWindow.vala \
	plugin-resources.h \
	plugin-resources.c

libbudgiemenuapplet_la_CFLAGS = \
	$(ARC_BASE_CFLAGS) \
	$(ARC_PLUGIN_CFLAGS) \
	$(GMENU_CFLAGS) \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS)

libbudgiemenuapplet_la_LIBADD = \
	${top_builddir}/plugin/libarc-plugin.la \
	$(ARC_BASE_CFLAGS) \
	$(ARC_PLUGIN_CFLAGS) \
	$(GMENU_LIBS)

libbudgiemenuapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libbudgiemenuapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libgnome-menu-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg arc-1.0 \
	--vapidir=${top_srcdir}/plugin \
	--target-glib=2.38 \
	--gresources=${srcdir}/plugin.gresource.xml

gsettings_SCHEMAS = \
	com.solus-project.budgie-menu.gschema.xml

@GSETTINGS_RULES@

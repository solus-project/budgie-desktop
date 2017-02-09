include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =

%.plugin: %.plugin.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/src/panel/applets/places-indicator  --generate-dependencies $(top_srcdir)/src/panel/applets/places-indicator/plugin.gresource.xml)

# resources
plugin-resources.h: $(top_srcdir)/src/panel/applets/places-indicator/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/src/panel/applets/places-indicator --generate-header --c-name places_indicator $<

plugin-resources.c: $(top_srcdir)/src/panel/applets/places-indicator/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/src/panel/applets/places-indicator --generate-source --c-name places_indicator $<

BUILT_SOURCES = \
	plugin-resources.h \
	plugin-resources.c

CLEANFILES = \
	$(BUILT_SOURCES) \
	PlacesIndicator.plugin

DISTCLEANFILES = \
	PlacesIndicator.plugin

plugin_DATA += \
	PlacesIndicator.plugin

EXTRA_DIST += \
	com.solus-project.places-indicator.gschema.xml \
	plugin.gresource.xml \
	settings.ui \
	PlacesIndicator.plugin.in

plugin_LTLIBRARIES = libplacesindicator.la

libplacesindicator_la_SOURCES = \
	PlacesIndicator.vala \
	PlacesIndicatorWindow.vala \
	MessageRevealer.vala \
	PlacesSection.vala \
	ListItem.vala \
	VolumeItem.vala \
	MountItem.vala \
	PlaceItem.vala \
	MountHelper.vala \
	plugin-resources.h \
	plugin-resources.c

libplacesindicator_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(DECLARATIONS) \
	$(VALA_NOISY_FLAGS)

libplacesindicator_la_LIBADD = \
	${top_builddir}/src/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	-lm

libplacesindicator_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libplacesindicator_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg posix \
	--vapidir=${top_srcdir}/src/plugin \
	--vapidir=${top_srcdir}/vapi \
	--target-glib=2.38 \
	--gresources=${srcdir}/plugin.gresource.xml

gsettings_SCHEMAS = \
	com.solus-project.places-indicator.gschema.xml

@GSETTINGS_RULES@

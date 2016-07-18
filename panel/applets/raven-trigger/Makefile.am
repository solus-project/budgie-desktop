-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =

%.plugin: %.plugin.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

CLEANFILES = \
	RavenTriggerApplet.plugin

DISTCLEANFILES = \
	RavenTriggerApplet.plugin

plugin_DATA += \
	RavenTriggerApplet.plugin

EXTRA_DIST += \
	RavenTriggerApplet.plugin.in

plugin_LTLIBRARIES = libraventriggerapplet.la

libraventriggerapplet_la_SOURCES = \
	RavenTriggerApplet.vala

libraventriggerapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(DECLARATIONS)

libraventriggerapplet_la_LIBADD = \
	${top_builddir}/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS)

libraventriggerapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libraventriggerapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/plugin

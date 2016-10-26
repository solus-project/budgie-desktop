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

CLEANFILES = \
	$(BUILT_SOURCES) \
	IconTasklistApplet.plugin

DISTCLEANFILES = \
	IconTasklistApplet.plugin

plugin_DATA += \
	IconTasklistApplet.plugin

EXTRA_DIST += \
	IconTasklistApplet.plugin.in \
	com.solus-project.icon-tasklist.gschema.xml

plugin_LTLIBRARIES = libicontasklistapplet.la

libicontasklistapplet_la_SOURCES = \
	AppSystem.vala \
	IconTasklistApplet.vala \
	Buttons.vala

libicontasklistapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(ICON_TASKLIST_PLUGIN_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS)

libicontasklistapplet_la_LIBADD = \
	${top_builddir}/src/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(ICON_TASKLIST_PLUGIN_LIBS)

libicontasklistapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libicontasklistapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gdk-x11-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/src/plugin

gsettings_SCHEMAS = \
	com.solus-project.icon-tasklist.gschema.xml

@GSETTINGS_RULES@

endif

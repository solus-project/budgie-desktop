if ENABLE_TRAY_PLUGIN

include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =

%.plugin: %.plugin.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

CLEANFILES = \
	TrayApplet.plugin

DISTCLEANFILES = \
	TrayApplet.plugin

plugin_DATA += \
	TrayApplet.plugin

EXTRA_DIST += \
	TrayApplet.plugin.in

plugin_LTLIBRARIES = libtrayapplet.la

libtrayapplet_la_SOURCES = \
	TrayApplet.vala

libtrayapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(NATRAY_CFLAGS) \
	$(DECLARATIONS) \
	-I${top_srcdir}/src/imports/natray \
	$(VALA_NOISY_FLAGS)

libtrayapplet_la_LIBADD = \
	${top_builddir}/src/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(NATRAY_LIBS) \
	${top_builddir}/src/imports/natray/libnatray.la

libtrayapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libtrayapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg natray-1.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/src/plugin \
	--vapidir=${top_srcdir}/src/imports/natray

endif

if ENABLE_SHOW_DESKTOP_PLUGIN

-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =

%.plugin: %.plugin.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache


plugin_DATA += \
	ShowDesktopApplet.plugin

EXTRA_DIST += \
	ShowDesktopApplet.plugin.in

plugin_LTLIBRARIES = libshowdesktopapplet.la

libshowdesktopapplet_la_SOURCES = \
	ShowDesktopApplet.vala

libshowdesktopapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(SHOW_DESKTOP_PLUGIN_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS)

libshowdesktopapplet_la_LIBADD = \
	${top_builddir}/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(SHOW_DESKTOP_PLUGIN_LIBS)

libshowdesktopapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libshowdesktopapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/plugin

endif

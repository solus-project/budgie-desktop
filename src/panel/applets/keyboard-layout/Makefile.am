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
	KeyboardLayoutApplet.plugin

DISTCLEANFILES = \
	KeyboardLayoutApplet.plugin

plugin_DATA += \
	KeyboardLayoutApplet.plugin

EXTRA_DIST += \
	KeyboardLayoutApplet.plugin.in

plugin_LTLIBRARIES = libkeyboardlayoutapplet.la

libkeyboardlayoutapplet_la_SOURCES = \
	KeyboardLayoutApplet.vala

libkeyboardlayoutapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(KEYBOARD_INDICATOR_CFLAGS) \
	-DGNOME_DESKTOP_USE_UNSTABLE_API \
	$(DECLARATIONS)

libkeyboardlayoutapplet_la_LIBADD = \
	${top_builddir}/src/plugin/libbudgie-plugin.la \
	$(KEYBOARD_INDICATOR_LIBS) \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS)

libkeyboardlayoutapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libkeyboardlayoutapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg gnome-desktop-3.0 \
	--pkg gsettings-desktop-schemas \
	--pkg ibus-1.0 \
	--vapidir=${top_srcdir}/src/plugin \
	--vapidir=${top_srcdir}/vapi

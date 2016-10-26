if ENABLE_STATUS_PLUGIN

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
	UserIndicator.plugin

DISTCLEANFILES = \
	UserIndicator.plugin

plugin_DATA += \
	UserIndicator.plugin

EXTRA_DIST += \
	UserIndicator.plugin.in

plugin_LTLIBRARIES = libuserindicator.la

libuserindicator_la_SOURCES = \
    DBusInterfaces.vala \
    UserIndicator.vala \
    UserIndicatorWindow.vala

libuserindicator_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(STATUS_PLUGIN_CFLAGS) \
	$(GVC_CFLAGS) \
	$(DECLARATIONS)

libuserindicator_la_LIBADD = \
	${top_builddir}/src/plugin/libbudgie-plugin.la \
	${top_builddir}/gvc/libgvc.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(GVC_LIBS) \
	$(STATUS_PLUGIN_LIBS) \
	-lm

libuserindicator_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libuserindicator_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gvc-1.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg posix \
	--pkg accountsservice \
	--vapidir=${top_srcdir}/src/plugin \
	--vapidir=${top_srcdir}/vapi

endif

if ENABLE_TASKLIST_PLUGIN

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
	TasklistApplet.plugin

DISTCLEANFILES = \
	TasklistApplet.plugin

plugin_DATA += \
	TasklistApplet.plugin

EXTRA_DIST += \
	TasklistApplet.plugin.in

plugin_LTLIBRARIES = libtasklistapplet.la

libtasklistapplet_la_SOURCES = \
	TasklistApplet.vala

libtasklistapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(TASKLIST_PLUGIN_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS) \
	$(VALA_NOISY_FLAGS)

libtasklistapplet_la_LIBADD = \
	${top_builddir}/src/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(TASKLIST_PLUGIN_LIBS)

libtasklistapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libtasklistapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/src/plugin

endif

if ENABLE_WORKSPACES_PLUGIN

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
	WorkspacesApplet.plugin

DISTCLEANFILES = \
	WorkspacesApplet.plugin


plugin_DATA += \
	WorkspacesApplet.plugin

EXTRA_DIST += \
	WorkspacesApplet.plugin.in

plugin_LTLIBRARIES = libworkspacesapplet.la

libworkspacesapplet_la_SOURCES = \
	WorkspacesApplet.vala

libworkspacesapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(WORKSPACES_PLUGIN_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS)

libworkspacesapplet_la_LIBADD = \
	${top_builddir}/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(WORKSPACES_PLUGIN_LIBS)

libworkspacesapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libworkspacesapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/plugin

endif

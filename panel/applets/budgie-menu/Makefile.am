-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =


plugin_DATA += \
	BudgieMenu.plugin

EXTRA_DIST += \
	$(plugin_DATA)

plugin_LTLIBRARIES = libbudgiemenuapplet.la

libbudgiemenuapplet_la_SOURCES = \
	BudgieMenu.vala \
	BudgieMenuWindow.vala

libbudgiemenuapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(GMENU_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS)

libbudgiemenuapplet_la_LIBADD = \
	${top_builddir}/plugin/libarc-plugin.la \
	$(GTK3_LIBS) \
	$(GMENU_LIBS) \
	$(GIO_UNIX_LIBS) \
	$(LIBPEAS_LIBS)

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
	--vapidir=${top_srcdir}/plugin

-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop
plugin_DATA =



plugin_DATA += \
	BudgieMenu.plugin

EXTRA_DIST += \
	$(plugin_DATA)

pkglib_LTLIBRARIES += libbudgiemenuapplet.la

libbudgiemenuapplet_la_SOURCES = \
	BudgieMenu.vala \
	BudgieMenuWindow.vala

libbudgiemenuapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(GMENU_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE


libbudgiemenuapplet_la_LIBADD = \
	${top_builddir}/widgets/libbudgiewidgets.la \
	${top_builddir}/budgie-plugin/libbudgie-plugin.la \
	$(GTK3_LIBS) \
	$(GMENU_LIBS) \
	$(GIO_UNIX_LIBS) \
	$(LIBPEAS_LIBS)

libbudgiemenuapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(AM_LDFLAGS)

libbudgiemenuapplet_la_VALAFLAGS = \
	--vapidir=${top_builddir}/budgie-plugin \
	--vapidir=${top_builddir}/widgets \
	--pkg gtk+-3.0 \
	--pkg libgnome-menu-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg BudgieWidgets

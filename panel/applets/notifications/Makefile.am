-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop
plugin_DATA =



plugin_DATA += \
	NotificationsApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

pkglib_LTLIBRARIES += libnotificationsapplet.la

libnotificationsapplet_la_SOURCES = \
	NotificationsApplet.vala

libnotificationsapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(LIBPEAS_CFLAGS)

libnotificationsapplet_la_LIBADD = \
	${top_builddir}/widgets/libbudgiewidgets.la \
	${top_builddir}/budgie-plugin/libbudgie-plugin.la \
	$(GTK3_LIBS) \
	$(LIBPEAS_LIBS)

libnotificationsapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(AM_LDFLAGS)

libnotificationsapplet_la_VALAFLAGS = \
	--vapidir=${top_builddir}/budgie-plugin \
	--vapidir=${top_builddir}/widgets \
	--pkg gtk+-3.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg BudgieWidgets

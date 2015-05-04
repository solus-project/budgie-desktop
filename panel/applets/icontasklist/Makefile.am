-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop
plugin_DATA =

plugin_DATA += \
	IconTasklistApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

pkglib_LTLIBRARIES += libicontasklistapplet.la

libicontasklistapplet_la_SOURCES = \
	IconTasklistApplet.vala

libicontasklistapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	$(WNCK3_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(GEE_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE

libicontasklistapplet_la_LIBADD = \
	${top_builddir}/budgie-plugin/libbudgie-plugin.la \
	${top_srcdir}/widgets/libbudgiewidgets.la \
	$(GTK3_LIBS) \
	$(LIBPEAS_LIBS) \
	$(WNCK3_LIBS) \
	$(GIO_UNIX_LIBS) \
	$(GEE_LIBS)

libicontasklistapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(AM_LDFLAGS)

libicontasklistapplet_la_VALAFLAGS = \
	--vapidir=${top_builddir}/budgie-plugin \
	--vapidir=${top_builddir}/ \
	--vapidir=${top_srcdir}/widgets \
	--pkg gtk+-3.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg libwnck-3.0 \
	--pkg budgie-1.0 \
	--pkg gio-unix-2.0 \
	--pkg BudgieWidgets \
	$(VALAFLAGS) \
	--pkg gee-0.8


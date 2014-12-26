-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop
plugin_DATA =



plugin_DATA += \
	StatusApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

pkglib_LTLIBRARIES += libstatusapplet.la

libstatusapplet_la_SOURCES = \
	StatusApplet.vala \
	SoundIndicator.vala \
	PowerIndicator.vala \
	MprisWidget.vala \
	mpris/MprisClient.vala \
	mpris/MprisGui.vala \
	UserClient.vala

libstatusapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(GVC_CFLAGS) \
	$(UPOWER_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	$(GIO_UNIX_CFLAGS)

libstatusapplet_la_LIBADD = \
	${top_builddir}/widgets/libbudgiewidgets.la \
	${top_builddir}/budgie-plugin/libbudgie-plugin.la \
	${top_builddir}/gvc/libgvc.la \
	$(GTK3_LIBS) \
	$(UPOWER_LIBS) \
	$(LIBPEAS_LIBS) \
	$(GIO_UNIX_LIBS)

libstatusapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(AM_LDFLAGS)

libstatusapplet_la_VALAFLAGS = \
	--vapidir=${top_builddir}/budgie-plugin \
	--vapidir=${top_builddir}/widgets \
	--vapidir=${top_srcdir} \
	$(VALAFLAGS) \
	--pkg gtk+-3.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg BudgieWidgets \
	--pkg libpulse \
	--pkg gvc-1.0 \
	--pkg upower-glib-1.0 \
	--pkg gio-unix-2.0


dist-hook:
	cd $(distdir) && \
	rm $(libstatusapplet_la_SOURCES:.vala=.c) libstatusapplet_la_vala.stamp

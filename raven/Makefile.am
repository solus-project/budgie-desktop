-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	raven.vapi

CLEANFILES = \
	$(BUILT_SOURCES)


lib_LTLIBRARIES = libraven.la

libraven_la_SOURCES = \
	raven.vala \
	powerstrip.vala \
	mpris/MprisClient.vala \
	mpris/MprisGui.vala \
	mpris/MprisWidget.vala

libraven_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(DECLARATIONS)

libraven_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS) \
	${top_builddir}/lib/libtoplevel.la \
	${top_builddir}/plugin/libarc-plugin.la

libraven_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg arc-1.0 \
	--pkg toplevel \
	-H ArcRaven.h \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/plugin \
	--vapidir=${top_srcdir}/lib \
	$(VALAFLAGS)

nodist_include_HEADERS = \
	ArcRaven.h

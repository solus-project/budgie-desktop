-include $(top_srcdir)/common.mk


CLEANFILES = \
	$(BUILT_SOURCES)


lib_LTLIBRARIES = libraven.la

libraven_la_SOURCES = \
	raven.vala

libraven_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(DECLARATIONS)

libraven_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS) \
	${top_builddir}/plugin/libarc-plugin.la

libraven_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg arc-1.0 \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/plugin \
	$(VALAFLAGS)

-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	toplevel.vapi

noinst_LTLIBRARIES = libtoplevel.la

libtoplevel_la_SOURCES = \
	animation.vala \
	toplevel.vala \
	shadow.vala \
	manager.vala

libtoplevel_la_CFLAGS = \
	$(ARC_BASE_CFLAGS) \
	$(DECLARATIONS)

libtoplevel_la_LIBADD = \
	$(ARC_BASE_LIBS)

libtoplevel_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	-H ArcToplevel.h \
	$(VALAFLAGS)

nodist_include_HEADERS = \
	ArcToplevel.h

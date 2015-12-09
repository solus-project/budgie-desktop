-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	arc-wm.desktop.in

applicationsdir = $(datadir)/applications
applications_DATA = \
	arc-wm.desktop

bin_PROGRAMS = arc-wm

arc_wm_SOURCES = \
	main.vala

arc_wm_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(MUTTER_CFLAGS) \
	$(DECLARATIONS)

arc_wm_LDADD = \
	$(GOBJECT_LIBS) \
	$(MUTTER_LIBS)

arc_wm_VALAFLAGS = \
	--pkg gio-unix-2.0 \
	--pkg libmutter \
	--vapidir=${top_srcdir}/vapi \
	$(VALAFLAGS)

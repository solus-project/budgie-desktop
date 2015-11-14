-include $(top_srcdir)/common.mk

EXTRA_DIST =

bin_PROGRAMS = arc-panel

arc_panel_SOURCES = \
	main.vala \
	panel.vala \
	utils.vala \
	manager.vala 

arc_panel_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(GIO_UNIX_CFLAGS)

arc_panel_LDADD = \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS)

arc_panel_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	$(VALAFLAGS)

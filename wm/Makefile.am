-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	arc-wm.desktop.in \
	com.solus-project.arc.wm.gschema.xml

gsettings_SCHEMAS = com.solus-project.arc.wm.gschema.xml
@GSETTINGS_RULES@

applicationsdir = $(datadir)/applications
applications_DATA = \
	arc-wm.desktop

bin_PROGRAMS = arc-wm

arc_wm_SOURCES = \
	background.vala \
	main.vala \
	keyboard.vala \
	wm.vala

arc_wm_CFLAGS = \
	$(ARC_BASE_CFLAGS) \
	$(ARC_WM_CFLAGS) \
	$(DECLARATIONS) \
	-DGNOME_DESKTOP_USE_UNSTABLE_API

arc_wm_LDADD = \
	$(ARC_BASE_LIBS) \
	$(ARC_WM_LIBS)

arc_wm_VALAFLAGS = \
	--pkg gio-unix-2.0 \
	--pkg libmutter \
	--pkg gsettings-desktop-schemas \
	--pkg gnome-desktop-3.0 \
	--vapidir=${top_srcdir}/vapi \
	$(VALAFLAGS)

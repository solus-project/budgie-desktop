-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	budgie-wm.desktop.in \
	com.solus-project.budgie.wm.gschema.xml

gsettings_SCHEMAS = com.solus-project.budgie.wm.gschema.xml
@GSETTINGS_RULES@

applicationsdir = $(datadir)/applications
applications_DATA = \
	budgie-wm.desktop

bin_PROGRAMS = budgie-wm

budgie_wm_SOURCES = \
	background.vala \
	main.vala \
	keyboard.vala \
	ibus.vala \
	shim.vala \
	windowmenu.vala \
	wm.vala

budgie_wm_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_WM_CFLAGS) \
	$(DECLARATIONS) \
	-DGNOME_DESKTOP_USE_UNSTABLE_API

if HAVE_CRANKY_MUTTER
budgie_wm_LDFLAGS = \
	-rpath $(MUTTER_TYPELIB_DIR)
endif

budgie_wm_LDADD = \
	${top_builddir}/config/libbudgie-config.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_WM_LIBS)

budgie_wm_VALAFLAGS = \
	--pkg gio-unix-2.0 \
	--pkg libmutter \
	--pkg gsettings-desktop-schemas \
	--pkg gnome-desktop-3.0 \
	--pkg budgie-config \
	--pkg ibus-1.0 \
	--vapidir=${top_srcdir}/config \
	--vapidir=${top_srcdir}/vapi \
	$(VALAFLAGS)

-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-panel

budgie_panel_SOURCES = \
	../data/budgie-panel-resources.h \
	../data/budgie-panel-resources.c \
	common/budgie-popover.h \
	common/budgie-popover.c \
	panel-applet.h \
	panel-applet.c \
	icon-tasklist.h \
	icon-tasklist.c \
	applets/clock-applet.h \
	applets/clock-applet.c \
	applets/menu-applet.h \
	applets/menu-applet.c \
	applets/menu-window.h \
	applets/menu-window.c \
	applets/power-applet.c \
	applets/power-applet.h \
	applets/sound-applet.c \
	applets/sound-applet.h \
	applets/windowlist-applet.h \
	applets/windowlist-applet.c \
	budgie-panel.c \
	budgie-panel.h \
	xutils.h \
	xutils.c \
	budgie-panel-main.c

budgie_panel_CFLAGS = \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(WNCK3_CFLAGS) \
	$(UPOWER_CFLAGS) \
	$(X11_CFLAGS) \
	$(GMENU_CFLAGS) \
	$(AM_CFLAGS)

budgie_panel_LDADD = \
	../gvc/libgvc.la \
	-lm \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS) \
	$(WNCK3_LIBS) \
	$(UPOWER_LIBS) \
	$(X11_LIBS) \
	$(GMENU_LIBS)

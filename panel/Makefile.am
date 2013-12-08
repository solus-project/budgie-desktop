-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-panel

budgie_panel_SOURCES = \
	applets/power-applet.c \
	applets/power-applet.h \
	budgie-panel.c \
	budgie-panel.h \
	budgie-panel-main.c

budgie_panel_CFLAGS = \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(WNCK3_CFLAGS) \
	$(AM_CFLAGS)

budgie_panel_LDADD = \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS) \
	$(WNCK3_LIBS)

-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-panel

budgie_panel_SOURCES = \
	../data/budgie-panel-resources.h \
	../data/budgie-panel-resources.c \
	BudgiePanel.vala

budgie_panel_CFLAGS = \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(WNCK3_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	$(GMENU_CFLAGS)

budgie_panel_LDADD = \
	../gvc/libgvc.la \
	../widgets/libbudgiewidgets.la \
	-lm \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS) \
	$(WNCK3_LIBS) \
	$(LIBPEAS_LIBS) \
	$(GMENU_LIBS) \
	../budgie-plugin/libbudgie-plugin.la

budgie_panel_VALAFLAGS = \
	--vapidir=../budgie-plugin \
	--pkg gtk+-3.0 \
	--pkg libgnome-menu-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0

SUBDIRS = \
	applets

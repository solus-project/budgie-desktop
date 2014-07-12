-include $(top_srcdir)/common.mk

bin_PROGRAMS = rundialog

rundialog_SOURCES = \
	RunDialog.vala \
	../data/budgie-run-dialog-resources.c

rundialog_CFLAGS = \
	$(GTK3_CFLAGS) \
	$(GMENU_CFLAGS) \
	$(GEE_CFLAGS) \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE

rundialog_LDADD = \
	$(GTK3_LIBS) \
	$(GEE_LIBS) \
	$(GMENU_LIBS)

rundialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libgnome-menu-3.0 \
	--pkg gio-unix-2.0 \
	--pkg gee-1.0

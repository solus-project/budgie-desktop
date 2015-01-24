-include $(top_srcdir)/common.mk

if BUILD_WM
bin_PROGRAMS = budgie-wm

budgie_wm_SOURCES = \
	plugin.h \
	core.c \
	legacy.h \
	legacy.c \
	impl.h \
	impl/map.c \
	impl/destroy.c \
	impl/minimize.c \
	impl/tabs.c \
	ui/background.h \
	ui/background.c \
	budgie-wm.c

budgie_wm_CFLAGS = \
	$(MUTTER_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(AM_CFLAGS)

budgie_wm_LDADD = \
	$(MUTTER_LIBS) \
	$(GIO_UNIX_LIBS)

endif

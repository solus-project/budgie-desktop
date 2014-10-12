-include $(top_srcdir)/common.mk

if BUILD_WM

bin_PROGRAMS = budgie-wm

budgie_wm_SOURCES = \
	plugin.h \
	plugin.c \
	budgie-wm.c

budgie_wm_CFLAGS = \
	$(MUTTER_CFLAGS) \
	$(AM_CFLAGS)

budgie_wm_LDADD = \
	$(MUTTER_LIBS)

endif

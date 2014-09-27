-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-wm

if HAVE_MUTTER_314
budgie_wm_SOURCES = \
	plugin.h \
	plugin_314.c \
	budgie-wm.c
else
budgie_wm_SOURCES = \
	plugin.h \
	plugin.c \
	budgie-wm.c
endif

EXTRA_DIST = \
	plugin.c \
	plugin_314.c

budgie_wm_CFLAGS = \
	$(MUTTER_CFLAGS) \
	$(AM_CFLAGS)

budgie_wm_LDADD = \
	$(MUTTER_LIBS)

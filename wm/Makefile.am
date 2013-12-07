-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-wm

budgie_wm_SOURCES = \
	plugin.c \
	budgie-wm.c

budgie_wm_CFLAGS = \
	$(MUTTER_CFLAGS) \
	$(AM_CFLAGS)

budgie_wm_LDADD = \
	$(MUTTER_LIBS)

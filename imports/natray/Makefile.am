if ENABLE_NATRAY

-include $(top_srcdir)/common.mk

noinst_LTLIBRARIES = libnatray.la

libnatray_la_SOURCES = \
		na-tray.c \
		na-tray.h \
		na-tray-child.c \
		na-tray-child.h \
		na-tray-manager.c \
		na-tray-manager.h \
		fixedtip.c \
		fixedtip.h

libnatray_la_CFLAGS = \
		$(NATRAY_CFLAGS)

libnatray_la_la_LIBADD = \
		$(NATRAY_LIBS)

EXTRA_DIST = \
		natray-1.0.vapi

endif

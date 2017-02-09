include $(top_srcdir)/common.mk


EXTRA_DIST = \
		natray-1.0.vapi
		
if ENABLE_NATRAY

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
		$(NATRAY_CFLAGS) \
		$(AM_CFLAGS)

libnatray_la_LIBADD = \
		$(NATRAY_LIBS)

endif

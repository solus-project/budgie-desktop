-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-session

EXTRA_DIST = \
	org.freedesktop.login1.xml

budgie_session_SOURCES = \
	budgie-session.c \
	budgie-session-dialog.h \
	budgie-session-dialog.c \
	sd_logind_proxy.c

budgie_session_CFLAGS = \
	$(GIO_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(AM_CFLAGS)

budgie_session_LDADD = \
	$(GIO_LIBS) \
	$(GIO_UNIX_LIBS) \
	$(GTK3_LIBS)

sd_logind_proxy.h: org.freedesktop.login1.xml
	gdbus-codegen --generate-c-code sd_logind_proxy \
	--c-namespace SdLogin \
	--c-generate-object-manager \
	--interface-prefix org.freedesktop.login1 \
	$<

BUILT_SOURCES = \
	sd_logind_proxy.h

CLEANFILES = \
	$(BUILT_SOURCES) \
	sd_logind_proxy.c

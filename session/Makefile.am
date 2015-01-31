-include $(top_srcdir)/common.mk

dialog_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/data --generate-dependencies $(top_srcdir)/data/session-dialog.gresource.xml)

BUILT_SOURCES = \
	budgie-session-dialog-resources.h \
	budgie-session-dialog-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# Resources
budgie-session-dialog-resources.h: $(top_srcdir)/data/session-dialog.gresource.xml $(dialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-header --c-name budgie_session_dialog $<

budgie-session-dialog-resources.c: $(top_srcdir)/data/session-dialog.gresource.xml $(dialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-source --c-name budgie_session_dialog $<


bin_PROGRAMS = budgie-session \
	budgie-session-dialog

EXTRA_DIST = \
	org.freedesktop.login1.xml \
	sessionconfig.h \
	sessionconfig.vapi

noinst_LTLIBRARIES = libsdloginproxy.la

libsdloginproxy_la_SOURCES = \
	sd_logind_proxy.c \
	sd_logind_proxy.h

libsdloginproxy_la_CFLAGS = \
	$(GIO_UNIX_CFLAGS)

libsdloginproxy_la_LIBADD = \
	$(GIO_UNIX_LIBS)

budgie_session_SOURCES = \
	BudgieSession.vala

budgie_session_CFLAGS = \
	$(GIO_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(GEE_CFLAGS) \
	-DDATADIR=\"$(datadir)/\"

budgie_session_LDADD = \
	$(GIO_LIBS) \
	$(GIO_UNIX_LIBS) \
	$(GEE_LIBS)

budgie_session_VALAFLAGS = \
	--pkg gio-unix-2.0 \
	--pkg gee-0.8 \
	--pkg posix \
	--vapidir=. \
	--pkg sessionconfig

budgie_session_dialog_SOURCES = \
	budgie-session-dialog-resources.h \
	budgie-session-dialog-resources.c \
	budgie-session-dialog.h \
	budgie-session-dialog.c \
	budgie-session-dialog-main.c

budgie_session_dialog_CFLAGS = \
	$(GIO_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(AM_CFLAGS)

budgie_session_dialog_LDADD = \
	$(GIO_LIBS) \
	$(GIO_UNIX_LIBS) \
	$(GTK3_LIBS) \
	libsdloginproxy.la

sd_logind_proxy.h: org.freedesktop.login1.xml
	gdbus-codegen --generate-c-code sd_logind_proxy \
	--c-namespace SdLogin \
	--c-generate-object-manager \
	--interface-prefix org.freedesktop.login1 \
	$<

sd_logind_proxy.c:

BUILT_SOURCES += \
	sd_logind_proxy.h \
	sd_logind_proxy.c

CLEANFILES += \
	$(BUILT_SOURCES) \
	sd_logind_proxy.c


dist-hook:
	cd $(distdir) && \
	rm $(budgie_session_SOURCES:.vala=.c) budgie_session_vala.stamp

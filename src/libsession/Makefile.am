-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	libsession.vapi

noinst_LTLIBRARIES = \
	libsession.la

libsession_la_SOURCES = \
	libsession.vala

libsession_la_CFLAGS = \
	$(LIBSESSION_CFLAGS)

libsession_la_LIBADD = \
	$(LIBSESSION_LIBS)

libsession_la_VALAFLAGS = \
	--pkg gio-unix-2.0 \
	-H BudgieSession.h \
	$(VALAFLAGS)

nodist_include_HEADERS = \
	BudgieSession.h

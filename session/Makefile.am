-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-session

EXTRA_DIST = \
	org.freedesktop.login1.xml

budgie_session_SOURCES = \
	budgie-session.c

budgie_session_CFLAGS = \
	$(GIO_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(AM_CFLAGS)

budgie_session_LDADD = \
	$(GIO_LIBS) \
	$(GIO_UNIX_LIBS)

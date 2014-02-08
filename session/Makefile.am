-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-session

budgie_session_SOURCES = \
	budgie-session.c

budgie_session_CFLAGS = \
	$(GIO_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(AM_CFLAGS)

budgie_session_LDADD = \
	$(GIO_LIBS) \
	$(GIO_UNIX_LIBS)

-include $(top_srcdir)/common.mk

%.desktop: %.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

CLEANFILES = \
	$(BUILT_SOURCES) \
	budgie-daemon.desktop \
	budgie-daemon.desktop.in

DISTCLEANFILES = \
	budgie-daemon.desktop \
	budgie-daemon.desktop.in


@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_XML_NOMERGE_RULE@

EXTRA_DIST = \
	budgie-daemon.desktop.in.in

bin_PROGRAMS = \
	budgie-daemon

budgie_daemon_SOURCES = \
	main.vala

budgie_daemon_CFLAGS = \
	$(BUDGIE_DAEMON_CFLAGS) \
	$(DECLARATIONS)

budgie_daemon_LDADD = \
	$(BUDGIE_DAEMON_LIBS) \
	${top_builddir}/libsession/libsession.la \
	${top_builddir}/theme/libbudgietheme.la


applicationsdir = $(datadir)/applications
applications_DATA = \
	budgie-daemon.desktop

budgie_daemon_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg theme \
	--pkg libsession \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/theme \
	--vapidir=${top_srcdir}/libsession

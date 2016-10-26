-include $(top_srcdir)/common.mk

daemon_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/src/daemon --generate-dependencies $(top_srcdir)/src/daemon/budgie-daemon.gresource.xml)

%.desktop: %.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

BUILT_SOURCES = \
	budgie-daemon-resources.h \
	budgie-daemon-resources.c

CLEANFILES = \
	$(BUILT_SOURCES) \
	budgie-daemon.desktop \
	budgie-daemon.desktop.in

DISTCLEANFILES = \
	budgie-daemon.desktop \
	budgie-daemon.desktop.in


@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_XML_NOMERGE_RULE@

# resources
budgie-daemon-resources.h: $(top_srcdir)/src/daemon/budgie-daemon.gresource.xml $(daemon_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/src/daemon --generate-header --c-name budgie_daemon $<

budgie-daemon-resources.c: $(top_srcdir)/src/daemon/budgie-daemon.gresource.xml $(daemon_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/src/daemon --generate-source --c-name budgie_daemon $<

EXTRA_DIST = \
	endsession.ui \
	osd.ui \
	budgie-daemon.gresource.xml \
	budgie-daemon.desktop.in.in


bin_PROGRAMS = \
	budgie-daemon

budgie_daemon_SOURCES = \
	budgie-daemon-resources.h \
	budgie-daemon-resources.c \
	endsession.vala \
	main.vala \
	manager.vala \
	osd.vala

budgie_daemon_CFLAGS = \
	$(BUDGIE_DAEMON_CFLAGS) \
	$(DECLARATIONS)

budgie_daemon_LDADD = \
	$(BUDGIE_DAEMON_LIBS) \
	${top_builddir}/src/config/libbudgie-config.la \
	${top_builddir}/src/libsession/libsession.la \
	${top_builddir}/theme/libbudgietheme.la


applicationsdir = $(datadir)/applications
applications_DATA = \
	budgie-daemon.desktop

budgie_daemon_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg theme \
	--pkg libsession \
	--pkg gdk-x11-3.0 \
	--pkg budgie-config \
	--vapidir=${top_srcdir}/src/config \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/theme \
	--vapidir=${top_srcdir}/src/libsession \
	--target-glib=2.38 \
	--gresources=${top_srcdir}/src/daemon/budgie-daemon.gresource.xml

-include $(top_srcdir)/common.mk

%.desktop: %.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

%.session: %.session.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

EXTRA_DIST = \
	budgie-desktop.session.in.in \
	budgie-desktop.desktop.in.in \
	budgie-desktop.in \
	budgie-desktop-nm-applet.desktop.in \
	budgie-desktop-screensaver.desktop.in

CLEANFILES = \
	budgie-desktop.session.in \
	budgie-desktop.session \
	budgie-desktop.desktop.in \
	budgie-desktop.desktop \
	budgie-desktop-nm-applet.desktop \
	budgie-desktop-screensaver.desktop

DISTCLEANFILES = \
	$(CLEANFILES)

bin_SCRIPTS = \
	budgie-desktop

xsessiondir = $(datadir)/xsessions

xsession_DATA = \
	budgie-desktop.desktop

gnomesessiondir = $(datadir)/gnome-session/sessions
gnomesession_DATA = \
	budgie-desktop.session

autostartdir = $(XDGDIR)/autostart

autostart_DATA = \
	budgie-desktop-nm-applet.desktop \
	budgie-desktop-screensaver.desktop

@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_XML_NOMERGE_RULE@

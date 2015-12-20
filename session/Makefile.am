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
	arc-desktop.session.in.in \
	arc-desktop.desktop.in.in \
	arc-desktop.in

CLEANFILES = \
	arc-desktop.session.in \
	arc-desktop.desktop.in

bin_SCRIPTS = \
	arc-desktop

xsessiondir = $(datadir)/xsessions

xsession_DATA = \
	arc-desktop.desktop

gnomesessiondir = $(datadir)/gnome-session/sessions
gnomesession_DATA = \
	arc-desktop.session

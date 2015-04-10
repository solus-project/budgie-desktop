-include $(top_srcdir)/common.mk

EXTRA_DIST =

panel_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/data --generate-dependencies $(top_srcdir)/data/budgie-panel.gresource.xml)

BUILT_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# resources
budgie-panel-resources.h: $(top_srcdir)/data/budgie-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-header --c-name budgie_panel $<

budgie-panel-resources.c: $(top_srcdir)/data/budgie-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-source --c-name budgie_panel $<


bin_PROGRAMS = budgie-panel

budgie_panel_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c \
	BudgiePanel.vala \
	PanelMover.vala \
	Editor.vala \
	IconSelect.vala

budgie_panel_CFLAGS = \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(WNCK3_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	$(GEE_CFLAGS) \
	-DMODULE_DIR=\"$(MODULEDIR)\" \
	-DMODULE_DATA_DIR=\"$(MODULE_DATA_DIR)\" \
	-DDATADIR=\"$(datadir)/budgie-desktop\" \
	-DLOCALEDIR=\"$(localedir)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

budgie_panel_LDADD = \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS) \
	$(WNCK3_LIBS) \
	$(LIBPEAS_LIBS) \
	$(GEE_LIBS) \
	-lm \
	../budgie-plugin/libbudgie-plugin.la \
	../widgets/libbudgiewidgets.la

budgie_panel_VALAFLAGS = \
	--vapidir=../budgie-plugin \
	--vapidir=../widgets \
	--vapidir=. \
	--pkg panelconfig \
	--pkg BudgieWidgets \
	--pkg gtk+-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg budgie-1.0 \
	--pkg PeasGtk-1.0 \
	$(VALAFLAGS) \
	--pkg gee-0.8

EXTRA_DIST += \
	panelconfig.h \
	panelconfig.vapi

SUBDIRS = \
	applets

dist-hook:
	cd $(distdir) && \
	rm $(budgie_panel_SOURCES:.vala=.c) budgie_panel_vala.stamp

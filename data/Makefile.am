-include $(top_srcdir)/common.mk

#@INTLTOOL_XML_NOMERGE_RULE@
gsettings_SCHEMAS = com.evolve-os.budgie.panel.gschema.xml \
	com.evolve-os.budgie.panel.object.gschema.xml
@GSETTINGS_RULES@

EXTRA_DIST = \
	budgie-desktop.desktop.in \
	com.evolve-os.budgie.panel.gschema.xml \
	com.evolve-os.budgie.panel.object.gschema.xml \
	budgie-panel.gresource.xml \
	rundialog.gresource.xml \
	session-dialog.gresource.xml \
	dialog.css \
	app.css \
	style.css \
	rundialog-style.css

xsessiondir = $(datadir)/xsessions

xsession_DATA = \
	budgie-desktop.desktop

panel_resources = $(shell glib-compile-resources --sourcedir=$(srcdir) --generate-dependencies $(srcdir)/budgie-panel.gresource.xml)
dialog_resources = $(shell glib-compile-resources --sourcedir=$(srcdir) --generate-dependencies $(srcdir)/session-dialog.gresource.xml)
rundialog_resources = $(shell glib-compile-resources --sourcedir=$(srcdir) --generate-dependencies $(srcdir)/rundialog.gresource.xml)

BUILT_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c \
	budgie-session-dialog-resources.h \
	budgie-session-dialog-resources.c \
	budgie-run-dialog-resources.h \
	budgie-run-dialog-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

budgie-panel-resources.h: budgie-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-header --c-name budgie_panel $<

budgie-panel-resources.c: budgie-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-source --c-name budgie_panel $<

budgie-session-dialog-resources.h: session-dialog.gresource.xml $(dialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-header --c-name budgie_session_dialog $<

budgie-session-dialog-resources.c: session-dialog.gresource.xml $(dialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-source --c-name budgie_session_dialog $<

budgie-run-dialog-resources.h: rundialog.gresource.xml $(rundialog_files)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-header --c-name budgie_run_dialog $<

budgie-run-dialog-resources.c: rundialog.gresource.xml $(rundialog_files)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-source --c-name budgie_run_dialog $<

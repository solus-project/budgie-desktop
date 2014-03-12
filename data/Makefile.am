-include $(top_srcdir)/common.mk

#@INTLTOOL_XML_NOMERGE_RULE@
gsettings_SCHEMAS = com.evolve-os.budgie.panel.gschema.xml
@GSETTINGS_RULES@

EXTRA_DIST = \
	budgie-desktop.desktop.in \
	com.evolve-os.budgie.panel.gschema.xml \
	budgie-panel.gresource.xml \
	session-dialog.gresource.xml \
	dialog.css \
	app.css \
	style.css

xsessiondir = $(datadir)/xsessions

xsession_DATA = \
	budgie-desktop.desktop

resource_files = $(shell glib-compile-resources --sourcedir=$(srcdir) --generate-dependencies $(srcdir)/budgie-panel.gresource.xml)
dialog_resources = $(shell glib-compile-resources --sourcedir=$(srcdir) --generate-dependencies $(srcdir)/session-dialog.gresource.xml)

BUILT_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c \
	budgie-session-dialog-resources.h \
	budgie-session-dialog-resources.c

budgie-panel-resources.h: budgie-panel.gresource.xml $(resource_files)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-header --c-name budgie_panel $<

budgie-panel-resources.c: budgie-panel.gresource.xml $(resource_files)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-source --c-name budgie_panel $<

budgie-session-dialog-resources.h: session-dialog.gresource.xml $(dialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-header --c-name budgie_session_dialog $<

budgie-session-dialog-resources.c: session-dialog.gresource.xml $(dialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-source --c-name budgie_session_dialog $<

-include $(top_srcdir)/common.mk

#@INTLTOOL_XML_NOMERGE_RULE@
gsettings_SCHEMAS = com.evolve-os.budgie.panel.gschema.xml
@GSETTINGS_RULES@

EXTRA_DIST = \
	budgie-desktop.desktop \
	com.evolve-os.budgie.panel.gschema.xml

xsessiondir = $(datadir)/xsessions

xsession_DATA = \
	budgie-desktop.desktop

resource_files = $(shell glib-compile-resources --sourcedir=$(srcdir) --generate-dependencies $(srcdir)/budgie-panel.gresource.xml)


BUILT_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c

budgie-panel-resources.h: budgie-panel.gresource.xml $(resource_files)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-header --c-name budgie_panel $<

budgie-panel-resources.c: budgie-panel.gresource.xml $(resource_files)
	glib-compile-resources --target=$@ --sourcedir=$(srcdir) --generate-source --c-name budgie_panel $<

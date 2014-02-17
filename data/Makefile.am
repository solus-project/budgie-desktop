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

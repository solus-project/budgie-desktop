-include $(top_srcdir)/common.mk

#@INTLTOOL_XML_NOMERGE_RULE@
gsettings_SCHEMAS = com.evolve-os.budgie.panel.gschema.xml
@GSETTINGS_RULES@

EXTRA_DIST = \
	budgie-desktop.desktop.in \
	com.evolve-os.budgie.panel.gschema.xml \
	budgie-panel.gresource.xml \
	rundialog.gresource.xml \
	session-dialog.gresource.xml \
	dialog.css \
	app.css \
	style.css \
	layout.ini \
	rundialog-style.css

xsessiondir = $(datadir)/xsessions

xsession_DATA = \
	budgie-desktop.desktop

defaultsdir = $(datadir)/budgie-desktop
defaults_DATA = \
	layout.ini

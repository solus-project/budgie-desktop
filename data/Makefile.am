EXTRA_DIST = \
	budgie-panel.desktop.in \
	com.solus-project.budgie-panel.gschema.xml \
	budgie-panel.gresource.xml \
	icons/notification-alert-symbolic.svg \
	icons/pane-hide-symbolic.svg \
	icons/pane-show-symbolic.svg \
	panel.ini

gsettings_SCHEMAS = \
	com.solus-project.budgie-panel.gschema.xml

@GSETTINGS_RULES@

appdir = $(datadir)/applications

app_DATA = \
	budgie-panel.desktop

iconsdir = $(datadir)/icons/hicolor/scalable/actions
icons_DATA = \
	icons/notification-alert-symbolic.svg \
	icons/pane-hide-symbolic.svg \
	icons/pane-show-symbolic.svg

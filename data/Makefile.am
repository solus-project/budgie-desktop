APPS_ICONS = \
	icons/apps/system-tray-symbolic.svg \
	icons/apps/icon-task-list-symbolic.svg \
	icons/apps/spacer-symbolic.svg \
	icons/apps/clock-applet-symbolic.svg \
	icons/apps/workspace-switcher-symbolic.svg \
	icons/apps/notifications-applet-symbolic.svg \
	icons/apps/separator-symbolic.svg \
	icons/apps/task-list-symbolic.svg

STATUS_ICONS = \
	icons/status/num-lock-symbolic.svg \
	icons/status/caps-lock-symbolic.svg


EXTRA_DIST = \
	budgie-panel.desktop.in \
	com.solus-project.budgie-panel.gschema.xml \
	budgie-panel.gresource.xml \
	icons/notification-alert-symbolic.svg \
	icons/pane-hide-symbolic.svg \
	icons/pane-show-symbolic.svg \
	panel.ini \
	$(APPS_ICONS) \
	$(STATUS_ICONS)

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

app_iconsdir = $(datadir)/icons/hicolor/scalable/apps
app_icons_DATA = \
	$(APPS_ICONS)

status_iconsdir = $(datadir)/icons/hicolor/scalable/status
status_icons_DATA = \
	$(STATUS_ICONS)


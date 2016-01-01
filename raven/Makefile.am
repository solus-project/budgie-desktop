-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	raven.vapi \
	ui/budgie-raven.gresource.xml \
	ui/appearance.ui \
	ui/panel.ui \
	ui/applets.ui \
	ui/applet_settings.ui \
	ui/notification.ui \
	ui/notification_clone.ui \
	ui/settings.ui

raven_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/raven/ui --generate-dependencies $(top_srcdir)/raven/ui/budgie-raven.gresource.xml)

BUILT_SOURCES = \
	budgie-raven-resources.h \
	budgie-raven-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# resources
budgie-raven-resources.h: $(top_srcdir)/raven/ui/budgie-raven.gresource.xml $(raven_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/raven/ui --generate-header --c-name budgie_raven $<

budgie-raven-resources.c: $(top_srcdir)/raven/ui/budgie-raven.gresource.xml $(raven_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/raven/ui --generate-source --c-name budgie_raven $<


lib_LTLIBRARIES = libraven.la

libraven_la_SOURCES = \
	budgie-raven-resources.h \
	budgie-raven-resources.c \
	raven.vala \
	main_view.vala \
	notifications_view.vala \
	settings_view.vala \
	powerstrip.vala \
	headerwidget.vala \
	calender.vala \
	sound.vala \
	mpris/MprisClient.vala \
	mpris/MprisGui.vala \
	mpris/MprisWidget.vala

libraven_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(GVC_CFLAGS) \
	$(DECLARATIONS)

libraven_la_LIBADD = \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(GVC_LIBS) \
	${top_builddir}/config/libbudgie-config.la \
	${top_builddir}/lib/libtoplevel.la \
	${top_builddir}/plugin/libbudgie-plugin.la \
	${top_builddir}/gvc/libgvc.la \
	-lm

libraven_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg budgie-1.0 \
	--pkg toplevel \
	--pkg gvc-1.0 \
	--pkg budgie-config \
	-H BudgieRaven.h \
	--vapidir=${top_srcdir}/config \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/plugin \
	--vapidir=${top_srcdir}/lib \
	--target-glib=2.38 \
	--gresources=${top_srcdir}/raven/ui/budgie-raven.gresource.xml \
	$(VALAFLAGS)

nodist_include_HEADERS = \
	BudgieRaven.h

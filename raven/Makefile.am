-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	raven.vapi \
	ui/arc-raven.gresource.xml \
	ui/settings.ui

raven_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/raven/ui --generate-dependencies $(top_srcdir)/raven/ui/arc-raven.gresource.xml)

BUILT_SOURCES = \
	arc-raven-resources.h \
	arc-raven-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# resources
arc-raven-resources.h: $(top_srcdir)/raven/ui/arc-raven.gresource.xml $(raven_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/raven/ui --generate-header --c-name arc_raven $<

arc-raven-resources.c: $(top_srcdir)/raven/ui/arc-raven.gresource.xml $(raven_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/raven/ui --generate-source --c-name arc_raven $<


lib_LTLIBRARIES = libraven.la

libraven_la_SOURCES = \
	arc-raven-resources.h \
	arc-raven-resources.c \
	raven.vala \
	main_view.vala \
	settings_view.vala \
	powerstrip.vala \
	headerwidget.vala \
	calender.vala \
	sound.vala \
	mpris/MprisClient.vala \
	mpris/MprisGui.vala \
	mpris/MprisWidget.vala

libraven_la_CFLAGS = \
	$(ARC_BASE_CFLAGS) \
	$(ARC_PLUGIN_CFLAGS) \
	$(GVC_CFLAGS) \
	$(DECLARATIONS)

libraven_la_LIBADD = \
	$(ARC_BASE_LIBS) \
	$(ARC_PLUGIN_LIBS) \
	$(GVC_LIBS) \
	${top_builddir}/lib/libtoplevel.la \
	${top_builddir}/plugin/libarc-plugin.la \
	${top_builddir}/gvc/libgvc.la

libraven_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg arc-1.0 \
	--pkg toplevel \
	--pkg gvc-1.0 \
	-H ArcRaven.h \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/plugin \
	--vapidir=${top_srcdir}/lib \
	--target-glib=2.38 \
	--gresources=${top_srcdir}/raven/ui/arc-raven.gresource.xml \
	$(VALAFLAGS)

nodist_include_HEADERS = \
	ArcRaven.h

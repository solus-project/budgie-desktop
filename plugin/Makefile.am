-include $(top_srcdir)/common.mk

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS =
INTROSPECTION_SCANNER_ARGS = --add-include-path=$(srcdir)
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

CLEANFILES =
EXTRA_DIST =

lib_LTLIBRARIES = libarc-plugin.la

libarc_plugin_la_SOURCES = \
	ArcPlugin.vala

libarc_plugin_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	$(GTK3_CFLAGS)

libarc_plugin_la_LIBADD = \
	$(LIBPEAS_LIBS) \
	$(GTK3_LIBS)

libarc_plugin_la_VALAFLAGS = \
	--pkg libpeas-1.0 \
	--pkg gtk+-3.0 \
	-H ArcPlugin.h

include_HEADERS = \
	ArcPlugin.h

INTROSPECTION_GIRS += Arc-1.0.gir

Arc-1.0.gir: libarc-plugin.la Makefile

Arc_1_0_gir_NAMESPACE = Arc
Arc_1_0_gir_VERSION = 1.0
Arc_1_0_gir_LIBS = libarc-plugin.la
Arc_1_0_gir_FILES = ArcPlugin.h ArcPlugin.c
Arc_1_0_gir_CFLAGS = $(INCLUDES) $(AM_CPPFLAGS) $(libarc_plugin_la_CFLAGS)
Arc_1_0_gir_INCLUDES = GObject-2.0 Gio-2.0 Gtk-3.0 Peas-1.0
Arc_1_0_gir_SCANNERFLAGS = --warn-all --c-include "ArcPlugin.h"

girdir = $(datadir)/gir-1.0
dist_gir_DATA = Arc-1.0.gir

typelibsdir = $(libdir)/girepository-1.0/
typelibs_DATA = Arc-1.0.typelib

CLEANFILES += $(dist_gir_DATA) $(typelibs_DATA)

vapidir = $(datadir)/vala/vapi
vapi_DATA = \
	arc-1.0.vapi \
	arc-1.0.deps

EXTRA_DIST += \
	arc-1.0.deps \
	arc-1.0.vapi \
	arc-1.0.pc.in

pkgconfigdir = \
	$(libdir)/pkgconfig

pkgconfig_DATA = \
	arc-1.0.pc

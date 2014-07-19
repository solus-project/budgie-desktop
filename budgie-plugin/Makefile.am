-include $(top_srcdir)/common.mk

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS =
INTROSPECTION_SCANNER_ARGS = --add-include-path=$(srcdir)
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

CLEANFILES =
EXTRA_DIST =

lib_LTLIBRARIES = libbudgie-plugin.la

libbudgie_plugin_la_SOURCES = \
	BudgiePlugin.vala

libbudgie_plugin_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	$(GTK3_CFLAGS)

libbudgie_plugin_la_LIBADD = \
	$(LIBPEAS_LIBS) \
	$(GTK3_LIBS)

libbudgie_plugin_la_VALAFLAGS = \
	--pkg libpeas-1.0 \
	--pkg gtk+-3.0 \
	-H BudgiePlugin.h

include_HEADERS = \
	BudgiePlugin.h

INTROSPECTION_GIRS += Budgie-1.0.gir

Budgie-1.0.gir: libbudgie-plugin.la Makefile

Budgie_1_0_gir_NAMESPACE = Budgie
Budgie_1_0_gir_VERSION = 1.0
Budgie_1_0_gir_LIBS = libbudgie-plugin.la
Budgie_1_0_gir_FILES = BudgiePlugin.h BudgiePlugin.c
Budgie_1_0_gir_CFLAGS = $(INCLUDES) $(AM_CPPFLAGS) $(libbudgie_plugin_la_CFLAGS)
Budgie_1_0_gir_INCLUDES = GObject-2.0 Gio-2.0 Gtk-3.0 Peas-1.0
Budgie_1_0_gir_SCANNERFLAGS = --warn-all --c-include "BudgiePlugin.h"

girdir = $(datadir)/gir-1.0
dist_gir_DATA = Budgie-1.0.gir

typelibsdir = $(libdir)/girepository-1.0/
typelibs_DATA = Budgie-1.0.typelib

CLEANFILES += $(dist_gir_DATA) $(typelibs_DATA)

vapidir = $(datadir)/vala/vapi
vapi_DATA = \
	budgie-1.0.vapi \
	budgie-1.0.deps

EXTRA_DIST += \
	budgie-1.0.deps \
	budgie-1.0.vapi \
	budgie-1.0.pc.in

pkgconfigdir = \
	$(prefix)/lib/pkgconfig

pkgconfig_DATA = \
	budgie-1.0.pc

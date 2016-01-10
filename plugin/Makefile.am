-include $(top_srcdir)/common.mk

include $(INTROSPECTION_MAKEFILE)
include $(VAPIGEN_MAKEFILE)

INTROSPECTION_GIRS =
INTROSPECTION_SCANNER_ARGS = --add-include-path=$(srcdir)
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

CLEANFILES =
EXTRA_DIST = \
	budgie-enums.h.template \
	budgie-enums.c.template \
	budgie-1.0.vapi \
	budgie-1.0.deps

lib_LTLIBRARIES = libbudgie-plugin.la


budgie_enum_headers = applet.h


budgie_devdir = $(includedir)/budgie-desktop
budgie_dev_HEADERS = \
	plugin.h \
	applet.h \
	popover-manager.h \
	budgie-enums.h

budgie-enums.h: $(budgie_enum_headers) budgie-enums.h.template
	$(GLIB_MKENUMS) --template $(filter %.template,$^) $(filter-out %.template,$^) > \
	budgie-enums.h.tmp && mv budgie-enums.h.tmp budgie-enums.h
budgie-enums.c: $(budgie_enum_headers) budgie-enums.h budgie-enums.c.template
	$(GLIB_MKENUMS) --template $(filter %.template,$^) $(filter-out %.template,$^) > \
	budgie-enums.c.tmp && mv budgie-enums.c.tmp budgie-enums.c

libbudgie_plugin_la_SOURCES = \
	budgie-enums.h \
	budgie-enums.c \
	applet.c \
	applet.h \
	applet-info.h \
	applet-info.c \
	popover-manager.h \
	popover-manager.c \
	plugin.h \
	plugin.c

libbudgie_plugin_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(AM_CFLAGS)

libbudgie_plugin_la_LIBADD = \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS)


INTROSPECTION_GIRS += Budgie-1.0.gir

Budgie-1.0.gir: libbudgie-plugin.la Makefile

Budgie_1_0_gir_NAMESPACE = Budgie
Budgie_1_0_gir_VERSION = 1.0
Budgie_1_0_gir_LIBS = libbudgie-plugin.la
Budgie_1_0_gir_FILES = $(libbudgie_plugin_la_SOURCES)
Budgie_1_0_gir_CFLAGS = $(INCLUDES) $(AM_CPPFLAGS) $(libbudgie_plugin_la_CFLAGS)
Budgie_1_0_gir_INCLUDES = GObject-2.0 Gio-2.0 Gtk-3.0 Peas-1.0
Budgie_1_0_gir_SCANNERFLAGS = --warn-all --symbol-prefix=budgie --c-include "plugin.h"

girdir = $(datadir)/gir-1.0
dist_gir_DATA = Budgie-1.0.gir

typelibsdir = $(libdir)/girepository-1.0/
typelibs_DATA = Budgie-1.0.typelib

CLEANFILES += $(dist_gir_DATA) $(typelibs_DATA)


vapidir = $(datadir)/vala/vapi
vapi_DATA = budgie-1.0.vapi

CLEANFILES += $(nodist_vapi_DATA)
 

pkgconfigdir = \
	$(libdir)/pkgconfig

pkgconfig_DATA = \
	budgie-1.0.pc

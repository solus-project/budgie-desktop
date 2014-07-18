-include $(top_srcdir)/common.mk

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
	--vapi=BudgiePlugin.vapi \
	-H BudgiePlugin.h

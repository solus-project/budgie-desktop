-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	toplevel.vapi

noinst_LTLIBRARIES = libtoplevel.la

libtoplevel_la_SOURCES = \
	animation.vala \
	toplevel.vala \
	shadow.vala \
	manager.vala

libtoplevel_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(DECLARATIONS)

libtoplevel_la_LIBADD = \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	${top_builddir}/plugin/libbudgie-plugin.la \
	-lm

libtoplevel_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg budgie-1.0 \
	--pkg libpeas-1.0 \
	--vapidir=${top_srcdir}/plugin \
	-H BudgieToplevel.h \
	$(VALAFLAGS)

nodist_include_HEADERS = \
	BudgieToplevel.h

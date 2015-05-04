-include $(top_srcdir)/common.mk

if BUILD_WM
bin_PROGRAMS = budgie-wm

noinst_LTLIBRARIES = libshellproxy.la

libshellproxy_la_SOURCES = \
	shell_proxy.c \
	shell_proxy.h

libshellproxy_la_CFLAGS = \
	$(GIO_UNIX_CFLAGS)

libshellproxy_la_LIBADD = \
	$(GIO_UNIX_LIBS)

budgie_wm_SOURCES = \
	plugin.h \
	core.c \
	legacy.h \
	legacy.c \
	impl.h \
	impl/keys.c \
	impl/map.c \
	impl/menu.c \
	impl/destroy.c \
	impl/minimize.c \
	impl/tabs.c \
	impl/workspace.c \
	ui/background.h \
	ui/background.c \
	ui/windowmenu.h \
	ui/windowmenu.c \
	budgie-wm.c

budgie_wm_CFLAGS = \
	$(MUTTER_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(AM_CFLAGS)

budgie_wm_LDADD = \
	$(MUTTER_LIBS) \
	$(GIO_UNIX_LIBS) \
	libshellproxy.la

shell_proxy.h: impl/org.gnome.ShellKeyGrabber.xml
	gdbus-codegen --generate-c-code shell_proxy \
	--c-namespace Shell \
	--c-generate-object-manager \
	--interface-prefix org.gnome.Shell. \
	$<

shell_proxy.c:

BUILT_SOURCES = \
	shell_proxy.h \
	shell_proxy.c

CLEANFILES = \
	$(BUILT_SOURCES)

EXTRA_DIST = \
	impl/org.gnome.ShellKeyGrabber.xml

endif

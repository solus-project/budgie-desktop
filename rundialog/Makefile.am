-include $(top_srcdir)/common.mk

if BUILD_RUNDIALOG
rundialog_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/data --generate-dependencies $(top_srcdir)/data/rundialog.gresource.xml)

BUILT_SOURCES = \
	budgie-run-dialog-resources.h \
	budgie-run-dialog-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# resources
budgie-run-dialog-resources.h: $(top_srcdir)/data/rundialog.gresource.xml $(rundialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-header --c-name budgie_run_dialog $<

budgie-run-dialog-resources.c: $(top_srcdir)/data/rundialog.gresource.xml $(rundialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-source --c-name budgie_run_dialog $<

bin_PROGRAMS = budgie-run-dialog

budgie_run_dialog_SOURCES = \
	RunDialog.vala \
	budgie-run-dialog-resources.c

budgie_run_dialog_CFLAGS = \
	$(GTK3_CFLAGS) \
	$(GMENU_CFLAGS) \
	$(GEE_CFLAGS) \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE

budgie_run_dialog_LDADD = \
	$(GTK3_LIBS) \
	$(GEE_LIBS) \
	$(GMENU_LIBS)

budgie_run_dialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libgnome-menu-3.0 \
	--pkg gio-unix-2.0 \
	--pkg gee-0.8 \
	--vapidir=..

endif

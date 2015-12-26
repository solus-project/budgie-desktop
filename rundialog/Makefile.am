-include $(top_srcdir)/common.mk

rundialog_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/rundialog --generate-dependencies $(top_srcdir)/rundialog/rundialog.gresource.xml)

BUILT_SOURCES = \
	budgie-run-dialog-resources.h \
	budgie-run-dialog-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# resources
budgie-run-dialog-resources.h: $(top_srcdir)/rundialog/rundialog.gresource.xml $(rundialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/rundialog --generate-header --c-name budgie_run_dialog $<

budgie-run-dialog-resources.c: $(top_srcdir)/rundialog/rundialog.gresource.xml $(rundialog_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/rundialog --generate-source --c-name budgie_run_dialog $<

bin_PROGRAMS = budgie-run-dialog

budgie_run_dialog_SOURCES = \
	RunDialog.vala \
	budgie-run-dialog-resources.c

budgie_run_dialog_CFLAGS = \
	$(RUNDIALOG_CFLAGS)

budgie_run_dialog_LDADD = \
	$(RUNDIALOG_LIBS)

budgie_run_dialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0


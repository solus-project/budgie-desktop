-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-run-dialog

budgie_run_dialog_SOURCES = \
	RunDialog.vala

budgie_run_dialog_CFLAGS = \
	$(RUNDIALOG_CFLAGS)

budgie_run_dialog_LDADD = \
	$(RUNDIALOG_LIBS)	  \
	../theme/libbudgietheme.la

budgie_run_dialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--vapidir=${top_srcdir}/theme \
	--pkg theme


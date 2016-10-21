-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-run-dialog

budgie_run_dialog_SOURCES = \
	RunDialog.vala

budgie_run_dialog_CFLAGS = \
	$(RUNDIALOG_CFLAGS) \
	$(DECLARATIONS)

budgie_run_dialog_LDADD = \
	$(RUNDIALOG_LIBS)	  \
	${top_builddir}/config/libbudgie-config.la \
	../theme/libbudgietheme.la

budgie_run_dialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg budgie-config \
	--vapidir=${top_srcdir}/config \
	--vapidir=${top_srcdir}/theme \
	--pkg theme


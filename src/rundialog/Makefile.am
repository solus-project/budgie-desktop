-include $(top_srcdir)/common.mk

bin_PROGRAMS = budgie-run-dialog

budgie_run_dialog_SOURCES = \
	RunDialog.vala

budgie_run_dialog_CFLAGS = \
	$(RUNDIALOG_CFLAGS) \
	$(DECLARATIONS)

budgie_run_dialog_LDADD = \
	$(RUNDIALOG_LIBS)	  \
	${top_builddir}/src/config/libbudgie-config.la \
	${top_builddir}/theme/libbudgietheme.la

budgie_run_dialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg budgie-config \
	--vapidir=${top_srcdir}/src/config \
	--vapidir=${top_srcdir}/theme \
	--pkg theme


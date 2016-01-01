if ENABLE_POLKIT_DIALOG

-include $(top_srcdir)/common.mk

EXTRA_DIST = \
	dialog.ui

bin_PROGRAMS = \
	budgie-polkit-dialog

budgie_polkit_dialog_SOURCES = \
	polkitdialog.vala

budgie_polkit_dialog_CFLAGS = \
	$(POLKIT_DIALOG_CFLAGS) \
	-DPOLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE \
	$(DECLARATIONS)

budgie_polkit_dialog_LDADD = \
	$(POLKIT_DIALOG_LIBS)


budgie_polkit_dialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg polkit-gobject-1 \
	--pkg polkit-agent-1 \
	--vapidir=${top_srcdir}/vapi

endif

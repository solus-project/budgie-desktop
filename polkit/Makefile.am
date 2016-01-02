if ENABLE_POLKIT_DIALOG

-include $(top_srcdir)/common.mk

polkit_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/polkit --generate-dependencies $(top_srcdir)/polkit/budgie-polkit.gresource.xml)

BUILT_SOURCES = \
	budgie-polkit-resources.h \
	budgie-polkit-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# resources
budgie-polkit-resources.h: $(top_srcdir)/polkit/budgie-polkit.gresource.xml $(polkit_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/polkit --generate-header --c-name budgie_raven $<

budgie-polkit-resources.c: $(top_srcdir)/polkit/budgie-polkit.gresource.xml $(polkit_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/polkit --generate-source --c-name budgie_raven $<

EXTRA_DIST = \
	dialog.ui \
	budgie-polkit.gresource.xml

bin_PROGRAMS = \
	budgie-polkit-dialog

budgie_polkit_dialog_SOURCES = \
	budgie-polkit-resources.h \
	budgie-polkit-resources.c \
	polkitdialog.vala

budgie_polkit_dialog_CFLAGS = \
	$(POLKIT_DIALOG_CFLAGS) \
	-DPOLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE \
	$(DECLARATIONS)

budgie_polkit_dialog_LDADD = \
	$(POLKIT_DIALOG_LIBS) \
	${top_builddir}/theme/libbudgietheme.la


budgie_polkit_dialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg polkit-gobject-1 \
	--pkg polkit-agent-1 \
	--vapidir=${top_srcdir}/vapi \
	--target-glib=2.38 \
	--gresources=${top_srcdir}/polkit/budgie-polkit.gresource.xml

endif

-include $(top_srcdir)/common.mk

polkit_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/polkit --generate-dependencies $(top_srcdir)/polkit/budgie-polkit.gresource.xml)

%.desktop: %.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

BUILT_SOURCES = \
	budgie-polkit-resources.h \
	budgie-polkit-resources.c

CLEANFILES = \
	$(BUILT_SOURCES) \
	budgie-polkit.desktop \
	budgie-polkit.desktop.in

DISTCLEANFILES = \
	budgie-polkit.desktop \
	budgie-polkit.desktop.in


@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_XML_NOMERGE_RULE@


# resources
budgie-polkit-resources.h: $(top_srcdir)/polkit/budgie-polkit.gresource.xml $(polkit_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/polkit --generate-header --c-name budgie_polkit $<

budgie-polkit-resources.c: $(top_srcdir)/polkit/budgie-polkit.gresource.xml $(polkit_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/polkit --generate-source --c-name budgie_polkit $<

EXTRA_DIST = \
	dialog.ui \
	budgie-polkit.gresource.xml \
	budgie-polkit.desktop.in.in

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
	${top_builddir}/config/libbudgie-config.la \
	${top_builddir}/libsession/libsession.la \
	${top_builddir}/theme/libbudgietheme.la


applicationsdir = $(datadir)/applications
applications_DATA = \
	budgie-polkit.desktop

budgie_polkit_dialog_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg polkit-gobject-1 \
	--pkg polkit-agent-1 \
	--pkg posix \
	--pkg theme \
	--pkg libsession \
	--pkg budgie-config \
	--vapidir=${top_srcdir}/config \
	--vapidir=${top_srcdir}/vapi \
	--vapidir=${top_srcdir}/theme \
	--vapidir=${top_srcdir}/libsession \
	--target-glib=2.38 \
	--gresources=${top_srcdir}/polkit/budgie-polkit.gresource.xml

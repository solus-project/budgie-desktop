-include $(top_srcdir)/common.mk

noinst_LTLIBRARIES = libbudgiewidgets.la

libbudgiewidgets_la_SOURCES = \
	BudgiePopover.vala

libbudgiewidgets_la_CFLAGS = \
	$(GTK3_CFLAGS)

libbudgiewidgets_la_LIBADD = \
	$(GTK3_LIBS)

libbudgiewidgets_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	-H BudgiePopover.h

AM_CFLAGS = \
	-fstack-protector -Wall -pedantic			\
	-Wstrict-prototypes -Wundef -fno-common 		\
	-Werror-implicit-function-declaration 			\
	-Wformat -Wformat-security -Werror=format-security 	\
	-Wconversion -Wunused-variable -Wunreachable-code 	\
	-Wall -W -D_FORTIFY_SOURCE=2 -std=c11			\
        -DDATADIR=\"$(datadir)\" -DSYSCONFDIR=\"$(sysconfdir)\" \
	-DGDK_VERSION_MAX_ALLOWED=GDK_VERSION_3_18 		\
	-DGDK_VERSION_MIN_REQUIRED=GDK_VERSION_3_18		\
	-DGLIB_VERSION_MAX_ALLOWED=GLIB_VERSION_2_46		\
	-DGLIB_VERSION_MIN_REQUIRED=GLIB_VERSION_2_46


AM_CPPFLAGS += \
	-I $(top_srcdir) \
	-I $(top_srcdir)/src/gvc \
	-I $(top_srcdir)/src/config \
	-I $(top_srcdir)/src/lib \
	-I $(top_srcdir)/src/libsession \
	-I $(top_srcdir)/src/panel \
	-I $(top_srcdir)/src/plugin \
	-I $(top_srcdir)/src/raven \
	-I $(top_srcdir)/src/theme \
	-O2

DECLARATIONS = \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

MODULE_FLAGS = \
	-module \
	-avoid-version \
	-shared

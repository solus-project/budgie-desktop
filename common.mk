AM_CFLAGS =  -fstack-protector -Wall -Wno-pedantic \
        -Wstrict-prototypes -Wundef -fno-common \
        -Werror-implicit-function-declaration \
        -Wformat -Wformat-security -Werror=format-security \
        -Wno-conversion \
        -Wunreachable-code \
        -std=c99 -Werror \
        -DDATADIR=\"$(datadir)\"

AM_CPPFLAGS += \
	-I $(top_srcdir) \
	-I $(top_srcdir)/gvc \
	-I $(top_srcdir)/lib \
	-I $(top_srcdir)/panel \
	-I $(top_srcdir)/plugin \
	-I $(top_srcdir)/raven \
	-O2

DECLARATIONS = \
	-DMODULE_DIR=\"$(MODULEDIR)\" \
	-DMODULE_DATA_DIR=\"$(MODULE_DATA_DIR)\" \
	-DDATADIR=\"$(datadir)/budgie-desktop\" \
	-DLOCALEDIR=\"$(localedir)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

MODULE_FLAGS = \
	-module \
	-avoid-version \
	-shared

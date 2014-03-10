AM_CFLAGS =  -fstack-protector -Wall -pedantic \
        -Wstrict-prototypes -Wundef -fno-common \
        -Werror-implicit-function-declaration \
        -Wformat -Wformat-security -Werror=format-security \
        -Wno-conversion -Werror \
        -Wunreachable-code \
        -DDATADIR=\"$(datadir)\"

AM_CPPFLAGS += \
	-I $(top_srcdir)/gvc \
	-I $(top_srcdir)/panel \
	-I $(top_srcdir)/panel/applets \
	-I $(top_srcdir)/panel/common

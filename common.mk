AM_CFLAGS =  -fstack-protector -Wall -pedantic \
        -Wstrict-prototypes -Wundef -fno-common \
        -Werror-implicit-function-declaration \
        -Wformat -Wformat-security -Werror=format-security \
        -Wno-conversion -Werror \
        -DDATADIR=\"$(datadir)\"

AM_CPPFLAGS += \
	-I $(top_srcdir)/gvc

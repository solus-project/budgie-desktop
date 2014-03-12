CONF=`pkg-config --cflags glib-2.0 gtk+-3.0 libwnck-3.0 libgnome-menu-3.0 upower-glib libmutter`
PROP="-DWNCK_I_KNOW_THIS_IS_UNSTABLE -DGMENU_I_KNOW_THIS_IS_UNSTABLE"
EXTRA="-I. -Ipanel/ -Ipanel/common -Igvc/"
# G_TYPE_DEFINE uses 0 not NULL....
OPTS="-DI_CAN_HAZ_SPARSE -Wdo-while -Wreturn-void -Wshadow -Wtypesign -Wno-non-pointer-null"

# Panel
C_FILES="`find panel/ -name '*.c'`"
sparse $OPTS $PROP $CONF $EXTRA $C_FILES

# Session
C_FILES="`find session/ -name '*.c'`"
sparse $OPTS $PROP $CONF $EXTRA $C_FILES

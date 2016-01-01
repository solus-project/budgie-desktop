# Source: https://mail.gnome.org/archives/commits-list/2012-September/msg01730.html
# adl_RECURSIVE_EVAL(VALUE, RESULT)
# =================================
# Interpolate the VALUE in loop until it doesn't change,
# and set the result to $RESULT.
# WARNING: It's easy to get an infinite loop with some unsane input.
# For example ${datadir} becomes ${datarootdir}, and then ${prefix}/share, and
# finally ${prefix} is replaced by the prefix.
AC_DEFUN([adl_RECURSIVE_EVAL],
[_lcl_receval="$1"
$2=`(test "x$prefix" = xNONE && prefix="$ac_default_prefix"
     test "x$exec_prefix" = xNONE && exec_prefix="${prefix}"
     _lcl_receval_old=''
     while test "[$]_lcl_receval_old" != "[$]_lcl_receval"; do
       _lcl_receval_old="[$]_lcl_receval"
       eval _lcl_receval="\"[$]_lcl_receval\""
     done
     echo "[$]_lcl_receval")`])

adl_RECURSIVE_EVAL(["${libdir}/budgie-desktop/plugins"], [MODULEDIR])
AC_SUBST(MODULEDIR)
AC_DEFINE_UNQUOTED(MODULEDIR, "$MODULEDIR",
                   [Installation directory for Budgie plugins])

# Technically unused right now but might be used in the future
adl_RECURSIVE_EVAL(["${datadir}/budgie-desktop/plugins"], [MODULE_DATA_DIR])
AC_SUBST(MODULE_DATA_DIR)
AC_DEFINE_UNQUOTED(MODULE_DATA_DIR, "$MODULE_DATA_DIR",
                   [Installation directory for Budgie plugin data])


# Locale directory
adl_RECURSIVE_EVAL(["${localedir}"], [LOCALEDIR])
AC_SUBST(LOCALEDIR)
AC_DEFINE_UNQUOTED(LOCALEDIR, "$LOCALEDIR",
                   [Installation directory for Budgie locale data])

#ifndef CONFIG_H_INCLUDED
#include "config.h"
#endif

#ifndef PANEL_CONFIG_H
#define PANEL_CONFIG_H

/* i.e. /usr/lib/budgie-desktop */
static const char *BUDGIE_MODULE_DIRECTORY = MODULE_DIR;

/* i.e. /usr/share/budgie-desktop/plugins */
static const char *BUDGIE_MODULE_DATA_DIRECTORY = MODULE_DATA_DIR;

/* i.e. /usr/share/budgie-desktop */
static const char *BUDGIE_DATADIR = DATADIR;

static const char *BUDGIE_VERSION = PACKAGE_VERSION;

static const char *BUDGIE_WEBSITE = PACKAGE_URL;

static const char *BUDGIE_LOCALEDIR = LOCALEDIR;

static const char *BUDGIE_GETTEXT_PACKAGE = GETTEXT_PACKAGE;

#endif

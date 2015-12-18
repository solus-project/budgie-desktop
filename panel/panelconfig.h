#ifndef CONFIG_H_INCLUDED
#include "config.h"
#endif

#ifndef PANEL_CONFIG_H
#define PANEL_CONFIG_H

/* i.e. /usr/lib/arc-desktop */
static const char *ARC_MODULE_DIRECTORY = MODULE_DIR;

/* i.e. /usr/share/arc-desktop/plugins */
static const char *ARC_MODULE_DATA_DIRECTORY = MODULE_DATA_DIR;

/* i.e. /usr/share/arc-desktop */
static const char *ARC_DATADIR = DATADIR;

static const char *ARC_VERSION = PACKAGE_VERSION;

static const char *ARC_WEBSITE = PACKAGE_URL;

static const char *ARC_LOCALEDIR = LOCALEDIR;

static const char *ARC_GETTEXT_PACKAGE = GETTEXT_PACKAGE;

#endif

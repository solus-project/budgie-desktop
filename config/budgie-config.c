/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#include "budgie-config.h"

#ifndef CONFIG_H_INCLUDED
#include "config.h"

__attribute__((constructor)) void _budgie_config_init(void)
{
        BUDGIE_MODULE_DIRECTORY = MODULEDIR;
        BUDGIE_MODULE_DATA_DIRECTORY = MODULE_DATA_DIR;
        BUDGIE_DATADIR = DATADIR;
        BUDGIE_VERSION = PACKAGE_VERSION;
        BUDGIE_WEBSITE = PACKAGE_URL;
        BUDGIE_LOCALEDIR = LOCALEDIR;
        BUDGIE_GETTEXT_PACKAGE = GETTEXT_PACKAGE;
        BUDGIE_CONFDIR = SYSCONFDIR;
}

#else
#error config.h missing!
#endif

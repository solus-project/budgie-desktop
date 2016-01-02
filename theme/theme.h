/*
 * This file is part of budgie-desktop.
 *
 * Copyright (C) 2015 Ikey Doherty
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

/**
 * This is genuinely needed. So the libbudgietheme shared library
 * really only has an __attribute__((constructor)), which we link
 * against to gain the shared theme assets in all of our binaries.
 *
 * However, -Wl,-as-needed will break this as there's no explicit
 * dependency, so we have this dummy function which won't be optimised
 * out by GCC, to enforce a dependency between the programs and
 * library via symbols.
 */
void budgie_please_link_me_libtool_i_have_great_themes(void);

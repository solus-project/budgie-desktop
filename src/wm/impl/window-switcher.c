/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#define _GNU_SOURCE

#include "window-switcher.h"
#include "util.h"

/**
 * Make ourselves known to gobject
 */
G_DEFINE_TYPE(BudgieWindowSwitcher, budgie_window_switcher, CLUTTER_TYPE_ACTOR)

/**
 * budgie_window_switcher_dispose:
 *
 * Clean up a BudgieWindowSwitcher instance
 */
static void budgie_window_switcher_dispose(GObject *obj)
{
        G_OBJECT_CLASS(budgie_window_switcher_parent_class)->dispose(obj);
}

/**
 * budgie_window_switcher_class_init:
 *
 * Handle class initialisation
 */
static void budgie_window_switcher_class_init(BudgieWindowSwitcherClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);

        /* gobject vtable */
        obj_class->dispose = budgie_window_switcher_dispose;
}

/**
 * budgie_window_switcher_init:
 *
 * Handle construction of the BudgieWindowSwitcher
 */
static void budgie_window_switcher_init(__budgie_unused__ BudgieWindowSwitcher *self)
{
}

ClutterActor *budgie_window_switcher_new(void)
{
        return g_object_new(BUDGIE_TYPE_WINDOW_SWITCHER, NULL);
}

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 8
 * tab-width: 8
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=8 tabstop=8 expandtab:
 * :indentSize=8:tabSize=8:noTabs=true:
 */

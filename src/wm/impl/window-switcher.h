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

#pragma once

#include <clutter/clutter.h>
#include <glib-object.h>

G_BEGIN_DECLS

typedef struct _BudgieWindowSwitcher BudgieWindowSwitcher;
typedef struct _BudgieWindowSwitcherClass BudgieWindowSwitcherClass;

/**
 * Class inheritance
 */
struct _BudgieWindowSwitcherClass {
        ClutterActorClass parent_class;
};

/**
 * Actual instance definition
 */
struct _BudgieWindowSwitcher {
        ClutterActor parent;
};

#define BUDGIE_TYPE_WINDOW_SWITCHER budgie_window_switcher_get_type()
#define BUDGIE_WINDOW_SWITCHER(o)                                                                  \
        (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_WINDOW_SWITCHER, BudgieWindowSwitcher))
#define BUDGIE_IS_WINDOW_SWITCHER(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_WINDOW_SWITCHER))
#define BUDGIE_WINDOW_SWITCHER_CLASS(o)                                                            \
        (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_WINDOW_SWITCHER, BudgieWindowSwitcherClass))
#define BUDGIE_IS_WINDOW_SWITCHER_CLASS(o)                                                         \
        (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_WINDOW_SWITCHER))
#define BUDGIE_WINDOW_SWITCHER_GET_CLASS(o)                                                        \
        (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_WINDOW_SWITCHER, BudgieWindowSwitcherClass))

GType budgie_window_switcher_get_type(void);

ClutterActor *budgie_window_switcher_new(void);

G_END_DECLS

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

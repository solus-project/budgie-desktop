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

#include <string.h>

#include "tile-widget.h"
#include "util.h"

/**
 * Make ourselves known to gobject
 */
G_DEFINE_TYPE(BudgieTilePreview, budgie_tile_preview, CLUTTER_TYPE_ACTOR)

/**
 * budgie_tile_preview_dispose:
 *
 * Clean up a BudgieTilePreview instance
 */
static void budgie_tile_preview_dispose(GObject *obj)
{
        G_OBJECT_CLASS(budgie_tile_preview_parent_class)->dispose(obj);
}

/**
 * budgie_tile_preview_class_init:
 *
 * Handle class initialisation
 */
static void budgie_tile_preview_class_init(BudgieTilePreviewClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);

        /* gobject vtable */
        obj_class->dispose = budgie_tile_preview_dispose;
}

/**
 * budgie_tile_preview_init:
 *
 * Handle construction of the BudgieTilePreview
 */
static void budgie_tile_preview_init(BudgieTilePreview *self)
{
        memset(&self->rect, 0, sizeof(MetaRectangle));
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

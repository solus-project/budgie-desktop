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
#include <meta/boxes.h>

G_BEGIN_DECLS

typedef struct _BudgieTilePreview BudgieTilePreview;
typedef struct _BudgieTilePreviewClass BudgieTilePreviewClass;

/**
 * Class inheritance
 */
struct _BudgieTilePreviewClass {
        ClutterActorClass parent_class;
};

/**
 * Actual instance definition
 */
struct _BudgieTilePreview {
        ClutterActor parent;
        MetaRectangle rect;
};

#define BUDGIE_TYPE_TILE_PREVIEW budgie_tile_preview_get_type()
#define BUDGIE_TILE_PREVIEW(o)                                                                     \
        (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_TILE_PREVIEW, BudgieTilePreview))
#define BUDGIE_IS_TILE_PREVIEW(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_TILE_PREVIEW))
#define BUDGIE_TILE_PREVIEW_CLASS(o)                                                               \
        (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_TILE_PREVIEW, BudgieTilePreviewClass))
#define BUDGIE_IS_TILE_PREVIEW_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_TILE_PREVIEW))
#define BUDGIE_TILE_PREVIEW_GET_CLASS(o)                                                           \
        (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_TILE_PREVIEW, BudgieTilePreviewClass))

GType budgie_tile_preview_get_type(void);

ClutterActor *budgie_tile_preview_new(void);

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

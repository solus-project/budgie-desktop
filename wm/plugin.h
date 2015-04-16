/*
 * plugin.h
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */

#define BUDGIE_TYPE_WM            (budgie_wm_get_type ())
#define BUDGIE_WM(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_TYPE_WM, BudgieWM))
#define BUDGIE_WM_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass),  BUDGIE_TYPE_WM, BudgieWMClass))
#define BUDGIE_IS_WM(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_WM_TYPE))
#define BUDGIE_IS_WM_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass),  BUDGIE_TYPE_WM))
#define BUDGIE_WM_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj),  BUDGIE_TYPE_WM, BudgieWMClass))

typedef struct _BudgieWM        BudgieWM;
typedef struct _BudgieWMClass   BudgieWMClass;
typedef struct _BudgieWMPrivate BudgieWMPrivate;

#define BUDGIE_WM_SCHEMA "com.evolve-os.budgie.wm"
#define MUTTER_EDGE_TILING "edge-tiling"
#define MUTTER_MODAL_ATTACH "attach-modal-dialogs"

#define BUDGIE_KEYBINDING_MAIN_MENU "panel-main-menu"
#define BUDGIE_KEYBINDING_RUN_DIALOG "panel-run-dialog"

/*
 * This is only temporarily here while we migrate away from the legacy
 * crap.
 */
struct _BudgieWMPrivate
{
        /* Valid only when switch_workspace effect is in progress */
        ClutterActor          *out_group;
        ClutterActor          *in_group;

        ClutterActor          *background_group;
        MetaPluginInfo         info;
};

struct _BudgieWM
{
        MetaPlugin parent;
        BudgieWMPrivate *priv;
};

struct _BudgieWMClass
{
        MetaPluginClass parent_class;
};

GType budgie_wm_get_type (void);

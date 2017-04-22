/* Fixed tooltip routine */

/*
 * Copyright (C) 2001 Havoc Pennington, 2002 Red Hat Inc.
 * Copyright (C) 2003-2006 Vincent Untz
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 */

#ifndef FIXED_TIP_H
#define FIXED_TIP_H

#include <gtk/gtk.h>

G_BEGIN_DECLS

#define NA_TYPE_FIXED_TIP			(na_fixed_tip_get_type ())
#define NA_FIXED_TIP(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), NA_TYPE_FIXED_TIP, NaFixedTip))
#define NA_FIXED_TIP_CLASS(klass)		(G_TYPE_CHECK_CLASS_CAST ((klass), NA_TYPE_FIXED_TIP, NaFixedTipClass))
#define NA_IS_FIXED_TIP(obj)			(G_TYPE_CHECK_INSTANCE_TYPE ((obj), NA_TYPE_FIXED_TIP))
#define NA_IS_FIXED_TIP_CLASS(klass)		(G_TYPE_CHECK_CLASS_TYPE ((klass), NA_TYPE_FIXED_TIP))
#define NA_FIXED_TIP_GET_CLASS(obj)		(G_TYPE_INSTANCE_GET_CLASS ((obj), NA_TYPE_FIXED_TIP, NaFixedTipClass))

typedef struct _NaFixedTip	  NaFixedTip;
typedef struct _NaFixedTipPrivate NaFixedTipPrivate;
typedef struct _NaFixedTipClass   NaFixedTipClass;

struct _NaFixedTip
{
  GtkWindow parent_instance;

  NaFixedTipPrivate *priv;
};

struct _NaFixedTipClass
{
  GtkWindowClass parent_class;

  void (* clicked)    (NaFixedTip *fixedtip);
};

GType      na_fixed_tip_get_type (void);

GtkWidget *na_fixed_tip_new (GtkWidget      *parent,
                             GtkOrientation  orientation);

void       na_fixed_tip_set_markup (GtkWidget  *widget,
                                    const char *markup_text);

void       na_fixed_tip_set_orientation (GtkWidget      *widget,
                                         GtkOrientation  orientation);

G_END_DECLS

#endif /* FIXED_TIP_H */

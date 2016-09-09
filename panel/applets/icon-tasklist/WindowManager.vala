/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2016 Fernando Mussel <fernandomussel91@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public interface WindowManager
{
    public abstract void toggle_window_list(IconButton btn, Gtk.Popover popover);
    public abstract void close_window(Wnck.Window win);
    public abstract void toggle_window(Wnck.Window win);

    public abstract DesktopAppInfo? query_window(Wnck.Window window);
}

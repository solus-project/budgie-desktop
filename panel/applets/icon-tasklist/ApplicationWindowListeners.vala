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

public interface NameChangeListener
{
    public abstract void name_changed(ApplicationWindow appwin, string new_name);
}

public interface IconChangeListener
{
    public abstract void icon_changed(ApplicationWindow appwin);
}

public interface AttentionStatusListener
{
    public abstract void attention_status_changed(ApplicationWindow appwin,
                                                  bool needs_attention );
}

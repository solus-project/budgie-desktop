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

public class ApplicationWindow
{
    private Wnck.Window? window = null;
    private unowned NameChangeListener? name_listener;
    private unowned IconChangeListener? icon_listener;
    private unowned AttentionStatusListener? attention_status_listener;

    private ulong icon_changed_id = 0;
    private ulong name_changed_id = 0;
    private ulong state_changed_id = 0;

    private bool attention_requested = false;
    private WindowMenu? menu = null;

    public ApplicationWindow(Wnck.Window window,
                             WindowMenu menu)
    {

        this.window = window;
        this.name_listener = null;
        this.icon_listener = null;
        this.attention_status_listener = null;
        this.menu = menu;

        // setup callbacks to all the window events we are interested in
        name_changed_id = this.window.name_changed.connect(update_name);
        icon_changed_id = this.window.icon_changed.connect(update_icon);
        state_changed_id = this.window.state_changed.connect(state_changed);
    }

    ~ApplicationWindow()
    {
        this.window.disconnect(icon_changed_id);
        this.window.disconnect(name_changed_id);
        this.window.disconnect(state_changed_id);
        // We must call this to free the WindowMenu instance
        this.menu.clear();
    }

    private void update_icon()
    {
        if (icon_listener != null) {
            icon_listener.icon_changed(this);
        }
    }

    private void update_name()
    {
        if (name_listener != null) {
            name_listener.name_changed(this, window.get_name());
        }
    }

    private void state_changed(Wnck.WindowState changed, Wnck.WindowState state)
    {
        if (window.needs_attention() && !attention_requested) {
            // window has just requested attention
            attention_requested = true;
        } else if (!window.needs_attention() && attention_requested) {
            attention_requested = false;
        } else {
            // no change
            return;
        }

        // If we reached here, the attention status changed. Send signal if
        // there is a listener
        if (attention_status_listener != null) {
            attention_status_listener.attention_status_changed(this, attention_requested);
        }
    }

    public unowned Wnck.Window get_window()
    {
        return window;
    }

    public void set_name_change_listener(NameChangeListener listener)
    {
        name_listener = listener;
    }

    public void set_icon_change_listener(IconChangeListener listener)
    {
        icon_listener = listener;
    }

    public void set_attention_status_listener(AttentionStatusListener listener)
    {
        attention_status_listener = listener;
    }

    public bool needs_attention()
    {
        return attention_requested;
    }

    public WindowMenu get_menu()
    {
        return menu;
    }

    public void set_menu(WindowMenu menu)
    {
        this.menu.clear();
        this.menu = menu;
    }
}

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

public class WindowListView
{

    private unowned WindowManager? window_manager = null;

    private Gtk.Popover? window_list_popover = null;
    private Gtk.ListBox window_listbox;
    private unowned Gtk.Widget owner;
    private HashTable<unowned ApplicationWindow, unowned WindowListItem>? window_row_map = null;
    private Gtk.SizeGroup switch_btn_group;
    private Queue<Gtk.ListBoxRow> removed_items;

    public WindowListView(Gtk.Widget owner, WindowManager window_manager)
    {
        this.owner = owner;
        this.window_manager = window_manager;
        window_row_map = new HashTable<unowned ApplicationWindow,unowned WindowListItem>(direct_hash, direct_equal);
        configure_view();
        removed_items = new Queue<Gtk.ListBoxRow>();
    }

    ~WindowListView()
    {
        clear_removed_items();
    }

    public uint get_window_num()
    {
        return window_row_map.size();
    }

    /**
     * Add new WindowListItem associated with \p appwin
     */
    public void add_window(ApplicationWindow appwin)
    {
        WindowListItem win_row = add_window_list_item(appwin);

        window_row_map [appwin] = win_row;
        // set the row object as the listener for the window's name change
        // event
        appwin.set_name_change_listener(win_row);
    }

    /**
     * Handles the view side operations required to add a new ListBoxRow associated
     * with the supplied window
     */
    private WindowListItem add_window_list_item(ApplicationWindow appwin)
    {
        WindowListItem new_item = new WindowListItem(appwin.get_window().get_name(),
                                                     appwin, window_manager);

        // this ensures that the switch buttons of all WindowListItems will have
        // the same length
        new_item.add_switch_button_to_group(switch_btn_group);
        window_listbox.insert(new_item, -1);
        // prevent new_item's parent(ListBoxRow) to be focusable
        new_item.get_parent().set_can_focus(false);
        new_item.get_parent().show_all();

        return new_item;
    }

    public void remove_window(ApplicationWindow appwin)
    {
        var list_row = window_row_map [appwin];

        // Handles the removal, with animation, of WindowListItem from the ListBox
        list_row.gracefully_die(window_listbox);
        window_row_map.remove(appwin);
        // hold item to prevent its destruction and the possible resize of the
        // other elements in the switch_btn_group SizeGroup. Removed elements
        // will be cleared after the popover is closed
        removed_items.push_tail(list_row.get_parent() as Gtk.ListBoxRow);

        if (get_window_num() == 0) {
            // last element removed. Close Popover
            if (window_list_popover.get_visible()) {
                window_list_popover.hide();
            }
            // clear the references to removed items
            clear_removed_items();
        }
    }

    private void clear_removed_items()
    {
        // delete the reference of all the removed WindowListItems removed
        // while the popover was opened
        Gtk.ListBoxRow item;
        while ((item = removed_items.pop_head()) != null) {
            (item.get_child() as WindowListItem).remove_switch_button_from_group(switch_btn_group);
        }
    }

    private void configure_view()
    {
        window_listbox = new Gtk.ListBox();
        window_listbox.selection_mode = Gtk.SelectionMode.NONE;

        window_list_popover = new Gtk.Popover(owner);
        window_list_popover.add(window_listbox);
        switch_btn_group = new Gtk.SizeGroup(Gtk.SizeGroupMode.BOTH);
        switch_btn_group.set_ignore_hidden(false);

        window_list_popover.closed.connect_after(on_popover_closed);
        window_listbox.show_all();
    }

    private void on_popover_closed()
    {
        clear_removed_items();
    }

    public Gtk.Popover get_popover()
    {
        return window_list_popover;
    }

    public void begin_attention_request(ApplicationWindow appwin)
    {
        var row = window_row_map [appwin];
        row.begin_attention_request();
    }

    public void end_attention_request(ApplicationWindow appwin)
    {
        var row = window_row_map [appwin];
        row.end_attention_request();
    }

    public void replace_owner(Gtk.Widget new_owner)
    {
        window_list_popover.set_relative_to(new_owner);
        owner = new_owner;
    }
}

/*
 * Copyright (c) 2014 Intel Corporation
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Author:
 *      Ikey Doherty <michael.i.doherty@intel.com>
 *
 * Ported to Vala to ensure a form of GtkSidebar was available in older distributions
 * purely for the benefit of the Budgie Desktop
 *
 *  - Ikey Doherty <ikey@solus-project.com>
 */

namespace Budgie {

class SidebarItem : Gtk.Box
{
    public Gtk.Label label;
    public Gtk.Image image;

    public SidebarItem()
    {
        set_orientation(Gtk.Orientation.HORIZONTAL);
        get_style_context().add_class("sidebar-item");

        image = new Gtk.Image();
        image.margin_right = 10;
        label = new Gtk.Label("");
        pack_start(image, false, false, 0);
        pack_start(label, true, true, 0);
    }

}
public class Sidebar : Gtk.Bin
{

    private Gtk.Stack? stack;
    private Gtk.ScrolledWindow scroll;
    private Gtk.ListBox list;
    private HashTable<Gtk.Widget?,Gtk.ListBoxRow?> rows;
    private bool in_child_changed = false;

    public Sidebar()
    {
        scroll = new Gtk.ScrolledWindow(null, null);
        add(scroll);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        list = new Gtk.ListBox();
        list.set_header_func(update_header);
        list.set_sort_func(sort_list);
        list.row_selected.connect(on_row_selected);
        scroll.add(list);

        get_style_context().add_class("sidebar");

        rows = new HashTable<Gtk.Widget?,Gtk.ListBoxRow?>(null, null);
    }

    ~Sidebar()
    {
        if (stack != null) {
            disconnect_stack_signals();
        }
    }

    void on_row_selected(Gtk.ListBoxRow? row)
    {

        if (in_child_changed) {
            return;
        }
        if (row == null) {
            return;
        }
        var item = row.get_child();
        Gtk.Widget? widget = item.get_data("stack-child");
        stack.set_visible_child(widget);
    }

    int sort_list(Gtk.ListBoxRow? row1, Gtk.ListBoxRow? row2)
    {
        int left = 0;
        int right = 0;

        if (row1 != null) {
            var item = row1.get_child();
            Gtk.Widget? widget = item.get_data("stack-child");
            stack.child_get(widget, "position", out left);
        }
        if (row2 != null) {
            var item = row2.get_child();
            Gtk.Widget? widget = item.get_data("stack-child");
            stack.child_get(widget, "position", out right);
        }

        if (left < right) {
            return -1;
        }
        if (left == right) {
            return 0;
        }

        return 1;
    }

    public void set_stack(Gtk.Stack? stack) {
        if (this.stack != null) {
            disconnect_stack_signals();
            clear_sidebar();
        }
        if (stack == null) {
            this.queue_resize();
            return;
        }
        this.stack = stack;
        populate_sidebar();
        connect_stack_signals();
        this.queue_resize();
    }

    void clear_sidebar()
    {
        foreach (var child in stack.get_children()) {
            remove_child(child);
        }
    }

    void update_row(ref Gtk.ListBoxRow? row, Gtk.Widget? widget)
    {
        string? title = null;
        string? icon = null;

        stack.child_get(widget, "title", out title, "icon-name", out icon);
        var item = row.get_child() as SidebarItem;
        item.label.set_label(title);

        if (icon != null) {
            item.image.set_from_icon_name(icon, Gtk.IconSize.LARGE_TOOLBAR);
        }

        row.set_visible(widget.get_visible() && title != null);
    }

    void update_header(Gtk.ListBoxRow? row, Gtk.ListBoxRow? before)
    {
        if (before != null && row.get_header() == null) {
            var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
            row.set_header(sep);
            sep.show_all();
        }
    }

    void on_child_updated(Object? source, ParamSpec prop) {
        var row = rows.lookup(source as Gtk.Widget);
        update_row(ref row, source as Gtk.Widget);
    }

    void on_position_updated(Gtk.Widget source, ParamSpec prop)
    {
        list.invalidate_sort();
    }
    
    void add_child(Gtk.Widget child)
    {
        if (rows.lookup(child) != null) {
            return;
        }

        var item = new SidebarItem();
        item.halign = Gtk.Align.START;
        item.valign = Gtk.Align.CENTER;

        var row = new Gtk.ListBoxRow();
        row.add(item);
        item.show();

        rows.insert(child, row);

        update_row(ref row, child);

        child.child_notify["title"].connect(on_child_updated);
        child.child_notify["icon-name"].connect(on_child_updated);
        child.notify["visible"].connect(on_child_updated);
        child.child_notify["position"].connect(on_position_updated);
                    
        item.set_data("stack-child", child);
        row.get_style_context().add_class("sidebar-item");
        list.add(row);
    }

    void remove_child(Gtk.Widget child)
    {
        var row = rows.lookup(child);
        if (row == null) {
            return;
        }
        SignalHandler.disconnect_by_func(child, (void*)on_child_updated, (void*)this);
        SignalHandler.disconnect_by_func(child, (void*)on_position_updated, (void*)this);

        list.remove(row);
        rows.remove(child);
    }

    void populate_sidebar()
    {
        foreach (Gtk.Widget? child in stack.get_children()) {
            add_child(child);
        }
    }

    void on_stack_child_added(Gtk.Widget child)
    {
        add_child(child);
    }

    void on_stack_child_removed(Gtk.Widget child)
    {
        remove_child(child);
    }

    void on_child_changed()
    {
        var child = stack.get_visible_child();
        var row = rows.lookup(child);
        if (row != null) {
            in_child_changed = true;
            list.select_row(row);
            in_child_changed = false;
        }
    }

    void connect_stack_signals()
    {
        stack.add.connect_after(on_stack_child_added);
        stack.remove.connect_after(on_stack_child_removed);
        stack.notify["visible-child"].connect(on_child_changed);
        stack.destroy.connect(disconnect_stack_signals);
    }

    void disconnect_stack_signals()
    {
        SignalHandler.disconnect_by_func(stack, (void*)on_stack_child_added, (void*)this);
        SignalHandler.disconnect_by_func(stack, (void*)on_stack_child_removed, (void*)this);
        SignalHandler.disconnect_by_func(stack, (void*)on_child_changed, (void*)this);
        SignalHandler.disconnect_by_func(stack, (void*)disconnect_stack_signals, (void*)this);
    }
}

} // End namespace

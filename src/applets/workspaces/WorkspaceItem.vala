/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017-2019 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Workspaces {

const Gtk.TargetEntry[] target_list = {
    { "application/x-wnck-window-id", 0, 0 }
};

public class WorkspaceItem : Gtk.EventBox
{
    private Wnck.Workspace workspace;
    private Budgie.Popover popover;
    private Gtk.Stack popover_stack;
    private Gtk.FlowBox rest_of_the_icons;
    public signal void remove_workspace(int index, uint32 time);
    public signal void pls_update_windows();
    private Gtk.Grid icon_grid;
    private Gtk.Allocation real_alloc;

    public WorkspaceItem(Wnck.Workspace space)
    {
        this.get_style_context().add_class("workspace-item");
        this.workspace = space;
        this.set_tooltip_text(workspace.get_name());

        real_alloc.width = 0;
        real_alloc.height = 0;

        icon_grid = new Gtk.Grid();
        icon_grid.set_column_spacing(0);
        icon_grid.set_row_spacing(0);
        icon_grid.set_row_homogeneous(true);
        icon_grid.set_column_homogeneous(true);
        this.add(icon_grid);

        popover = new Budgie.Popover(this);
        popover.get_style_context().add_class("workspace-popover");
        popover.set_size_request(150, -1);

        Gtk.Box popover_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        popover.add(popover_box);

        Gtk.Label name_label = new Gtk.Label(@"<big>$(workspace.get_name())</big>");
        popover_box.pack_start(name_label, false, false, 0);
        name_label.get_style_context().add_class("dim-label");
        name_label.halign = Gtk.Align.START;
        name_label.margin_start = 5;
        name_label.margin_top = 5;
        name_label.margin_bottom = 5;
        name_label.set_use_markup(true);
        Gtk.Separator sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        popover_box.pack_start(sep, true, false, 0);

        popover_stack = new Gtk.Stack();
        popover_box.add(popover_stack);
        popover_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        popover_stack.set_interpolate_size(true);
        popover_stack.set_homogeneous(false);

        Gtk.Box button_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        button_box.get_style_context().add_class("workspace-popover-button-box");
        popover_stack.add(button_box);
        Gtk.Button rename_button = new Gtk.Button.with_label(_("Rename"));
        button_box.pack_start(rename_button, true, true, 0);
        rename_button.get_child().halign = Gtk.Align.START;
        rename_button.get_child().margin_start = 0;
        rename_button.set_relief(Gtk.ReliefStyle.NONE);
        Gtk.Separator sep1 = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        button_box.pack_start(sep1, true, false, 0);
        Gtk.Button remove_button = new Gtk.Button.with_label(_("Remove"));
        button_box.pack_start(remove_button, true, true, 0);
        remove_button.get_child().halign = Gtk.Align.START;
        remove_button.get_child().margin_start = 0;
        remove_button.set_relief(Gtk.ReliefStyle.NONE);

        Gtk.Box rename_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        popover_stack.add(rename_box);
        rename_box.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
        rename_box.margin_start = 5;
        rename_box.margin_end = 5;
        rename_box.margin_top = 5;
        rename_box.margin_bottom = 5;
        Gtk.Entry entry = new Gtk.Entry();
        entry.set_text(workspace.get_name());
        rename_box.pack_start(entry, true, true, 0);
        Gtk.Button rename_confirm = new Gtk.Button.from_icon_name("emblem-ok-symbolic", Gtk.IconSize.MENU);
        rename_box.pack_start(rename_confirm, false, false, 0);

        rest_of_the_icons = new Gtk.FlowBox();
        rest_of_the_icons.set_max_children_per_line(4);
        rest_of_the_icons.set_orientation(Gtk.Orientation.HORIZONTAL);
        rest_of_the_icons.set_row_spacing(0);
        rest_of_the_icons.set_column_spacing(0);
        rest_of_the_icons.set_selection_mode(Gtk.SelectionMode.NONE);
        rest_of_the_icons.set_homogeneous(true);
        popover_stack.add_named(rest_of_the_icons, "icons");

        popover_box.show_all();

        Gtk.drag_dest_set(
            this,
            Gtk.DestDefaults.MOTION | Gtk.DestDefaults.HIGHLIGHT,
            target_list,
            Gdk.DragAction.MOVE
        );

        this.drag_drop.connect(on_drag_drop);
        this.drag_data_received.connect(on_drag_data_received);

        remove_button.button_release_event.connect((event) => {
            popover.hide();
            remove_workspace(workspace.get_number(), event.time);
            return false;
        });

        rename_button.clicked.connect(() => {
            popover_stack.set_visible_child(rename_box);
        });

        rename_confirm.clicked.connect(() => {
            popover.hide();
            workspace.change_name(entry.get_text());
        });

        entry.activate.connect(() => {
            popover.hide();
            workspace.change_name(entry.get_text());
        });

        popover.closed.connect(() => {
            popover_stack.set_visible_child(button_box);
            entry.set_text(workspace.get_name());
            WorkspacesApplet.manager.unregister_popover(this);
            WorkspacesApplet.dragging = false;
        });

        workspace.name_changed.connect(() => {
            this.set_tooltip_text(workspace.get_name());
            name_label.set_markup(@"<big>$(workspace.get_name())</big>");
            entry.set_text(workspace.get_name());
        });

        this.show_all();
    }

    private bool on_drag_drop(Gtk.Widget widget, Gdk.DragContext context, int x, int y, uint time)
    {
        bool is_valid_drop_site = true;

        if (context.list_targets() != null) {
            var target_type = (Gdk.Atom)context.list_targets().nth_data(0);
            Gtk.drag_get_data(
                widget,
                context,
                target_type,
                time
            );
        } else {
            is_valid_drop_site = false;
        }

        return is_valid_drop_site;
    }

    private void on_drag_data_received(Gtk.Widget widget, Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time)
    {
        bool dnd_success = false;

        ulong* data = (ulong*)selection_data.get_data();

        if (data != null) {
            Wnck.Window window = Wnck.Window.@get(*data);
            window.move_to_workspace(this.workspace);
            dnd_success = true;
        }

        Gtk.drag_finish(context, dnd_success, true, time);
    }

    public void update_windows(GLib.List<unowned Wnck.Window> window_list)
    {
        int column_offset = 0;
        int row_offset = 0;

        if (WorkspacesApplet.get_orientation() == Gtk.Orientation.HORIZONTAL) {
            column_offset = 18;
            row_offset = 5;
        } else {
            column_offset = 10;
            row_offset = 15;
        }
        int num_columns = (real_alloc.width - column_offset) / 16;
        int num_rows = (real_alloc.height - row_offset) / 16;

        if (num_columns <= 0) {
            num_columns = 1;
        }

        if (num_rows <= 0) {
            num_rows = 1;
        }

        int max_items = num_rows * num_columns;
        int num_windows = (int)window_list.length();

        int window_counter = 1;
        int row_counter = 0;
        int column_counter = 0;

        Gtk.Label more_label = new Gtk.Label("");
        more_label.get_style_context().add_class("workspace-more-label");
        more_label.set_label(@"<small>+$(num_windows - max_items + 1)</small>");
        more_label.set_use_markup(true);
        more_label.set_size_request(15, 15);

        foreach (Gtk.Widget widget in icon_grid.get_children()) {
            widget.destroy();
        }
        foreach (Gtk.Widget widget in rest_of_the_icons.get_children()) {
            widget.destroy();
        }

        window_list.@foreach((window) => {
            WindowIcon icon = new WindowIcon(window);
            if (window_counter < max_items || num_windows == max_items) {
                icon_grid.attach(icon, column_counter, row_counter);
                icon.halign = Gtk.Align.CENTER;
                icon.valign = Gtk.Align.CENTER;
            } else if (window_counter == max_items) {
                Gtk.EventBox ebox = new Gtk.EventBox();
                ebox.add(more_label);
                icon_grid.attach(ebox, column_counter, row_counter);
                ebox.show_all();
                ebox.button_press_event.connect(() => {
                    popover_stack.set_visible_child(rest_of_the_icons);
                    WorkspacesApplet.dragging = true;
                    WorkspacesApplet.manager.register_popover(this, popover);
                    WorkspacesApplet.manager.show_popover(this);
                    return true;
                });
                ebox.halign = Gtk.Align.CENTER;
                ebox.valign = Gtk.Align.CENTER;
            }

            if (window_counter >= max_items && icon.get_parent() == null) {
                rest_of_the_icons.add(icon);
            }

            window_counter++;
            column_counter++;

            if (column_counter >= num_columns) {
                column_counter = 0;
                row_counter++;
            }

            if (row_counter >= num_rows) {
                return;
            }
        });

        if (rest_of_the_icons.get_children().length() == 0) {
            popover.hide();
        }

        this.queue_resize();
    }

    public override void size_allocate(Gtk.Allocation allocation) {
        this.queue_resize();
        base.size_allocate(real_alloc);
    }

    public override bool button_release_event(Gdk.EventButton event)
    {
        if (event.button == 1) {
            var _workspace = WorkspacesApplet.wnck_screen.get_active_workspace();
            if (_workspace != null && _workspace == workspace) {
                return Gdk.EVENT_STOP;
            }
            workspace.activate(event.time);
        } else if (event.button == 3) {
            WorkspacesApplet.manager.register_popover(this, popover);
            WorkspacesApplet.manager.show_popover(this);
        } else {
            return Gdk.EVENT_PROPAGATE;
        }

        return Gdk.EVENT_STOP;
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        if (WorkspacesApplet.get_orientation() == Gtk.Orientation.VERTICAL) {
            base.get_preferred_width(out min, out nat);
            min = nat = real_alloc.width = WorkspacesApplet.panel_size;
            return;
        }
        float w_width = (float)workspace.get_width();
        float width = (w_width/workspace.get_height()) * WorkspacesApplet.panel_size;
        min = nat = (int)width;
        real_alloc.width = (int)width;
    }

    public override void get_preferred_height(out int min, out int nat) {
        base.get_preferred_height(out min, out nat);
        min = nat = real_alloc.height = WorkspacesApplet.panel_size;
    }

    public Wnck.Workspace get_workspace() {
        return workspace;
    }
}

}

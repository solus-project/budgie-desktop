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

public class WindowListItem: Gtk.Revealer, NameChangeListener
{

    private Gtk.Box layout;
    private Gtk.Button window_switch_btn;
    private Gtk.Label window_name_lbl;
    private Gtk.Button window_close_btn;

    private string window_name;
    private unowned ApplicationWindow? appwin = null;
    private unowned WindowManager? window_manager = null;
    private UrgencyAnimation urgency_animation;

    public WindowListItem(string window_name, ApplicationWindow appwin, WindowManager window_manager)
    {
        configure_window_switch_button();
        configure_window_close_button();
        urgency_animation = new UrgencyAnimation(this,
                                                 UrgencyAnimation.INFINITE_CYCLE_NUM);
        layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);

        layout.pack_start(window_switch_btn, true, true, 0);
        layout.pack_start(window_close_btn, true, true, 0);
        set_window_name(window_name);
        this.appwin = appwin;
        this.window_manager = window_manager;

        add(layout);
        set_can_focus(false);
        set_reveal_child(true);
        // allows the glow of attention animation to surround the whole element
        layout.set_border_width (1);
        show_all();
    }

    public void gracefully_die(Gtk.ListBox lsbox)
    {
        // just in case
        urgency_animation.end_animation();

        if (!get_settings().gtk_enable_animations) {
            lsbox.remove(this.get_parent());
            return;
        }

        this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
        this.notify["child-revealed"].connect_after(()=> {
            lsbox.remove(this.get_parent());
        });
        this.set_reveal_child(false);
    }

    private void configure_window_close_button()
    {
        window_close_btn = new Gtk.Button.from_icon_name("window-close",
            Gtk.IconSize.SMALL_TOOLBAR);
        window_close_btn.set_can_focus(false);

        window_close_btn.tooltip_text = _("Close window");
        window_close_btn.button_release_event.connect_after(close_window);
    }

    private void configure_window_switch_button()
    {
        window_switch_btn = new Gtk.Button();
        window_name_lbl = new Gtk.Label("");
        window_name_lbl.halign = Gtk.Align.CENTER;
        window_switch_btn.add(window_name_lbl);
        window_switch_btn.set_can_focus(false);

        window_switch_btn.button_release_event.connect_after(switch_window);
    }

    public void name_changed(ApplicationWindow appwin, string new_name)
    {
        set_window_name(new_name);
    }

    public void set_window_name(string window_name)
    {
        if (window_name.char_count() > 50) {
            this.window_name = window_name.substring(0, 46) + " ...";
        } else {
            this.window_name = window_name;
        }

        window_name_lbl.set_label(this.window_name);
        window_switch_btn.set_tooltip_text(_("Switch to window:") + window_name);
    }

    public bool switch_window(Gdk.EventButton event)
    {
        window_manager.toggle_window(appwin.get_window());
        return true;
    }

    public bool close_window(Gdk.EventButton event)
    {
        window_manager.close_window(appwin.get_window());
        return true;
    }

    public ApplicationWindow get_application_window()
    {
        return appwin;
    }

    public void begin_attention_request()
    {
        urgency_animation.begin_animation();
    }

    public void end_attention_request()
    {
        urgency_animation.end_animation();
    }

    public void add_switch_button_to_group(Gtk.SizeGroup group)
    {
        group.add_widget(window_switch_btn);
    }

    public void remove_switch_button_from_group(Gtk.SizeGroup group)
    {
        group.remove_widget(window_switch_btn);
    }
}

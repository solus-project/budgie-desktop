/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Arc
{

public class MainView : Gtk.Box
{

    /* This is completely temporary. Shush */
    private MprisWidget? mpris = null;
    private CalendarWidget? cal = null;
    private SoundWidget? sound = null;

    private Gtk.Stack? main_stack = null;
    private Gtk.StackSwitcher? switcher = null;

    public signal void view_switch();

    public void expose_notification()
    {
        main_stack.set_visible_child_name("notifications");
    }

    public MainView()
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.VERTICAL);

        var header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        header.get_style_context().add_class("raven-header");
        header.get_style_context().add_class("top");
        main_stack = new Gtk.Stack();
        pack_start(header, false, false, 0);

        /* Anim */
        main_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

        var settings = new Gtk.Button.from_icon_name("applications-system-symbolic", Gtk.IconSize.BUTTON);
        settings.clicked.connect(()=> {
            this.view_switch();
        });
        settings.margin_top = 4;
        settings.margin_bottom = 4;
        settings.margin_right = 4;
        header.pack_end(settings, false, false, 0);
        settings.valign = Gtk.Align.CENTER;

        switcher = new Gtk.StackSwitcher();
        group.add_widget(switcher);
        group.add_widget(settings);

        switcher.valign = Gtk.Align.CENTER;
        switcher.margin_top = 4;
        switcher.margin_bottom = 4;
        switcher.set_halign(Gtk.Align.CENTER);
        switcher.set_stack(main_stack);
        header.pack_start(switcher, true, true, 0);

        pack_start(main_stack, true, true, 0);

        var scroll = new Gtk.ScrolledWindow(null, null);
        main_stack.add_titled(scroll, "applets", _("Applets"));
        /* Dummy - no notifications right now */
        var not = new NotificationsView();
        main_stack.add_titled(not, "notifications", _("Notifications"));

        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        /* Eventually these guys get dynamically loaded */
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        scroll.add(box);

        cal = new CalendarWidget();
        cal.margin_top = 6;
        box.pack_start(cal, false, false, 0);

        sound = new SoundWidget();
        sound.margin_top = 6;
        box.pack_start(sound, false, false, 0);

        mpris = new MprisWidget();
        mpris.margin_top = 6;
        box.pack_start(mpris, false, false, 0);

        show_all();

        main_stack.set_visible_child_name("applets");

        main_stack.notify["visible-child-name"].connect(on_name_change);

    }

    void on_name_change()
    {
        if (main_stack.get_visible_child_name() == "notifications") {
            Raven.get_instance().ReadNotifications();
        }
    }

    public void set_clean()
    {
        main_stack.set_visible_child_name("applets");
    }
}

} /* End namespace */

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */

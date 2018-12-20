/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2018 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public class MainView : Gtk.Box
{

    /* This is completely temporary. Shush */
    private MprisWidget? mpris = null;
    private CalendarWidget? cal = null;
    private Budgie.SoundWidget? audio_input_widget = null;
    private Budgie.SoundWidget? audio_output_widget = null;
    private Settings? raven_settings = null;

    private Gtk.Stack? main_stack = null;
    private Gtk.StackSwitcher? switcher = null;

    public void expose_notification()
    {
        main_stack.set_visible_child_name("notifications");
    }

    public MainView()
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
        raven_settings = new GLib.Settings("com.solus-project.budgie-raven");
        raven_settings.changed.connect(this.on_raven_settings_changed);

        var header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        header.get_style_context().add_class("raven-header");
        header.get_style_context().add_class("top");
        main_stack = new Gtk.Stack();
        pack_start(header, false, false, 0);

        /* Anim */
        main_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        switcher = new Gtk.StackSwitcher();

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

        cal = new CalendarWidget(raven_settings);
        box.pack_start(cal, false, false, 0);

        audio_output_widget = new Budgie.SoundWidget("output");
        box.pack_start(audio_output_widget, false, false, 0);

        audio_input_widget = new Budgie.SoundWidget("input");
        box.pack_start(audio_input_widget, false, false, 0);

        mpris = new MprisWidget();
        box.pack_start(mpris, false, false, 0);

        show_all();

        main_stack.notify["visible-child-name"].connect(on_name_change);
        set_clean();
    }

    void on_name_change()
    {
        if (main_stack.get_visible_child_name() == "notifications") {
            Raven.get_instance().ReadNotifications();
        }
    }

    /**
     * on_raven_settings_changed will handle when the settings for Raven widgets have changed
     */
    void on_raven_settings_changed(string key) {
        bool show_widget = raven_settings.get_boolean(key);

        /**
         * You're probably wondering why I'm not just setting a visible value here, and that's typically a good idea.
         * However, it causes weird focus and rendering issues even when has_visible_focus is set to false. I don't get it either, so we're doing this.
         */
        if (show_widget) { // Show the widget
            switch (key) {
                case "show-calendar-widget":
                    cal.show_all();
                    break;
                case "show-sound-output-widget":
                    audio_output_widget.show_all();
                    break;
                case "show-mic-input-widget":
                    audio_input_widget.show_all();
                    break;
                case "show-mpris-widget":
                    mpris.show_all();
                    break;
            }
        } else { // Hide the widget
            switch (key) {
                case "show-calendar-widget":
                    cal.hide();
                    break;
                case "show-sound-output-widget":
                    audio_output_widget.hide();
                    break;
                case "show-mic-input-widget":
                    audio_input_widget.hide();
                    break;
                case "show-mpris-widget":
                    mpris.hide();
                    break;
            }
        }
    }

    public void set_clean()
    {
        on_raven_settings_changed("show-calendar-widget");
        on_raven_settings_changed("show-sound-output-widget");
        on_raven_settings_changed("show-mic-input-widget");
        on_raven_settings_changed("show-mpris-widget");
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

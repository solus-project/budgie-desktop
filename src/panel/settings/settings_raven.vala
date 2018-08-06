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

namespace Budgie {

/**
 * RavenPage shows options for configuring Raven
 */
public class RavenPage : Budgie.SettingsPage {
    private Gtk.Switch? allow_volume_overdrive;
    private Gtk.Switch? show_calendar_widget;
    private Gtk.Switch? show_sound_output_widget;
    private Gtk.Switch? show_mic_input_widget;
    private Gtk.Switch? show_mpris_widget;
    private GLib.Settings raven_settings;
    private GLib.Settings sound_settings;

    public RavenPage() {
        Object(group: SETTINGS_GROUP_APPEARANCE,
            content_id: "raven",
            title: _("Raven"),
            display_weight: 3,
            icon_name: "preferences-calendar-and-tasks" // Subject to change
        );

        var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
        var grid = new SettingsGrid();
        this.add(grid);

        allow_volume_overdrive = new Gtk.Switch();
        grid.add_row(new SettingsRow(allow_volume_overdrive,
            _("Allow raising volume above 100%"),
            _("Allows raising the volume via Sound Settings as well as the Sound Output Widget in Raven up to 150%.")
        ));

        show_calendar_widget = new Gtk.Switch();
        grid.add_row(new SettingsRow(show_calendar_widget,
            _("Show Calendar Widget"),
            _("Shows or hides the Calendar Widget in Raven's Applets section.")
        ));

        show_sound_output_widget = new Gtk.Switch();
        grid.add_row(new SettingsRow(show_sound_output_widget,
            _("Show Sound Output Widget"),
            _("Shows or hides the Sound Output Widget in Raven's Applets section.")
        ));

        show_mic_input_widget = new Gtk.Switch();
        grid.add_row(new SettingsRow(show_mic_input_widget,
            _("Show Microphone Input Widget"),
            _("Shows or hides the Microphone Input Widget in Raven's Applets section.")
        ));

        show_mpris_widget = new Gtk.Switch();
        grid.add_row(new SettingsRow(show_mpris_widget,
            _("Show Media Playback Controls Widget"),
            _("Shows or hides the Media Playback Controls (MPRIS) Widget in Raven's Applets section.")
        ));

        raven_settings = new GLib.Settings("com.solus-project.budgie-raven");
        raven_settings.bind("show-calendar-widget", show_calendar_widget, "active", SettingsBindFlags.DEFAULT);
        raven_settings.bind("show-sound-output-widget", show_sound_output_widget, "active", SettingsBindFlags.DEFAULT);
        raven_settings.bind("show-mic-input-widget", show_mic_input_widget, "active", SettingsBindFlags.DEFAULT);
        raven_settings.bind("show-mpris-widget", show_mpris_widget, "active", SettingsBindFlags.DEFAULT);

        sound_settings = new GLib.Settings("org.gnome.desktop.sound");
        sound_settings.bind("allow-volume-above-100-percent", allow_volume_overdrive, "active", SettingsBindFlags.DEFAULT);
    }
}

}

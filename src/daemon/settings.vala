/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2017-2018 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

[DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]
interface PowerScreen : Object {
    public abstract int32 brightness {owned get; set;}
}

/**
 * The button layout style as set in budgie
 */
public enum ButtonPosition {
    LEFT = 1 << 0,
    TRADITIONAL = 1 << 1,
}
/**
 * The SettingsManager currently only has a very simple job, and looks for
 * session wide settings changes to respond to
 */
public class SettingsManager {
    private unowned Application? _parent_app = null;
    public unowned Application parent_app {
        get { return _parent_app; }
        set { _parent_app = value; }
    }

    /**
     * All the settings
     */
    private Settings? mutter_settings = null;
    private Settings? gnome_desktop_settings = null;
    private Settings? gnome_power_settings = null;
    private PowerScreen? gnome_power_props = null;
    private Settings? gnome_session_settings = null;
    private Settings? gnome_sound_settings = null;
    private Settings? gnome_wm_settings = null;
    private Settings? raven_settings = null;
    private Settings? wm_settings = null;
    private Settings? xoverrides = null;

    /**
     * Defaults for Caffeine Mode
     */
    private int32? default_brightness = 30;
    private uint32? default_idle_delay;
    private bool? default_idle_dim;
    private string? default_sleep_inactive_ac_type;
    private string? default_sleep_inactive_battery_type;

    /**
     * Other
     */
    private string? caffeine_full_cup = "";
    private string? caffeine_empty_cup = "";
    private Notify.Notification? caffeine_notification = null;
    private bool temporary_notification_disabled = false;

    public SettingsManager() {
        Notify.init("com.solus-project.budgie-daemon"); // Attempt initialization of Notify

        set_supported_caffeine_icons(); // Set supported Caffeine icons will determine whether or not to use an IconTheme or Budgie caffeine icons

        /* Settings we need to write to */
        mutter_settings = new Settings("org.gnome.mutter");
        gnome_desktop_settings = new Settings("org.gnome.desktop.interface");
        gnome_power_settings = new Settings("org.gnome.settings-daemon.plugins.power");
        gnome_session_settings = new Settings("org.gnome.desktop.session");
        gnome_sound_settings = new Settings("org.gnome.desktop.sound");
        gnome_wm_settings = new Settings("org.gnome.desktop.wm.preferences");
        raven_settings = new Settings("com.solus-project.budgie-raven");
        xoverrides = new Settings("org.gnome.settings-daemon.plugins.xsettings");
        wm_settings = new Settings("com.solus-project.budgie-wm");

        try {
            gnome_power_props = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.SettingsDaemon.Power", "/org/gnome/SettingsDaemon/Power");
        } catch (IOError e) {
            warning("Failed to acquire bus for org.gnome.SettingsDaemon.Power: %s\n", e.message);
        }

        fetch_defaults();

        wm_settings.set_boolean("caffeine-mode", false); // Ensure Caffeine Mode is disabled by default
        enforce_mutter_settings(); // Call enforce mutter settings so we ensure we transition our Mutter settings over to BudgieWM
        raven_settings.changed["allow-volume-overdrive"].connect(this.on_raven_sound_overdrive_change);
        wm_settings.changed.connect(this.on_wm_settings_changed);
        this.on_wm_settings_changed("button-style");
    }

    /**
     * change_brightness will attempt to change our brightness in the power properties
     */
    private void change_brightness (int32 value) {
        if (this.gnome_power_props != null) {
            try {
                this.gnome_power_props.brightness = value;
            } catch {
                warning("Error: Failed to change change the brightness during Caffeine Mode toggle.");
            }
        }
    }

    /**
     * fetch_defaults will fetch the default values for various idle, sleep, and brightness settings
     */
    private void fetch_defaults() {
        default_idle_delay = gnome_session_settings.get_uint ("idle-delay");
        default_idle_dim = gnome_power_settings.get_boolean ("idle-dim");
        default_sleep_inactive_ac_type = gnome_power_settings.get_string ("sleep-inactive-ac-type");
        default_sleep_inactive_battery_type = gnome_power_settings.get_string ("sleep-inactive-battery-type");

        if (gnome_power_props != null) {
            try {
                default_brightness = gnome_power_props.brightness;
            } catch {
                warning("Could not set default value.");
            }
        }
    }

    /**
     * enforce_mutter_settings will apply Mutter schema changes to BudgieWM for supported keys
     */
    private void enforce_mutter_settings() {
        bool center_windows = mutter_settings.get_boolean("center-new-windows");
        wm_settings.set_boolean("center-windows", center_windows);
    }

    /**
     * Create a new xsettings override based on the *Existing* key so that
     * we don't dump any settings like Gdk/ScaleFactor, etc.
     */
    private Variant? new_filtered_xsetting(string button_layout)
    {
        /* These are the two new keys we want */
        var builder = new VariantBuilder(new VariantType("a{sv}"));
        builder.add("{sv}", "Gtk/ShellShowsAppMenu", new Variant.int32(0));
        builder.add("{sv}", "Gtk/DecorationLayout", new Variant.string(button_layout));

        Variant existing_vars = this.xoverrides.get_value("overrides");
        VariantIter it = existing_vars.iterator();
        string? k = null;
        Variant? v = null;
        while (it.next("{sv}", &k, &v)) {
            if (k == "Gtk/ShellShowsAppMenu" || k == "Gtk/DecorationLayout") {
                continue;
            }
            builder.add("{sv}", k, v);
        }
        return builder.end();
    }

    /**
     * do_disable is triggered when our timeout is called
     */
    private bool do_disable() {
        wm_settings.set_boolean("caffeine-mode", false);
        return false;
    }

    /**
     * do_disable_quietly will quietly disable Caffeine Mode
     */
    public void do_disable_quietly() {
        temporary_notification_disabled = true;
        wm_settings.set_boolean("caffeine-mode", false);
    }

    private void on_raven_sound_overdrive_change() {
        bool allow_volume_overdrive = raven_settings.get_boolean("allow-volume-overdrive"); // Get our overdrive value
        gnome_sound_settings.set_boolean("allow-volume-above-100-percent", allow_volume_overdrive); // Set it to allow-volume-above-100-percent
    }

    private void on_wm_settings_changed(string key)
    {
        switch (key) {
            case "button-style":
                ButtonPosition style = (ButtonPosition)wm_settings.get_enum(key);
                this.set_button_style(style);
                break;
            case "center-windows":
                bool center = wm_settings.get_boolean(key);
                mutter_settings.set_boolean("center-new-windows", center);
                break;
            case "caffeine-mode":
                bool enabled = wm_settings.get_boolean(key); // Get the caffeine mode enabled value
                this.set_caffeine_mode(enabled);
                break;
            case "focus-mode":
                bool mode = wm_settings.get_boolean(key);
                this.set_focus_mode(mode);
                break;
            default:
                break;
        }
    }

    /**
     * reset_values will reset select power and session keys
     */
    private void reset_values() {
        gnome_session_settings.set_uint("idle-delay", default_idle_delay);
        gnome_power_settings.set_boolean("idle-dim", default_idle_dim);
        gnome_power_settings.set_string("sleep-inactive-ac-type", default_sleep_inactive_ac_type);
        gnome_power_settings.set_string("sleep-inactive-battery-type", default_sleep_inactive_battery_type);
    }

    /**
     * Set the button layout to one of left or traditional
     */
    void set_button_style(ButtonPosition style)
    {
        Variant? xset = null;
        string? wm_set = null;

        switch (style) {
        case ButtonPosition.LEFT:
            xset = this.new_filtered_xsetting("close,minimize,maximize:menu");
            wm_set = "close,minimize,maximize:appmenu";
            break;
        case ButtonPosition.TRADITIONAL:
        default:
            xset = this.new_filtered_xsetting("menu:minimize,maximize,close");
            wm_set = "appmenu:minimize,maximize,close";
            break;
        }

        this.xoverrides.set_value("overrides", xset);
        this.gnome_wm_settings.set_value("button-layout", wm_set);
    }

    /**
     * set_caffeine_mode will set our various settings for caffeine mode
     */
    private void set_caffeine_mode(bool enabled, bool disable_notification = false) {
        if (enabled) { // Enable Caffeine Mode
            gnome_power_settings.set_boolean("idle-dim", false);
            gnome_power_settings.set_string("sleep-inactive-ac-type", "nothing");
            gnome_power_settings.set_string("sleep-inactive-battery-type", "nothing");
            gnome_session_settings.set_uint("idle-delay", 0);
        } else { // Disable Caffeine Mode
            reset_values(); // Reset the values
        }

        if (wm_settings.get_boolean("caffeine-mode-toggle-brightness")) { // Should toggle brightness
            int32 set_brightness = (int32) wm_settings.get_int("caffeine-mode-screen-brightness");
            change_brightness((enabled) ? set_brightness : default_brightness);
        }

        if (wm_settings.get_boolean("caffeine-mode-notification") && !disable_notification && !temporary_notification_disabled && Notify.is_initted()) { // Should show a notification
            string title = (enabled) ? _("Turned on Caffeine Boost") : _("Turned off Caffeine Boost");
            string body = "";
            string icon = (enabled) ? caffeine_full_cup : caffeine_empty_cup;

            var time = wm_settings.get_int("caffeine-mode-timer"); // Get our timer number

            if (enabled && (time > 0)) { // If Caffeine Mode is enabled and we'll turn it off in a certain amount of time
                var duration = ngettext ("a minute", "%d minutes", time).printf (time);
                body = "%s %s".printf(_("Will turn off in"), duration);

                Timeout.add_seconds(time * 60, this.do_disable, Priority.HIGH);
            }

            if (this.caffeine_notification == null) { // Caffeine Notification not yet created
                this.caffeine_notification = new Notify.Notification(title, body, icon);
                caffeine_notification.set_urgency(Notify.Urgency.CRITICAL);
            } else {
                try {
                    this.caffeine_notification.close(); // Ensure previous is closed
                } catch (Error e) {
                    warning("Failed to close previous notification: %s", e.message);
                }

                this.caffeine_notification.update(title, body, icon); // Update the Notification
            }

            try {
                this.caffeine_notification.show();
            } catch (Error e) {
                warning("Failed to send our Caffeine notification: %s", e.message);
            }
        }

        if (temporary_notification_disabled) { // If we've temporarily disabled the Notification (such as for not providing a notification during End Session DIalog opening)
            Timeout.add_seconds(60, () => { // Wait about a minute
                temporary_notification_disabled = false; // Turn back off
                return false;
            }, Priority.HIGH);
        }
    }

    /**
     * set_focus_mode will set the window focus mode
     */
    void set_focus_mode(bool enable) {
        string gfocus_mode = "click";

        if (enable) {
            gfocus_mode = "mouse";
        }

        this.gnome_wm_settings.set_value("focus-mode", gfocus_mode);
    }

    /**
     * set_supported_caffeine_icons will determine whether or not to use the current IconTheme's caffeine icons, if supported.
     * If it is not supported, it will fall back to our budgie vendored icons.
     */
    private void set_supported_caffeine_icons() {
        Gtk.IconTheme current_theme = Gtk.IconTheme.get_default();
        string full = "caffeine-cup-full";
        string empty = "caffeine-cup-empty";
        caffeine_full_cup = current_theme.has_icon(full) ? full : "budgie-" + full;
        caffeine_empty_cup = current_theme.has_icon(empty) ? empty : "budgie-" + empty;
    }

} /* End class SettingsManager (BudgieSettingsManager) */

} /* End namespace Budgie */

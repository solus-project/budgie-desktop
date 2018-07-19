const string POWER_SCHEME = "org.gnome.settings-daemon.plugins.power";
const string SESSION_SCHEME = "org.gnome.desktop.session";

[GtkTemplate (ui = "/com/solus-project/caffeine/window.ui")]
public class CaffeineWindow : Gtk.Grid
{
    [GtkChild]
    private Gtk.Switch? mode;

    [GtkChild]
    private Gtk.SpinButton? timer;

    Gtk.EventBox? event_box;
    Settings? power_settings;
    Settings? session_settings;
    Settings? settings;

    // Default configuration value
    uint32? default_idle_delay;
    bool? default_idle_dim;
    string? default_sleep_inactive_ac_type;
    string? default_sleep_inactive_battery_type;

    public CaffeineWindow (Gtk.EventBox? event_box, Settings? settings)
    {
        Object();
        this.event_box = event_box;
        this.settings = settings;

        // Get settings
        power_settings = new Settings (POWER_SCHEME);
        session_settings = new Settings (SESSION_SCHEME);
        fetch_default ();

        mode.notify["active"].connect (on_mode_active);
    }

    private void fetch_default ()
    {
        // Fetch default configuration
        default_idle_delay = session_settings.get_uint ("idle-delay");
        default_idle_dim = power_settings.get_boolean ("idle-dim");
        default_sleep_inactive_ac_type = power_settings.get_string ("sleep-inactive-ac-type");
        default_sleep_inactive_battery_type = power_settings.get_string ("sleep-inactive-battery-type");
    }

    private void send_notification (bool activate, int time)
    {
        var cmd = new StringBuilder ();
        cmd.append ("notify-send ");

        if (activate) {
            cmd.append ("\"" + _("Turn on Caffeine Boost") + "\" ");
            if (time > 0) {
                var duration = ngettext ("a minute", "%d minutes", time).printf (time);
                cmd.append ("\""+ _("Will turn off in ") + duration + "\" ");
            }
            cmd.append ("--icon=caffeine-cup-full");
        } else {
            cmd.append ("\"" + _("Turn off Caffeine Boost") + "\" ");
            cmd.append ("--icon=caffeine-cup-empty");
        }

        try {
            Process.spawn_command_line_async (cmd.str);
    	} catch (SpawnError e) {
    		print ("Error: %s\n", e.message);
    	}
    }

    private void on_mode_active (Object? obj, ParamSpec? params)
    {
        var icon = event_box.get_child ();
        event_box.remove (icon);

        var time = timer.get_value_as_int ();
        if (mode.get_active ())
        {
            // Fetch power settings default value
            fetch_default ();

            timer.sensitive = false;
            session_settings.set_uint ("idle-delay", 0);
            power_settings.set_boolean ("idle-dim", false);
            power_settings.set_string ("sleep-inactive-ac-type", "nothing");
            power_settings.set_string ("sleep-inactive-battery-type", "nothing");

            icon = new Gtk.Image.from_icon_name("caffeine-cup-full", Gtk.IconSize.MENU);
            event_box.add (icon);

            // Add timeout callback if timer's spinbox is not 0
            if (time > 0)
            {
                Timeout.add_seconds(time * 60, on_timer_out, Priority.DEFAULT);
            }
        }
        else
        {
            timer.sensitive = true;
            session_settings.set_uint ("idle-delay", default_idle_delay);
            power_settings.set_boolean ("idle-dim", default_idle_dim);
            power_settings.set_string ("sleep-inactive-ac-type", default_sleep_inactive_ac_type);
            power_settings.set_string ("sleep-inactive-battery-type", default_sleep_inactive_battery_type);

            icon = new Gtk.Image.from_icon_name("caffeine-cup-empty", Gtk.IconSize.MENU);
            event_box.add (icon);
        }

        if (settings.get_boolean ("enable-notification")) {
            send_notification(mode.get_active (), time);
        }

        event_box.show_all();
    }

    private bool on_timer_out ()
    {
        //Reset Caffeine mode and timer value
        mode.active = false;
        timer.value = 0;
        return false;
    }
}

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

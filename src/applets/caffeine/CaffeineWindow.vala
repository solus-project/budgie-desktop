const string POWER_SCHEME = "org.gnome.settings-daemon.plugins.power";
const string SESSION_SCHEME = "org.gnome.desktop.session";
const string INTERFACE_SCHEME = "org.gnome.desktop.interface";

namespace Caffeine
{

[DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]
interface PowerScreen : Object
{
    public abstract int32 brightness {owned get; set;}
}

[GtkTemplate (ui = "/com/solus-project/caffeine/window.ui")]
public class AppletWindow : Gtk.Grid
{
    [GtkChild]
    private Gtk.Switch? mode;

    [GtkChild]
    private Gtk.SpinButton? timer;

    private Gtk.EventBox? event_box;
    private Settings? power_settings;
    private Settings? session_settings;
    private Settings? settings;
    private Settings? interface_settings;
    private PowerScreen? props;

    // Default configuration variables
    private uint32? default_idle_delay;
    private bool? default_idle_dim;
    private string? default_sleep_inactive_ac_type;
    private string? default_sleep_inactive_battery_type;
    private int32? default_brightness;

    public AppletWindow (Gtk.EventBox? event_box, Settings? settings)
    {
        Object();
        this.event_box = event_box;
        this.settings = settings;

        // Get settings
        power_settings = new Settings (POWER_SCHEME);
        session_settings = new Settings (SESSION_SCHEME);
        interface_settings = new Settings (INTERFACE_SCHEME);
        try {
            props = Bus.get_proxy_sync (BusType.SESSION,
                                        "org.gnome.SettingsDaemon.Power",
                                        "/org/gnome/SettingsDaemon/Power");
        } catch (IOError e) {
            print ("Error: %s\n", e.message);
        }
        fetch_default ();

        mode.notify["active"].connect (on_mode_active);

        interface_settings.changed["icon-theme"].connect_after(on_interface_changed);
    }

    public static string get_icon_name (string find)
    {
        // find the caffeine icon name
        // if the theme does not have the icon then fallback
        // to the budgie equivalent that is installed in hicolor
        // as budgie-caffeine-cup-full/empty
        var icon_theme = Gtk.IconTheme.get_default ();
        icon_theme.rescan_if_needed();
        if (icon_theme.has_icon (find)) {
            return find;
        }

        return "budgie-" + find;
    }

    public void toggle_applet ()
    {
        mode.active = !mode.active;
    }

    private void fetch_default ()
    {
        // Fetch default configuration
        default_idle_delay = session_settings.get_uint ("idle-delay");
        default_idle_dim = power_settings.get_boolean ("idle-dim");
        default_sleep_inactive_ac_type = power_settings.get_string ("sleep-inactive-ac-type");
        default_sleep_inactive_battery_type = power_settings.get_string ("sleep-inactive-battery-type");
        try {
            default_brightness = props.brightness;
        } catch {
            print ("Error: Can't get default brightness value");
        }
    }

    private void change_brightness (int32 value)
    {
        try {
            props.brightness = value;
        } catch {
            print ("Error: Can't change the brightness");
        }
    }

    private void send_notification (bool activate, int time)
    {
        var cmd = new StringBuilder ();
        cmd.append ("notify-send ");

        if (activate) {
            cmd.append ("\"%s\" ".printf (_("Turn on Caffeine Boost")));

            if (time > 0) {
                var duration = ngettext ("a minute", "%d minutes", time).printf (time);
                cmd.append ("\"%s %s\" ".printf (_("Will turn off in"), duration));
            }
            cmd.append ("--icon=" + get_icon_name ("caffeine-cup-full"));
        } else {
            cmd.append ("\"%s\" ".printf (_("Turn off Caffeine Boost")));
            cmd.append ("--icon=" + get_icon_name ("caffeine-cup-empty"));
        }

        try {
            Process.spawn_command_line_async (cmd.str);
        } catch (SpawnError e) {
            print ("Error: %s\n", e.message);
        }
    }

    private void on_interface_changed(string key)
    {
        // called when interface schema icon-theme key is changed
        // Use a short delay to ensure GTK has had time to update
        // the icon-theme details for the screen
        Timeout.add(200, ()=> {
            // switch the caffeine icon if the theme has one defined
            // or use the budgie fallback icon
            var icon = event_box.get_child ();
            event_box.remove (icon);
            var state = mode.active ? "full" : "empty";
            string icon_name = get_icon_name ("caffeine-cup-" + state);
            icon = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.MENU);
            event_box.add (icon);
            event_box.show_all();
            return false;
        });
    }

    private void on_mode_active (Object? obj, ParamSpec? params)
    {
        var icon = event_box.get_child ();
        event_box.remove (icon);

        var time = timer.get_value_as_int();
        if (mode.active) {
            // Fetch power settings default value
            fetch_default ();

            session_settings.set_uint ("idle-delay", 0);
            power_settings.set_boolean ("idle-dim", false);
            power_settings.set_string ("sleep-inactive-ac-type", "nothing");
            power_settings.set_string ("sleep-inactive-battery-type", "nothing");

            // Add timeout callback if timer's spinbox is not 0
            if (time > 0) {
                Timeout.add_seconds(time * 60, on_timer_out, Priority.DEFAULT);
            }
        } else {
            session_settings.set_uint ("idle-delay", default_idle_delay);
            power_settings.set_boolean ("idle-dim", default_idle_dim);
            power_settings.set_string ("sleep-inactive-ac-type", default_sleep_inactive_ac_type);
            power_settings.set_string ("sleep-inactive-battery-type", default_sleep_inactive_battery_type);
        }

        if (settings.get_boolean ("enable-notification")) {
            send_notification (mode.active, time);
        }

        if (settings.get_boolean ("toggle-brightness")) {
            if (mode.active) {
                change_brightness (settings.get_int ("screen-brightness"));
            } else {
                change_brightness (default_brightness);
            }
        }

        timer.sensitive = !timer.sensitive;

        var state = mode.active ? "full" : "empty";
        string icon_name = get_icon_name ("caffeine-cup-" + state);
        icon = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.MENU);
        event_box.add (icon);

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

} // End namespace

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

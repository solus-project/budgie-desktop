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
    Variant? defaults;

    public CaffeineWindow (Gtk.EventBox? event_box)
    {
        Object();
        this.event_box = event_box;

        // Get settings
        power_settings = new Settings (POWER_SCHEME);
        session_settings = new Settings (SESSION_SCHEME);
        fetch_default ();

        mode.notify["active"].connect (on_mode_active);
    }

    private void fetch_default ()
    {
        var builder = new VariantBuilder (new VariantType ("a{sv}"));
        builder.add ("{sv}", "idle-delay", new Variant.uint32(
            session_settings.get_uint ("idle-delay")));
        builder.add ("{sv}", "idle-dim", new Variant.boolean(
            power_settings.get_boolean ("idle-dim")));
        builder.add ("{sv}", "sleep-inactive-ac-type", new Variant.string(
            power_settings.get_string ("sleep-inactive-ac-type")));
        builder.add ("{sv}", "sleep-inactive-battery-type", new Variant.string(
            power_settings.get_string ("sleep-inactive-battery-type")));

        defaults = builder.end ();
    }

    private void on_mode_active (Gtk.Switch? mode)
    {
        var icon = event_box.get_child ();
        event_box.remove (icon);

        var time = timer.get_value_as_int();
        if (mode.get_active ())
        {
            // Fetch power settings default value
            fetch_default ();

            timer.sensitive = false;
            session_settings.set_uint ("idle-delay", 0);
            power_settings.set_boolean ("idle-dim", false);
            power_settings.set_string ("sleep-inactive-ac-type", "nothing");
            power_settings.set_string ("sleep-inactive-battery-type", "nothing");

            icon = Gtk.Image.from_icon_name("caffeine-cup-full", Gtk.IconSize.MENU);
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
            session_settings.set_uint ("idle-delay",
                defaults.lookup_value ("idle-delay", VariantType ("u")));
            power_settings.set_boolean ("idle-dim",
                defaults.lookup_value ("idle-dim", VariantType ("b")));
            power_settings.set_string ("sleep-inactive-ac-type",
                defaults.lookup_value ("sleep-inactive-ac-type", VariantType ("s")));
            power_settings.set_string ("sleep-inactive-battery-type",
                defaults.lookup_value ("sleep-inactive-battery-type", VariantType ("s")));

            icon = Gtk.Image.from_icon_name("caffeine-cup-empty", Gtk.IconSize.MENU);
            event_box.add (icon);
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

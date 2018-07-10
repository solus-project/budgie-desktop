[GtkTemplate (ui = "/com/solus-project/caffeine/settings.ui")]
public class CaffeineSettings : Gtk.Grid
{
    Settings? settings = null;

    [GtkChild]
    private Gtk.Switch? notify_switch;

    [GtkChild]
    private Gtk.Switch? brightness_switch;

    [GtkChild]
    private Gtk.SpinButton? brightness_level;

    public CaffeineSettings(Settings? settings)
    {
        Object();
        this.settings = settings;
        settings.bind("size", spinbutton_size, "value", SettingsBindFlags.DEFAULT);

        // Bind settings to widget value
        setting.bind("enable-notification", notify_switch, "active",
            SettingsBindFlags.DEFAULT);
        setting.bind("maximize-brightness", brightness_switch, "active",
            SettingsBindFlags.DEFAULT);
        setting.bind("screen-brightness", brightness_level, "value",
            SettingsBindFlags.DEFAULT);
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

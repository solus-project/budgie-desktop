namespace Caffeine
{

[GtkTemplate (ui = "/com/solus-project/caffeine/settings.ui")]
public class AppletSettings : Gtk.Grid
{
    private Settings? settings = null;

    [GtkChild]
    private Gtk.Switch? notify_switch;

    [GtkChild]
    private Gtk.Switch? brightness_switch;

    [GtkChild]
    private Gtk.SpinButton? brightness_level;

    public AppletSettings(Settings? settings)
    {
        Object();
        this.settings = settings;

        // Bind settings to widget value
        settings.bind("enable-notification", notify_switch, "active",
            SettingsBindFlags.DEFAULT);
        settings.bind("toggle-brightness", brightness_switch, "active",
            SettingsBindFlags.DEFAULT);
        settings.bind("screen-brightness", brightness_level, "value",
            SettingsBindFlags.DEFAULT);
    }
}
} //End namespace

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

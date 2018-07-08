namespace Caffeine
{

[GtkTemplate (ui = "/com/solus-project/caffeine/window.ui")]
public class Window : Gtk.Grid
{
    [GtkChild]
    Gtk.Switch? mode;

    [GtkChild]
    Gtk.SpinButton? timer;

    public Window ()
    {
        Object();
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

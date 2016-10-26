namespace Budgie {
    [CCode (cheader_filename = "BudgieRaven.h")]
    public class Raven : Gtk.Window {
        public Raven(Budgie.DesktopManager manager);
        public void update_geometry(Gdk.Rectangle rect, Budgie.Toplevel? top, Budgie.Toplevel? bottom);
        public void setup_dbus();
    }
}

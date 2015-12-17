namespace Arc {
    [CCode (cheader_filename = "ArcRaven.h")]
    public class Raven : Gtk.Window {
        public Raven(Arc.DesktopManager manager);
        public void update_geometry(Gdk.Rectangle rect, Arc.Toplevel? top, Arc.Toplevel? bottom);
        public void setup_dbus();
    }
}

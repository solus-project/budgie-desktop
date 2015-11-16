namespace Arc {
    [CCode (cheader_filename = "ArcRaven.h")]
    public class Raven : Gtk.Window {
        public Raven();
        public void update_geometry(Gdk.Rectangle rect, Arc.Toplevel? top, Arc.Toplevel? bottom);
    }
}

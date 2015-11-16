namespace Arc {
    [CCode (cheader_filename = "ArcToplevel.h")]
    public abstract class Toplevel : Gtk.Window {
        public int shadow_width {  set ; get; }
    }
}

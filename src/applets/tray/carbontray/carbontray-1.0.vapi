namespace Carbon {
    [Compact]
    [CCode (cheader_filename = "tray.h")]
	public class Tray : GLib.Object {
        [CCode (has_construct_function = false, type = "GtkWidget*")]
        public Tray(Gtk.Orientation orientation, int iconSize, int spacing);

        public void add_to_container(Gtk.Container container);

        public void remove_from_container(Gtk.Container container);
        
        public bool register(Gdk.X11.Screen screen);

        public void unregister();

        public void set_spacing(int spacing);
    }
}

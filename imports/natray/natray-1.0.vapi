namespace Na {
	[CCode (cheader_filename = "na-tray.h")]
	public class Tray : Gtk.Bin {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public Tray();
		[CCode (has_construct_function = false, type = "GtkWidget*")]
        public Tray.for_screen(Gdk.Screen screen, Gtk.Orientation orientation);

        public void set_orientation(Gtk.Orientation orientation);
        public Gtk.Orientation get_orientation(Gtk.Orientation orientation);

        public void set_padding(int padding);
        public void set_icon_size(int icon_size);

        public void set_colors(Gdk.Color fg, Gdk.Color error, Gdk.Color warning, Gdk.Color success);

        public void force_redraw();
	}
}

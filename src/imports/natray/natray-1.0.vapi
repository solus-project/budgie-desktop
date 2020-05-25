namespace Na {
	[CCode (cheader_filename = "na-grid.h")]
	public class Grid : Gtk.Bin {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public Grid(Gtk.Orientation orientation);

        public void set_min_icon_size(int icon_size);
	}
}

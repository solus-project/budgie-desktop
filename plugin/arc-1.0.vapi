namespace Arc {
	[CCode (cheader_filename = "ArcPlugin.h")]
	public interface Plugin : GLib.Object {
		public abstract Arc.Applet get_panel_widget ();
	}
	[CCode (cheader_filename = "ArcPlugin.h")]
	public class Applet : Gtk.Bin {
        public Applet();

        public virtual unowned GLib.HashTable<Gtk.Widget?,Gtk.Popover?>? get_popovers();
	}
}

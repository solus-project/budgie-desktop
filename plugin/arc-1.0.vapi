namespace Arc {
    [CCode (cheader_filename = "ArcPlugin.h")]
    public interface PopoverManager : GLib.Object
    {
        public abstract void register_popover(Gtk.Widget? widget, Gtk.Popover? popover);
        public abstract void unregister_popover(Gtk.Widget? widget);
    }
    [CCode (cheader_filename = "ArcPlugin.h")]
    public interface Plugin : GLib.Object {
        public abstract Arc.Applet get_panel_widget ();
    }
    [CCode (cheader_filename = "ArcPlugin.h")]
    public class Applet : Gtk.Bin {
        public Applet();

        public virtual void update_popovers(Arc.PopoverManager? manager) { }
    }
}

namespace Arc {
    [CCode (cheader_filename = "ArcToplevel.h")]
    public abstract class Toplevel : Gtk.Window {
        public int shadow_width {  set ; get; }
        public int intended_size { set ; get; }
        public int shadow_depth { set ;  get; }
    }

    [CCode (cheader_filename = "ArcToplevel.h")]
    [Flags]
    public enum PanelPosition {
        NONE,
        BOTTOM,
        TOP,
        LEFT,
        RIGHT
    }

    [CCode (cheader_filename = "ArcToplevel.h")]
    [Flags]
    public enum AppletPackType {
        START,
        END
    }

    [CCode (cheader_filename = "ArcToplevel.h")]
    [Flags]
    public enum AppletAlignment {
        START,
        CENTER,
        END
    }
    [CCode (cheader_filename = "ArcToplevel.h")]
    public static void set_struts(Gtk.Window? window, PanelPosition position, long panel_size);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public class ShadowBlock : Gtk.EventBox
    {
        public ShadowBlock(PanelPosition position);
        public PanelPosition position { set; get; }
        public int required_size { set; get; }
    }
}

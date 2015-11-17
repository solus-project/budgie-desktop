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

    [CCode (cheader_filename = "ArcToplevel.h")]
    public delegate double TweenFunc(double factor);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public delegate void AnimCompletionFunc(Animation? src);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public struct PropChange {
        string property
        Value old
        Value @new;
    }

    [CCode (cheader_filename = "ArcToplevel.h")]
    public class Animation : Object {
        public int64 start_time;
        public int64 length;
        public unowned TweenFunc tween;
        public PropChange[] changes;
        public unowned Gtk.Widget widget;
        public GLib.Object? object;
        public uint id;
        public bool can_anim;
        public int64 elapsed;
        public bool no_reset;

        public void start(AnimCompletionFunc? compl);
        public void stop();
    }

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double sine_ease_in_out(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double sine_ease_in(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double sine_ease_out(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double elastic_ease_in(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double elastic_ease_out(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double back_ease_in(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double back_ease_out(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double expo_ease_in(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double expo_ease_out(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double quad_ease_in(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double quad_ease_out(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double quad_ease_in_out(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double circ_ease_in(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static double circ_ease_out(double p);

    [CCode (cheader_filename = "ArcToplevel.h")]
    public static const int64 MSECOND;
}

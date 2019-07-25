namespace Clutter {
  [CCode (type_id = "CLUTTER_TYPE_ACTOR_BOX", cheader_filename = "clutter/clutter.h")]
  public struct ActorBox {
    [CCode (cname = "clutter_actor_box_from_vertices")]
    public ActorBox.from_vertices (Clutter.Vertex[] verts);
  }

  public struct Matrix : Cogl.Matrix {
  }

  public class Backend : GLib.Object {
    [NoWrapper]
    public virtual void add_options (GLib.OptionGroup group);
    [NoWrapper]
    public virtual bool create_context () throws GLib.Error;
    [NoWrapper]
    public virtual unowned Clutter.StageWindow create_stage (Clutter.Stage wrapper) throws GLib.Error;
    [NoWrapper]
    public virtual void ensure_context (Clutter.Stage stage);
    [NoWrapper]
    public virtual unowned Clutter.DeviceManager get_device_manager ();
    [NoWrapper]
    public virtual Clutter.FeatureFlags get_features ();
    [NoWrapper]
    public virtual void init_events ();
    [NoWrapper]
    public virtual void init_features ();
    [NoWrapper]
    public virtual bool post_parse () throws GLib.Error;
    [NoWrapper]
    public virtual bool pre_parse () throws GLib.Error;
    [NoWrapper]
    public virtual void redraw (Clutter.Stage stage);
  }

  [CCode (cheader_filename = "clutter/clutter.h", type_id = "clutter_box_get_type ()")]
  public class Box : Clutter.Actor {
    public Clutter.LayoutManager layout_manager { get; set; }
  }

  [CCode (type_id = "CLUTTER_TYPE_COLOR", cheader_filename = "clutter/clutter.h")]
  public struct Color {
    [CCode (cname = "clutter_color_from_hls")]
    public Color.from_hls (float hue, float luminance, float saturation);
    [CCode (cname = "clutter_color_from_pixel")]
    public Color.from_pixel (uint32 pixel);
    [CCode (cname = "clutter_color_from_string")]
    public Color.from_string (string str);
    [CCode (cname = "clutter_color_from_string")]
    public bool parse_string (string str);
    public static unowned Clutter.Color? get_static (Clutter.StaticColor color);
  }

  [CCode (cheader_filename = "clutter/clutter.h", type_id = "clutter_container_get_type ()")]
  public interface Container : GLib.Object {
    public void add (params Clutter.Actor[] actors);
    [CCode (cname = "clutter_container_class_find_child_property")]
    public class unowned GLib.ParamSpec find_child_property (string property_name);
    [CCode (cname = "clutter_container_class_list_child_properties")]
    public class unowned GLib.ParamSpec[] list_child_properties ();
  }

  [CCode (cheader_filename = "clutter/clutter.h", copy_function = "g_boxed_copy", free_function = "g_boxed_free", type_id = "clutter_event_get_type ()")]
  [Compact]
  public class Event {
    public Clutter.AnyEvent any { [CCode (cname = "(ClutterAnyEvent *)")] get; }
    public Clutter.ButtonEvent button { [CCode (cname = "(ClutterButtonEvent *)")] get; }
    public Clutter.CrossingEvent crossing { [CCode (cname = "(ClutterCrossingEvent *)")] get; }
    public Clutter.KeyEvent key { [CCode (cname = "(ClutterKeyEvent *)")] get; }
    public Clutter.MotionEvent motion { [CCode (cname = "(ClutterMotionEvent *)")] get; }
    public Clutter.ScrollEvent scroll { [CCode (cname = "(ClutterScrollEvent *)")] get; }
    public Clutter.StageStateEvent stage_state { [CCode (cname = "(ClutterStageStateEvent *)")] get; }
    public Clutter.TouchEvent touch { [CCode (cname = "(ClutterTouchEvent *)")] get; }
    public Clutter.TouchpadPinchEvent touchpad_pinch { [CCode (cname = "(ClutterTouchpadPinchEvent *)")] get; }
    public Clutter.TouchpadSwipeEvent touchpad_swipe { [CCode (cname = "(ClutterTouchpadSwipeEvent *)")] get; }
  }

  [CCode (type_id = "clutter_stage_get_type ()", cheader_filename = "clutter/clutter.h")]
  public class Stage : Clutter.Group {
    [CCode (cname = "clutter_redraw")]
    public void redraw ();
  }

  [CCode (cheader_filename = "clutter/clutter.h")]
  public interface StageWindow : GLib.Object {
    [NoWrapper]
    public abstract void add_redraw_clip (Clutter.Geometry stage_rectangle);
    [NoWrapper]
    public abstract void get_geometry (Clutter.Geometry geometry);
    [NoWrapper]
    public abstract int get_pending_swaps ();
    [NoWrapper]
    public abstract unowned Clutter.Actor get_wrapper ();
    [NoWrapper]
    public abstract bool has_redraw_clips ();
    [NoWrapper]
    public abstract void hide ();
    [NoWrapper]
    public abstract bool ignoring_redraw_clips ();
    [NoWrapper]
    public abstract bool realize ();
    [NoWrapper]
    public abstract void resize (int width, int height);
    [NoWrapper]
    public abstract void set_cursor_visible (bool cursor_visible);
    [NoWrapper]
    public abstract void set_fullscreen (bool is_fullscreen);
    [NoWrapper]
    public abstract void set_title (string title);
    [NoWrapper]
    public abstract void set_user_resizable (bool is_resizable);
    [NoWrapper]
    public abstract void show (bool do_raise);
    [NoWrapper]
    public abstract void unrealize ();
  }

  [CCode (type_id = "clutter_texture_get_type ()", cheader_filename = "clutter/clutter.h")]
  public class Texture : Clutter.Actor {
    public Cogl.Material cogl_material { get; set; }
    public Cogl.Texture cogl_texture { get; set; }
  }

  [Compact]
  [CCode (cheader_filename = "clutter/clutter.h")]
  public class TimeoutPool {
    [CCode (has_construct_function = false)]
    public TimeoutPool (int priority);
  }

  [CCode (cprefix = "CLUTTER_FEATURE_", cheader_filename = "clutter/clutter.h")]
  [Flags]
  public enum FeatureFlags {
    TEXTURE_NPOT;
    [CCode (cname = "clutter_feature_available")]
    public bool is_available ();
    [CCode (cname = "clutter_feature_get_all")]
    public static Clutter.FeatureFlags @get ();
  }

  [CCode (type_id = "CLUTTER_TYPE_UNITS", cheader_filename = "clutter/clutter.h")]
  public struct Units {
    [CCode (cname = "clutter_units_from_cm")]
    public Units.from_cm (float cm);
    [CCode (cname = "clutter_units_from_em")]
    public Units.from_em (float em);
    [CCode (cname = "clutter_units_from_em_for_font")]
    public Units.from_em_for_font (string font_name, float em);
    [CCode (cname = "clutter_units_from_mm")]
    public Units.from_mm (float mm);
    [CCode (cname = "clutter_units_from_pixels")]
    public Units.from_pixels (int px);
    [CCode (cname = "clutter_units_from_pt")]
    public Units.from_pt (float pt);
    [CCode (cname = "clutter_units_from_string")]
    public Units.from_string (string str);
  }
}

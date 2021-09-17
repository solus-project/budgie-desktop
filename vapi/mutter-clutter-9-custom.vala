namespace Clutter {

	public struct Color {
		public bool parse_string (string str);
	}

	public interface Container : GLib.Object {
		public void add (params Clutter.Actor[] actors);
		[CCode (cname = "clutter_container_class_find_child_property")]
		public class unowned GLib.ParamSpec find_child_property (string property_name);
		[CCode (cname = "clutter_container_class_list_child_properties")]
		public class unowned GLib.ParamSpec[] list_child_properties ();
	}

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

	[CCode (cheader_filename = "clutter/clutter.h", has_copy_function = false, has_destroy_function = false, has_type_id = false)]
	public struct Capture {
	}
}

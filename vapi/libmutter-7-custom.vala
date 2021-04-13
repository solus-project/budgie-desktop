[CCode (has_type_id = false)]
public struct before_frame {
}

[CCode (has_type_id = false)]
public struct frame {
}

namespace Meta {
	[CCode (cheader_filename = "meta/meta-backend.h", type_id = "meta_backend_get_type ()")]
	public abstract class Backend : GLib.Object, GLib.Initable {
        public unowned Meta.Settings get_settings ();
    }
}
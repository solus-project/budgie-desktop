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

    [CCode (cheader_filename = "meta/meta-context.h", type_id = "meta_context_get_type ()")]
    public class Context : GLib.Object {
    	[CCode (cname = "meta_context_configure")]
	public bool configure_args ([CCode (array_length_pos = 0.9)] ref unowned string[] argv) throws GLib.Error;
    }
}

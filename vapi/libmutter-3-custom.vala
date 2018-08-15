namespace Meta {
	public abstract class MonitorManager : Meta.DBusDisplayConfigSkeleton, GLib.DBusInterface {
		/* not exported */
		public signal void monitors_changed ();
	}
}

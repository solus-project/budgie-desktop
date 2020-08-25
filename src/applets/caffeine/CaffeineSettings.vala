namespace Caffeine {
	[GtkTemplate (ui = "/com/solus-project/caffeine/settings.ui")]
	public class AppletSettings : Gtk.Grid {
		private Settings? settings = null;
		private Settings? wm_settings = null;

		[GtkChild]
		private Gtk.Switch? notify_switch;

		[GtkChild]
		private Gtk.Switch? brightness_switch;

		[GtkChild]
		private Gtk.SpinButton? brightness_level;

		public AppletSettings(Settings? settings) {
			Object();
			this.settings = settings;
			this.wm_settings = new Settings("com.solus-project.budgie-wm");

			// Bind settings to widget value
			wm_settings.bind("caffeine-mode-notification", notify_switch, "active", SettingsBindFlags.DEFAULT);
			wm_settings.bind("caffeine-mode-toggle-brightness", brightness_switch, "active", SettingsBindFlags.DEFAULT);
			wm_settings.bind("caffeine-mode-screen-brightness", brightness_level, "value", SettingsBindFlags.DEFAULT);
		}
	}
}

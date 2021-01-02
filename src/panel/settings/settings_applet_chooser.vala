/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {
	/**
	* PluginItem is used to represent a plugin for the user to add to their
	* panel through the Applet API
	*/
	public class PluginItem : Gtk.Grid {
		/**
		* We're bound to the info
		*/
		public unowned Peas.PluginInfo? plugin { public get ; construct set; }

		private Gtk.Image image;
		private Gtk.Label label;
		private Gtk.Label desc;

		/**
		* Construct a new PluginItem for the given applet
		*/
		public PluginItem(Peas.PluginInfo? info) {
			Object(plugin: info);

			get_style_context().add_class("plugin-item");

			margin_top = 4;
			margin_bottom = 4;

			image = new Gtk.Image.from_icon_name(info.get_icon_name(), Gtk.IconSize.LARGE_TOOLBAR);
			image.pixel_size = 32;
			image.margin_start = 12;
			image.margin_end = 14;

			label = new Gtk.Label(info.get_name());
			label.margin_end = 18;
			label.halign = Gtk.Align.START;

			desc = new Gtk.Label(info.get_description());
			desc.margin_top = 4;
			desc.halign = Gtk.Align.START;
			desc.set_property("xalign", 0.0);
			desc.get_style_context().add_class("dim-label");

			attach(image, 0, 0, 1, 2);
			attach(label, 1, 0, 1, 1);
			attach(desc, 1, 1, 1, 1);

			this.show_all();
		}
	}

	/**
	* AppletChooser provides a dialog to allow selection of an
	* applet to be added to a panel
	*/
	public class AppletChooser : Gtk.Dialog {
		Gtk.ListBox applets;
		Gtk.Widget button_ok;

		private string? applet_id = null;

		public AppletChooser(Gtk.Window parent) {
			Object(use_header_bar: 1,
				modal: true,
				title: _("Choose an applet"),
				transient_for: parent);

			Gtk.Box content_area = get_content_area() as Gtk.Box;

			this.add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
			button_ok = this.add_button(_("Add applet"), Gtk.ResponseType.ACCEPT);
			button_ok.set_sensitive(false);
			button_ok.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);

			var scroll = new Gtk.ScrolledWindow(null, null);
			scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			applets = new Gtk.ListBox();
			applets.set_activate_on_single_click(false);
			applets.set_sort_func(this.sort_applets);
			scroll.add(applets);

			applets.row_selected.connect(row_selected);
			applets.row_activated.connect(row_activated);

			content_area.pack_start(scroll, true, true, 0);
			content_area.show_all();

			set_default_size(400, 450);
		}

		/**
		* Simple accessor to get the new applet ID to be added
		*/
		public new string? run() {
			Gtk.ResponseType resp = (Gtk.ResponseType)base.run();
			switch (resp) {
				case Gtk.ResponseType.ACCEPT:
					return this.applet_id;
				case Gtk.ResponseType.CANCEL:
				default:
					return null;
			}
		}

		/**
		* Super simple sorting of applets in alphabetical listing
		*/
		int sort_applets(Gtk.ListBoxRow? a, Gtk.ListBoxRow? b) {
			Peas.PluginInfo? infoA = ((PluginItem) a.get_child()).plugin;
			Peas.PluginInfo? infoB = ((PluginItem) b.get_child()).plugin;

			return strcmp(infoA.get_name().down(), infoB.get_name().down());
		}

		/**
		* User picked a plugin
		*/
		void row_selected(Gtk.ListBoxRow? row) {
			if (row == null) {
				this.applet_id = null;
				this.button_ok.set_sensitive(false);
				return;
			}

			this.button_ok.set_sensitive(true);

			/* TODO: Switch name -> module_name */
			this.applet_id = ((PluginItem) row.get_child()).plugin.get_name();
		}

		/**
		* Special sauce to allow us to double-click activate an applet
		*/
		void row_activated(Gtk.ListBoxRow? row) {
			this.row_selected(row);

			if (this.applet_id != null) {
				this.response(Gtk.ResponseType.ACCEPT);
			}
		}

		/**
		* Set the available plugins to show in the dialog
		*/
		public void set_plugin_list(List<Peas.PluginInfo?> plugins) {
			foreach (var child in applets.get_children()) {
				child.destroy();
			}

			foreach (var plugin in plugins) {
				this.add_plugin(plugin);
			}
			this.applets.invalidate_sort();
		}

		/**
		* Add a new plugin to our display area
		*/
		void add_plugin(Peas.PluginInfo? plugin) {
			this.applets.add(new PluginItem(plugin));
		}
	}
}

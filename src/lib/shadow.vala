/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Budgie {
	/**
	* Alternative to a separator, gives a shadow effect
	*/
	public class ShadowBlock : Gtk.EventBox {
		private PanelPosition pos;
		private bool horizontal = false;
		int rm = 0;

		public PanelPosition position {
			public set {
				var old = pos;
				pos = value;
				update_position(old);
			}
			public get {
				return pos;
			}
		}

		private bool _active = true;

		// Allow making the shadow disappear but still use space
		public bool active {
			public set {
				this._active = value;
				if (this._active) {
					get_style_context().add_class("shadow-block");
					get_style_context().remove_class("budgie-container");
				} else {
					get_style_context().remove_class("shadow-block");
					get_style_context().add_class("budgie-container");
				}
			}
			public get {
				return this._active;
			}
		}


		void update_position(PanelPosition? old) {
			if (pos == PanelPosition.TOP || pos == PanelPosition.BOTTOM) {
				horizontal = true;
			} else {
				horizontal = false;
			}
			queue_resize();
		}

		public ShadowBlock(PanelPosition position) {
			this.active = true;
			this.position = position;
		}

		public override void get_preferred_height(out int min, out int nat) {
			if (horizontal) {
				min = 5;
				nat = 5;
				return;
			};
			min = nat = rm;
		}

		public override void get_preferred_height_for_width(int width, out int min, out int nat) {
			if (horizontal) {
				min = 5;
				nat = 5;
				return;
			}
			min = nat = rm;
		}

		public override void get_preferred_width(out int min, out int nat) {
			if (horizontal) {
				min = nat = rm;
				return;
			}
			min = nat = 5;
		}

		public override void get_preferred_width_for_height(int height, out int min, out int nat) {
			if (horizontal) {
				min = nat = rm;
				return;
			}
			min = nat = 5;
		}
	}
}

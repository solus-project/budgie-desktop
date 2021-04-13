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

/**
 * The wrapper provides nice visual effects to house an IconButton, allowing
 * us to slide the buttons into view when ready, and dispose of them as and
 * when our slide-out animation has finished. Without the wrapper, we'd have
 * a very ugly effect of icons just "popping" off.
 */
public class ButtonWrapper : Gtk.Revealer {
	public unowned IconButton? button;

	public ButtonWrapper(IconButton? button) {
		this.button = button;
		this.add(button);
		this.set_reveal_child(false);
		this.show_all();
	}

	public Gtk.Orientation orient {
		set {
			if (value == Gtk.Orientation.VERTICAL) {
				this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
			} else {
				this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);
			}
		}
		get {
			if (this.get_transition_type() == Gtk.RevealerTransitionType.SLIDE_DOWN) {
				return Gtk.Orientation.VERTICAL;
			}
			return Gtk.Orientation.HORIZONTAL;
		}
	}

	public void gracefully_die() {
		if (!get_settings().gtk_enable_animations) {
			this.hide();
			this.destroy();
			return;
		}

		if (this.orient == Gtk.Orientation.HORIZONTAL) {
			this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_LEFT);
		} else {
			this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
		}

		this.notify["child-revealed"].connect_after(() => {
			this.hide();
			this.destroy();
		});

		this.set_reveal_child(false);
	}
}

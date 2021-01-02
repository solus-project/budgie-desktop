/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace BudgieTaskList {
	/** Apply tween to animation completion factor (0.0-1.0) */
	public delegate double TweenFunc(double factor);

	/** Callback for animation completion */
	public delegate void AnimCompletionFunc(Animation? src);

	/** Animate a GObject property */
	public struct PropChange {
		string property; /**<GObject property name */
		Value old; /**<Value pre-animation */
		Value @new; /**<Target value for end of animation */
	}

	/**
	* Utility to struct to enable easier animations
	* Inspired by Clutter.
	*/
	[Compact]
	public class Animation : GLib.Object {
		public int64 start_time; /**<Start time (microseconds) of animation */
		public int64 length; /**<Length of animation in microseconds */
		public unowned TweenFunc tween; /**<Tween function to use for property changes */
		public PropChange[] changes; /**<Group of properties to change in this animation */
		public unowned Gtk.Widget widget;/**<Rendering widget that owns the Gdk.FrameClock */
		public Object? object; /**<Widget to apply property changes to */
		public uint id; /**<Idle source ID */
		public bool can_anim; /**<Whether we can animate ?*/
		public int64 elapsed; /**<Elapsed time */
		public bool no_reset; /**<Used sometimes for switching an animation*/
		private unowned AnimCompletionFunc compl;

		private bool tick_callback(Gtk.Widget widget, Gdk.FrameClock frame) {
			int64 time = frame.get_frame_time();
			float factor = 0.0f;
			var elapsed = time - start_time;

			/* Bail out of the animation, set it to its maximum */
			if (elapsed >= length || id == 0 || !can_anim) {
				if (id > 0) {
					foreach (var p in changes) {
						if (object == null) {
							widget.set_property(p.property, p.@new);
						} else {
							object.set_property(p.property, p.@new);
						}
					}
				}
				id = 0;
				if (can_anim) {
					can_anim = false;
					if (compl != null) {
						compl(this);
					}
				}
				widget.queue_draw();
				return false;
			}

			factor = ((float)elapsed / length).clamp(0, 1.0f);
			foreach (var c in changes) {
				var old = c.old.get_double();
				var @new = c.@new.get_double();

				if (tween != null) {
					/* Drop precision here, start with double we loose it exponentially. */
					factor = (float)tween((double)factor);
				}

				var delta = (@new-old) * factor;
				var nprop = (double)(old + delta);
				if (object == null) {
					widget.set_property(c.property, nprop);
				} else {
					object.set_property(c.property, nprop);
				}
			}

			widget.queue_draw();
			return can_anim;
		}


		/**
		* Start this animation by attaching ourselves to the GdkFrameClock
		*
		* @param compl A completion callback to execute when this animation completes
		*/
		public void start(AnimCompletionFunc? compl) {
			if (!no_reset) {
				start_time = widget.get_frame_clock().get_frame_time();
			}
			this.compl = compl;
			can_anim = true;
			id = widget.add_tick_callback(this.tick_callback);
		}


		/**
		* Stop a running animation
		*/
		public void stop() {
			can_anim = false;
			if (id != 0) {
				widget.remove_tick_callback(id);
			}
			id = 0;
		}
	}
	/* These easing functions originally came from
	* https://github.com/warrenm/AHEasing/blob/master/AHEasing/easing.c
	* and are available under the terms of the WTFPL
	*/

	public static double sine_ease_in_out(double p) {
		return 0.5 * (1 - Math.cos(p * Math.PI));
	}

	public static double sine_ease_in(double p) {
		return Math.sin((p - 1) * Math.PI_2) + 1;
	}

	public static double sine_ease_out(double p) {
		return Math.sin(p * Math.PI_2);
	}

	public static double elastic_ease_in(double p) {
		return Math.sin(13 * Math.PI_2 * p) * Math.pow(2, 10 * (p - 1));
	}

	public static double elastic_ease_out(double p) {
		return Math.sin(-13 * Math.PI_2 * (p + 1)) * Math.pow(2, -10 * p) + 1;
	}

	public static double back_ease_in(double p) {
		return p * p * p - p * Math.sin(p * Math.PI);
	}

	public static double back_ease_out(double p) {
		double f = (1 - p);
		return 1 - (f * f * f - f * Math.sin(f * Math.PI));
	}

	public static double expo_ease_in(double p) {
		return (p == 0.0) ? p : Math.pow(2, 10 * (p - 1));
	}

	public static double expo_ease_out(double p) {
		return (p == 1.0) ? p : 1 - Math.pow(2, -10 * p);
	}

	public static double quad_ease_in(double p) {
		return p * p;
	}

	public static double quad_ease_out(double p) {
		return -(p * (p - 2));
	}

	public static double quad_ease_in_out(double p) {
		return p < 0.5 ? (2 * p * p) : (-2 * p * p) + (4 * p) - 1;
	}

	public static double circ_ease_in(double p) {
		return 1 - Math.sqrt(1 - (p * p));
	}

	public static double circ_ease_out(double p) {
		return Math.sqrt((2 - p) * p);
	}

	public const int64 MSECOND = 1000;
}

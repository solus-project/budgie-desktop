/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017-2018 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const int MAX_CYCLES = 12;

public class Icon : Gtk.DrawingArea
{
    public Gdk.Pixbuf? pixbuf = null;
    private int size = 24;
    private int widget_width = 36;
    private int widget_height = 30;
    private Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;
    public bool waiting = false;
    private int wait_cycle_counter = 0;
    private int attention_cycle_counter = 0;

    private double bounce_amount = 0;
    private double attention_amount = 0;

    public double bounce {
        public set {
            bounce_amount = value;
            this.queue_draw();
        }
        public get {
            return bounce_amount;
        }
        default = 0.0;
    }

    public double attention {
        public set {
            attention_amount = value;
            this.queue_draw();
        }
        public get {
            return attention_amount;
        }
        default = 0.0;
    }

    public double icon_opacity {
        public set {
            if (waiting) {
                opacity = value;
            } else {
                opacity = 1.0;
            }
        }
        public get {
            return opacity;
        }
        default = 1.0;
    }

    public Icon() {}

    public Icon.from_gicon(GLib.Icon icon, int pixel_size) {
        set_from_gicon(icon, pixel_size);
    }

    public Icon.from_pixbuf(Gdk.Pixbuf pb, int pixel_size) {
        set_from_pixbuf(pb, pixel_size);
    }

    public Icon.from_icon_name(string icon_name, int pixel_size) {
        set_from_icon_name(icon_name, pixel_size);
    }

    public void set_widget_width(int width) {
        this.widget_width = width;
    }

    public void set_widget_height(int height) {
        this.widget_height = height;
    }

    public override void size_allocate(Gtk.Allocation allocation) {
        this.queue_resize();
        Gtk.Allocation alloc;
        this.get_parent().get_allocation(out alloc);
        base.size_allocate(alloc);
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        Gtk.Allocation alloc;
        this.get_parent().get_allocation(out alloc);
        min = nat = this.widget_width = alloc.width;
    }

    public override void get_preferred_height(out int min, out int nat)
    {
        Gtk.Allocation alloc;
        this.get_parent().get_allocation(out alloc);
        min = nat = this.widget_height = alloc.height;
    }

    public void set_from_gicon(GLib.Icon icon, int pixel_size)
    {
        this.size = pixel_size;
        Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
        Gtk.IconInfo info = icon_theme.lookup_by_gicon(icon, this.size, Gtk.IconLookupFlags.FORCE_REGULAR);
        try {
            this.pixbuf = info.load_icon();
        } catch (GLib.Error e) {
            warning(e.message);
        }
        GLib.Idle.add(() => {
            this.queue_resize();
            this.queue_draw();
            return false;
        });
    }

    public void set_from_pixbuf(Gdk.Pixbuf pb, int pixel_size) {
        this.size = pixel_size;
        this.pixbuf = pb;
        GLib.Idle.add(() => {
            this.queue_resize();
            this.queue_draw();
            return false;
        });
    }

    public void set_from_icon_name(string icon_name, int pixel_size)
    {
        this.size = pixel_size;
        Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
        try {
            this.pixbuf = icon_theme.load_icon(icon_name, this.size, Gtk.IconLookupFlags.FORCE_REGULAR);
        } catch (GLib.Error e) {
            warning(e.message);
        }
        GLib.Idle.add(() => {
            this.queue_resize();
            this.queue_draw();
            return false;
        });
    }

    public void set_size(int pixel_size) {
        this.size = pixel_size;
        GLib.Idle.add(() => {
            this.queue_resize();
            this.queue_draw();
            return false;
        });
    }

    public void animate_attention(Budgie.PanelPosition? position)
    {
        if (position != null) {
            this.panel_position = position;
        }

        if (attention_cycle_counter == 6) {
            attention_amount = 0;
            attention_cycle_counter = 0;
            return;
        }

        attention_cycle_counter++;

        BudgieTaskList.Animation attention_animation = new BudgieTaskList.Animation();
        attention_animation.widget = this;
        attention_animation.length = 50 * BudgieTaskList.MSECOND;
        attention_animation.tween = BudgieTaskList.sine_ease_in;

        if (attention_cycle_counter % 2 == 0) {
            attention_animation.changes = new BudgieTaskList.PropChange[] {
                BudgieTaskList.PropChange() {
                    property = "attention",
                    old = -5.0,
                    @new = 5.0
                }
            };
        } else if (attention_cycle_counter == 5) {
            attention_animation.changes = new BudgieTaskList.PropChange[] {
                BudgieTaskList.PropChange() {
                    property = "attention",
                    old = 5.0,
                    @new = 0.0
                }
            };
        } else {
            attention_animation.changes = new BudgieTaskList.PropChange[] {
                BudgieTaskList.PropChange() {
                    property = "attention",
                    old = (attention_cycle_counter == 1) ? 0.0 : 5.0,
                    @new = -5.0
                }
            };
        }

        attention_animation.start((a)=> {
            animate_attention(null);
        });
    }

    public void animate_wait()
    {
        if (!waiting) {
            wait_cycle_counter = 0;
            return;
        }

        if (wait_cycle_counter == MAX_CYCLES) {
            wait_cycle_counter = 0;
            return;
        }

        wait_cycle_counter++;

        BudgieTaskList.Animation wait_animation = new BudgieTaskList.Animation();
        wait_animation.widget = this;
        wait_animation.length = 700 * BudgieTaskList.MSECOND;
        wait_animation.tween = BudgieTaskList.sine_ease_in;
        wait_animation.changes = new BudgieTaskList.PropChange[] {
            BudgieTaskList.PropChange() {
                property = "icon_opacity",
                old = 1.0,
                @new = 0.3
            }
        };

        BudgieTaskList.Animation wait_animation1 = new BudgieTaskList.Animation();
        wait_animation1.widget = this;
        wait_animation1.length = 700 * BudgieTaskList.MSECOND;
        wait_animation1.tween = BudgieTaskList.sine_ease_in;
        wait_animation1.changes = new BudgieTaskList.PropChange[] {
            BudgieTaskList.PropChange() {
                property = "icon_opacity",
                old = 0.3,
                @new = 1.0
            }
        };

        wait_animation.start(() => {
            this.icon_opacity = 0.3;
        });

        GLib.Timeout.add(700, () => {
            if (!waiting) {
                wait_animation.stop();
                wait_animation1.stop();
                this.icon_opacity = 1.0;
                return false;
            }
            wait_animation1.start((a)=> {
                this.icon_opacity = 1.0;
                animate_wait();
            });
            return false;
        });
    }

    public void animate_launch(Budgie.PanelPosition position)
    {
        this.panel_position = position;

        double old_value;

        if (position == Budgie.PanelPosition.TOP || position == Budgie.PanelPosition.BOTTOM) {
            old_value = (double)((this.widget_height-this.size)/2);
        } else {
            old_value = (double)((this.widget_width-this.size)/2);
        }

        BudgieTaskList.Animation launch_animation = new BudgieTaskList.Animation();
        launch_animation.widget = this;
        launch_animation.length = 1200 * BudgieTaskList.MSECOND;
        launch_animation.tween = BudgieTaskList.elastic_ease_out;
        launch_animation.changes = new BudgieTaskList.PropChange[] {
            BudgieTaskList.PropChange() {
                property = "bounce",
                old = old_value,
                @new = this.bounce
            }
        };

        launch_animation.start((a)=> {
            this.bounce = 0.0;
        });
    }

    public override bool draw(Cairo.Context cr)
    {
        if (pixbuf == null) {
            return false;
        }

        int x = (this.widget_width / 2) - (this.size / 2);
        int y = (this.widget_height / 2) - (this.size / 2);


        if (this.panel_position == Budgie.PanelPosition.LEFT) {
            x += (int)bounce_amount;
            y += (int)attention_amount;
        } else if (this.panel_position == Budgie.PanelPosition.RIGHT) {
            x -= (int)bounce_amount;
            y += (int)attention_amount;
        } else if (this.panel_position == Budgie.PanelPosition.TOP) {
            y += (int)bounce_amount;
            x += (int)attention_amount;
        } else {
            y -= (int)bounce_amount;
            x += (int)attention_amount;
        }

        Gdk.cairo_set_source_pixbuf(cr, pixbuf, x, y);
        cr.paint();

        return true;
    }
}
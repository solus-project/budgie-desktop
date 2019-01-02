/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017-2019 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const int MAX_CYCLES = 12;

public class Icon : Gtk.Image
{
    private int widget_width = 36;
    private int widget_height = 30;
    private Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;
    public bool waiting = false;
    private int wait_cycle_counter = 0;
    private int attention_cycle_counter = 0;

    private double bounce_amount = 0.0;
    private double attention_amount = 0.0;

    public double bounce {
        public set {
            bounce_amount = value;
            this.queue_draw();
        }
        public get {
            return bounce_amount;
        }
        //default = 0.0;
    }

    public double attention {
        public set {
            attention_amount = value;
            this.queue_draw();
        }
        public get {
            return attention_amount;
        }
        //default = 0.0;
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
        //default = 1.0;
    }

    public Icon() {}

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
            old_value = (double)((this.widget_height-this.pixel_size)/2);
        } else {
            old_value = (double)((this.widget_width-this.pixel_size)/2);
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
        Gtk.Allocation alloc;
        get_allocation(out alloc);

        /* Have base implementation render first */
        var window = this.get_window();
        if (window == null) {
            return Gdk.EVENT_STOP;
        }
        /* Create a compatible buffer for the current scaling factor */
        var buffer = window.create_similar_image_surface(Cairo.Format.ARGB32,
                                                         alloc.width * this.scale_factor,
                                                         alloc.height * this.scale_factor,
                                                         this.scale_factor);
        var cr2 = new Cairo.Context(buffer);
        base.draw(cr2);

        /* Always start from 0 because the surface is correctly aligned */
        int x = 0;
        int y = 0;

        /* Offset the drawing */
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

        /* Render with our own offsets now */
        cr.set_source_surface(buffer, x, y);
        cr.paint();

        return true;
    }
}

/*
 * SoundIndicator.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const string MIXER_NAME = "Budgie Volume Control";
const int icon_size = 22;

public class SoundIndicator : Gtk.Bin
{

    /** Current image to display */
    public Gtk.Image widget { protected set; public get; }

    /** Our mixer */
    public Gvc.MixerControl mixer { protected set ; public get ; }

    /** Default stream */
    public Gvc.MixerStream stream { protected set ; public get ; }

    /** For the Status popover */
    public Gtk.Scale status_widget { protected set ; public get ; }
    public Gtk.Image status_image { protected set; public get; }

    private ulong change_id;

    public SoundIndicator()
    {
        // Start off with at least some icon until we connect to pulseaudio */
        widget = new Gtk.Image.from_icon_name("audio-volume-muted-symbolic", Gtk.IconSize.INVALID);
        widget.pixel_size = icon_size;
        margin = 2;
        add(widget);

        mixer = new Gvc.MixerControl(MIXER_NAME);
        mixer.state_changed.connect(on_state_change);
        mixer.open();

        status_widget = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        status_widget.set_draw_value(false);

        status_image = new Gtk.Image.from_icon_name("audio-volume-muted-symbolic", Gtk.IconSize.INVALID);
        status_image.pixel_size = icon_size;

        change_id = status_widget.value_changed.connect(on_scale_change);
        show_all();
    }

    /**
     * Called when something changes on the mixer, i.e. we connected
     * This is where we hook into the stream for changes
     */
    protected void on_state_change(uint new_state)
    {
        if (new_state == Gvc.MixerControlState.READY) {
            stream  = mixer.get_default_sink();
            stream.notify.connect((s,p)=> {
                if (p.name == "volume" || p.name == "is-muted") {
                    update_volume();
                }
            });
            update_volume();
        }
    }

    /**
     * Update from the scale (set volume.)
     */
    protected void on_scale_change()
    {
        if (stream.set_volume((uint32)status_widget.get_value())) {
            Gvc.push_volume(stream);
        }
    }

    /**
     * Update our icon when something changed (volume/mute)
     */
    protected void update_volume()
    {
        var vol_norm = mixer.get_vol_max_norm();
        var vol = stream.get_volume();

        /* Same maths as computed by volume.js in gnome-shell, carried over
         * from C->Vala port of budgie-panel */
        int n = (int) Math.floor(3*vol/vol_norm)+1;
        string image_name;

        // Work out an icon
        if (stream.get_is_muted() || vol <= 0) {
            image_name = "audio-volume-muted-symbolic";
        } else {
            switch (n) {
                case 1:
                    image_name = "audio-volume-low-symbolic";
                    break;
                case 2:
                    image_name = "audio-volume-medium-symbolic";
                    break;
                default:
                    image_name = "audio-volume-high-symbolic";
                    break;
            }
        }
        widget.set_from_icon_name(image_name, Gtk.IconSize.INVALID);
        status_image.set_from_icon_name(image_name, Gtk.IconSize.INVALID);

        var vol_max = mixer.get_vol_max_amplified();

        // Each scroll increments by 5%, much better than units..
        var step_size = vol_max / 20;
        SignalHandler.block(status_widget, change_id);
        status_widget.set_range(0, vol_max);
        status_widget.set_value(vol);
        status_widget.set_increments(step_size, step_size);
        if (vol_norm < vol_max) {
            status_widget.add_mark(vol_norm, Gtk.PositionType.TOP, null);
        } else {
            status_widget.clear_marks();
        }
        SignalHandler.unblock(status_widget, change_id);

        // Set a tooltip if we know the dB 
        if (stream.get_can_decibel()) {
            var db = stream.get_decibel();
            var tooltip = "%f dB".printf(db);
            widget.set_tooltip_text(tooltip);
        }

        // Gtk 3.12 issue, ensure we show all..
        show_all();
        queue_draw();
    }

} // End class

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

public class SoundIndicator : Gtk.Bin
{

    /** Current image to display */
    public Gtk.Image widget { protected set; public get; }

    /** Our mixer */
    public Gvc.MixerControl mixer { protected set ; public get ; }

    /** Default stream */
    public Gvc.MixerStream? stream { protected set ; public get ; }

    private double step_size;

    public SoundIndicator()
    {
        // Start off with at least some icon until we connect to pulseaudio */
        widget = new Gtk.Image.from_icon_name("audio-volume-muted-symbolic", Gtk.IconSize.MENU);
        margin = 2;
        var wrap = new Gtk.EventBox();
        wrap.add(widget);
        wrap.margin = 0;
        wrap.border_width = 0;
        add(wrap);

        mixer = new Gvc.MixerControl(MIXER_NAME);
        mixer.state_changed.connect(on_state_change);
        mixer.open();

        /* Catch scroll wheel events */
        wrap.add_events(Gdk.EventMask.SCROLL_MASK);
        wrap.scroll_event.connect(on_scroll_event);
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
     * Update from scroll events. turn volume up + down.
     */
    protected bool on_scroll_event(Gdk.EventScroll event)
    {
        return_val_if_fail(stream != null, false);

        uint32 vol = stream.get_volume();
        var orig_vol = vol;

        switch (event.direction) {
            case Gdk.ScrollDirection.UP:
                vol += (uint32)step_size;
                break;
            case Gdk.ScrollDirection.DOWN:
                vol -= (uint32)step_size;
                // uint. im lazy :p
                if (vol > orig_vol) {
                    vol = 0;
                }
                break;
            default:
                // Go home, you're drunk.
                return false;
        }

        /* Ensure sanity + amp capability */
        var max_amp = mixer.get_vol_max_amplified();
        var norm = mixer.get_vol_max_norm();
        if (max_amp < norm) {
            max_amp = norm;
        }

        if (vol > max_amp) {
            vol = (uint32)max_amp;
        }

        /* Prevent amplification using scroll on sound indicator */
        if (vol >= norm) {
            vol = (uint32)norm;
        }

        if (stream.set_volume(vol)) {
            Gvc.push_volume(stream);
        }

        return true;
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

        var vol_max = mixer.get_vol_max_amplified();

        // Each scroll increments by 5%, much better than units..
        step_size = vol_max / 20;

        // This usually goes up to about 150% (152.2% on mine though.)
        var pct = ((float)vol / (float)vol_norm)*100;
        var ipct = (uint)pct;
        widget.set_tooltip_text(@"$ipct%");

        // Gtk 3.12 issue, ensure we show all..
        show_all();
        queue_draw();
    }

} // End class

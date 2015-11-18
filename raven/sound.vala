/*
 * This file is part of arc-desktop
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class SoundWidget : Gtk.Box
{

    private Gtk.Revealer? revealer = null;
    private Gtk.Scale? scale = null;

    private Gvc.MixerControl? mixer = null;

    private Gtk.Switch? output_switch = null;
    private Gtk.Box? output_box = null;
    private Gtk.RadioButton? output_leader = null;
    private HashTable<uint,Gtk.RadioButton?> outputs;

    private Gtk.Switch? input_switch = null;
    private Gtk.Box? input_box = null;
    private Gtk.RadioButton? input_leader = null;
    private HashTable<uint,Gtk.RadioButton?> inputs;

    public bool expanded {
        public set {
            this.revealer.set_reveal_child(value);
        }
        public get {
            return this.revealer.get_reveal_child();
        }
        default = true;
    }

    private Arc.HeaderWidget? header = null;

    public SoundWidget()
    {
        Object(orientation: Gtk.Orientation.VERTICAL);

        get_style_context().add_class("audio-widget");

        /* TODO: Fix icon */
        scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale.set_draw_value(false);
        header = new Arc.HeaderWidget("", "audio-volume-muted-symbolic", false, scale);
        pack_start(header, false, false);

        revealer = new Gtk.Revealer();
        pack_start(revealer, false, false, 0);

        var ebox = new Gtk.EventBox();
        ebox.get_style_context().add_class("raven-background");
        revealer.add(ebox);

        outputs = new HashTable<uint,Gtk.RadioButton?>(direct_hash,direct_equal);
        inputs = new HashTable<uint,Gtk.RadioButton?>(direct_hash,direct_equal);
        mixer = new Gvc.MixerControl("Arc Volume Control");
        mixer.state_changed.connect(on_state_changed);
        mixer.output_added.connect(on_output_added);
        mixer.output_removed.connect(on_output_removed);
        mixer.input_added.connect(on_input_added);
        mixer.input_removed.connect(on_input_removed);

        var main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_layout.margin = 6;

        ebox.add(main_layout);

        /* Output row */
        var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var label = new Gtk.Label("Output");
        label.get_style_context().add_class("heading");
        row.pack_start(label, true, true, 0);
        label.halign = Gtk.Align.START;

        output_switch = new Gtk.Switch();
        output_switch.active = false;
        row.pack_end(output_switch, false, false, 0);
        main_layout.pack_start(row, false, false, 0);
        output_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_layout.pack_start(output_box, false, false, 0);
        output_box.margin_bottom = 6;

        /* Input row */
        row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        label = new Gtk.Label("Input");
        label.get_style_context().add_class("heading");
        row.pack_start(label, true, true, 0);
        label.halign = Gtk.Align.START;

        input_switch = new Gtk.Switch();
        input_switch.active = false;
        row.pack_end(input_switch, false, false, 0);
        main_layout.pack_start(row, false, false, 0);
        input_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_layout.pack_start(input_box, false, false, 0);
        input_box.margin_bottom = 6;

        header.bind_property("expanded", this, "expanded");
        expanded = true;

        mixer.open();
    }

    /* New available output */
    void on_output_added(uint id)
    {
        if (outputs.contains(id)) {
            return;
        }
        var device = this.mixer.lookup_output_id(id);
        message("Added output: %s", device.description);

        var check = new Gtk.RadioButton.with_label_from_widget(this.output_leader, device.description);
        output_box.pack_start(check, false, false, 0);

        if (this.output_leader == null) {
            this.output_leader = check;
            check.margin_top = 3;
        }

        outputs.insert(id, check);
    }

    /* New available input */
    void on_input_added(uint id)
    {
        if (inputs.contains(id)) {
            return;
        }
        var device = this.mixer.lookup_input_id(id);
        message("Added input: %s", device.description);

        var check = new Gtk.RadioButton.with_label_from_widget(this.input_leader, device.description);
        input_box.pack_start(check, false, false, 0);

        if (this.input_leader == null) {
            this.input_leader = check;
            check.margin_top = 3;
        }

        inputs.insert(id, check);
    }

    void on_output_removed(uint id)
    {
        Gtk.RadioButton? btn = outputs.lookup(id);
        if (btn == null) {
            warning("Removing id we dont know about: %u", id);
            return;
        }
        outputs.steal(id);
        btn.destroy();
    }

    void on_input_removed(uint id)
    {
        Gtk.RadioButton? btn = inputs.lookup(id);
        if (btn == null) {
            warning("Removing id we dont know about: %u", id);
            return;
        }
        inputs.steal(id);
        btn.destroy();
    }

    /* Update defaults, not yet implemented */
    void update_mixers()
    {

    }

    void on_state_changed(uint state)
    {
        switch (state) {
            case Gvc.MixerControlState.READY:
                /* We ready. */
                update_mixers();
                break;
            default:
                break;
        }
    }

} // End class

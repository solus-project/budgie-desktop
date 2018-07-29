using Gtk;
/*
 * This file is part of budgie-desktop
 * Copyright © 2017-2018 Ubuntu Budgie Developers, 2018 Budgie Desktop Developers
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
*/

namespace SupportingFunctions {
    /*
    * Here we keep the (possibly) shared stuff, or general functions, to
    * keep the main code clean and readable
    */
    private string[] keepsection(string[] arr_in, int lastn) {
        /* the last <n> positions will be kept in mind */
        string[] temparr = {};
        int currlen = arr_in.length;
        if (currlen > lastn) {
            int remove = currlen - lastn;
            temparr = arr_in[remove:currlen];
            return temparr;
        }
        return arr_in;
    }

    private int get_buttonindex (
        Button button, Button[] arr
        ) {
        for (int i=0; i < arr.length; i++) {
            if(button == arr[i]) return i;
        } return -1;
    }

    private GLib.Settings get_settings(string path) {
        var settings = new GLib.Settings(path);
        return settings;
    }

    private string readfile (string path) {
        try {
            string read;
            FileUtils.get_contents (path, out read);
            return read;
        } catch (FileError error) {
            string welcome = (_("Welcome to QuickNote.")).concat(" ", (_(
                "Text will be saved automatically while typing."
            )));
            return welcome;
        }
    }

    private void writefile (string path, string notes) {
        try {
            FileUtils.set_contents (path, notes);
        } catch (FileError error) {
            print("Cannot write to file. Is the directory available?");
        }
    }
}


namespace QuickNoteApplet {

    private ScrolledWindow win;
    private GLib.Settings qn_settings;
    private TextView view;
    private string[] steps;
    private string newtext;
    private bool update_steps;

    private string get_filepath(GLib.Settings settings, string key) {
        string filename = "quicknote_data.txt";
        string filepath = settings.get_string(key);
        if (filepath == "") {
            string homedir = Environment.get_home_dir();
            string settingsdir = ".config/solus-project/quicknote";
            string custompath = GLib.Path.build_path(homedir, settingsdir);
            File file = File.new_for_path(custompath);
            try {
                file.make_directory_with_parents();
            }
            catch (Error e) {
                /* the directory exists, nothing to be done */
            }
                return GLib.Path.build_filename(custompath, filename);
        }
        else {
            return GLib.Path.build_filename(filepath, filename);
        }
    }

    private string get_qntext (GLib.Settings settings, string key) {
        /* on startup of the applet, fetch the text */
        string filepath = get_filepath(settings, key);
        string initialtext = SupportingFunctions.readfile(filepath);
        return initialtext;
    }


    public class QuickNoteSettings : Gtk.Grid {
        /* Budgie Settings -section */
        private Scale[] scales = {};
        private CheckButton usecustom;
        private Entry dir_entry;
        private Button dir_button;
        private int maxlen;

        private void trim_text (string text) {
            string newtext;
            int lenstring = text.length;
            if (lenstring > maxlen) {
                string slice = text[
                    (lenstring - maxlen + 3) : lenstring
                ];
                newtext = "...".concat(slice);
            }
            else {
                newtext = text;
            }
            this.dir_entry.set_text(newtext);
        }

        public QuickNoteSettings(GLib.Settings? settings) {
            /* max string length in dir_entry */
            maxlen = 20;
            int app_width = qn_settings.get_int("width");
            int app_height = qn_settings.get_int("height");
            string set_custompath = qn_settings.get_string("custompath");
            /* Gtk stuff, widgets etc. here */
            var widthlabel = new Label((_("Text area width")));
            widthlabel.set_xalign(0);
            this.attach (widthlabel, 0, 0, 2, 1);
            var widthscale = new Gtk.Scale.with_range(
                Gtk.Orientation.HORIZONTAL, 250, 750, 5
            );
            this.attach(widthscale, 0, 1, 2, 1);
            var heightlabel = new Label((_("Text area height")));
            heightlabel.set_xalign(0);
            this.attach (heightlabel, 0, 2, 2, 1);
            var heightscale = new Gtk.Scale.with_range(
                Gtk.Orientation.HORIZONTAL, 150, 450, 5
            );
            this.attach(heightscale, 0, 3, 2, 1);
            heightscale.set_value(app_height);
            widthscale.set_value(app_width);
            heightscale.value_changed.connect(update_size);
            widthscale.value_changed.connect(update_size);
            this.scales += widthscale;
            this.scales += heightscale;
            /* custom path section */
            usecustom = new Gtk.CheckButton();
            var customlabel = new Gtk.Label(
                " " + (_("Set a custom directory"))
            );
            customlabel.set_xalign(0);
            var spacelabel = new Gtk.Label("\n");
            this.attach(spacelabel, 0, 4, 1, 1);
            this.attach(usecustom, 0, 5, 1, 1);
            this.attach(customlabel, 1, 5, 1, 1);
            dir_entry = new Gtk.Entry();
            dir_entry.set_editable(false);
            dir_entry.set_alignment(0);
            this.attach(dir_entry, 0, 6, 2, 1);
            var spacelabel2 = new Gtk.Label("\n");
            this.attach(spacelabel2, 0, 7, 2, 1);
            dir_button = new Gtk.Button.with_label((_("Choose directory")));
            this.attach(dir_button, 0, 8, 2, 1);
            /* set initial state */
            bool custom_isset = (set_custompath != "");
            set_widgets(custom_isset);
            usecustom.set_active(custom_isset);
            if (custom_isset == true) {
                trim_text(set_custompath);
            }
            usecustom.toggled.connect(act_oncustomtoggle);
            dir_button.clicked.connect(get_directory);
        }

        private void set_widgets (bool state, string ? path = null) {
            this.dir_button.set_sensitive(state);
            this.dir_entry.set_sensitive(state);
            this.dir_entry.set_text("");
        }

        private void get_directory (Button button) {
            Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
                "Select a directory", null, Gtk.FileChooserAction.SELECT_FOLDER,
                (_("Cancel")), Gtk.ResponseType.CANCEL, (_("Use")),
                Gtk.ResponseType.ACCEPT
                );
                if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                    string newpath = chooser.get_uri ().replace("file://", "");
                    trim_text(newpath);
                    qn_settings.set_string("custompath", newpath);
                }
		    chooser.close ();
        }

        private void act_oncustomtoggle(ToggleButton check) {
            bool isactive = usecustom.get_active();
            set_widgets(isactive);
            if (isactive == false) {
                this.dir_entry.set_text("");
                qn_settings.set_string("custompath", "");
            }
        }

        private void update_size (Gtk.Range scale) {
            int newval = (int)scale.get_value();
            if (scale == this.scales[0]) {
                qn_settings.set_int("width", newval);
            }
            else {
                qn_settings.set_int("height", newval);
            }
        }
    }


    public class QuickNote : Budgie.Plugin, Peas.ExtensionBase {
        public Budgie.Applet get_panel_widget(string uuid) {
            return new QuickNoteApplet();
        }
    }


    public class QuickNotePopover : Budgie.Popover {
        private Gtk.EventBox indicatorBox;
        private Gtk.Image indicatorIcon;
        Button[] doredobuttons;
        int last_index;

        private void manage_text(TextBuffer buffer) {
            /*
            * if undo/redo buttons are used, textfile should update,
            * but history should remain
            */
            if (update_steps == true) {
                newtext = buffer.text;
                string fpath = get_filepath(qn_settings, "custompath");
                SupportingFunctions.writefile(fpath, newtext);
                steps += newtext;
                steps = SupportingFunctions.keepsection(steps, 30);
                last_index = 1000;
            }
        }

        private void do_redo (Button button) {
            /* no bookkeepinhg during do/redo */
            update_steps = false;
            /* find out if we need to go back or forth */
            int b_index = SupportingFunctions.get_buttonindex(
                button, doredobuttons
            );
            /* length of steps */
            int lensteps = steps.length;
            if (b_index == 0) {
                if (this.last_index == 1000) {
                    this.last_index = lensteps - 2;
                }
                else {
                    this.last_index -= 1;
                }
                if (this.last_index >= 0) {
                    newtext = steps[this.last_index];
                    view.buffer.text = newtext;
                }
                else {
                    this.last_index = 0;
                }
            }
            else {
                int len_steps = steps.length;
                if (this.last_index < len_steps - 1) {
                    this.last_index += 1;
                    newtext = steps[this.last_index];
                    view.buffer.text = newtext;
                }
            }
            update_steps = true;
        }

        public QuickNotePopover(Gtk.EventBox indicatorBox) {
            GLib.Object(relative_to: indicatorBox);
            this.indicatorBox = indicatorBox;
            this.indicatorIcon = new Gtk.Image.from_icon_name(
                "quicknote-applet-symbolic", Gtk.IconSize.MENU
            );
            indicatorBox.add(this.indicatorIcon);
            Grid maingrid = new Gtk.Grid();
            this.add(maingrid);
            win = new Gtk.ScrolledWindow (null, null);
            maingrid.attach(win, 0, 0, 1, 1);
            view = new TextView ();
            view.set_left_margin(20);
            view.set_top_margin(20);
            view.set_right_margin(20);
            view.set_bottom_margin(20);
            view.set_wrap_mode (Gtk.WrapMode.WORD);
            TextBuffer content = view.get_buffer();
            content.changed.connect(manage_text);
            win.add (view);
            ButtonBox bbox = new ButtonBox(Gtk.Orientation.HORIZONTAL);
            bbox.set_layout(Gtk.ButtonBoxStyle.CENTER);
            Button undo = new Button.from_icon_name(
                "edit-undo-symbolic", Gtk.IconSize.BUTTON
            );
            undo.set_relief(Gtk.ReliefStyle.NONE);
            bbox.pack_start(undo, false, false, 0);
            Button redo = new Button.from_icon_name(
                "edit-redo-symbolic", Gtk.IconSize.BUTTON
            );
            this.doredobuttons += undo;
            this.doredobuttons += redo;
            undo.clicked.connect(do_redo);
            redo.clicked.connect(do_redo);
            redo.set_relief(Gtk.ReliefStyle.NONE);
            bbox.pack_start(redo, false, false, 0);
            maingrid.attach(bbox, 0, 1, 1, 1);
        }
    }


    public class QuickNoteApplet : Budgie.Applet {

        private Gtk.EventBox indicatorBox;
        private QuickNotePopover popover = null;
        private unowned Budgie.PopoverManager? manager = null;
        public string uuid { public set; public get; }
        /* specifically to the settings section */
        public override bool supports_settings()
        {
            return true;
        }
        public override Gtk.Widget? get_settings_ui()
        {
            return new QuickNoteSettings(this.get_applet_settings(uuid));
        }

        public QuickNoteApplet() {
            qn_settings = SupportingFunctions.get_settings(
                "com.solus-project.quicknote"
            );
            newtext = get_qntext(qn_settings, "custompath");
            steps = {newtext};
            /* box */
            indicatorBox = new Gtk.EventBox();
            add(indicatorBox);
            /* Popover */
            popover = new QuickNotePopover(indicatorBox);
            /* On Press indicatorBox */
            indicatorBox.button_press_event.connect((e)=> {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    /* temporary disable bookkeeping */
                    update_steps = false;
                    newtext = get_qntext(qn_settings, "custompath");
                    view.buffer.text = newtext;
                    update_steps = true;
                    int app_width = qn_settings.get_int("width");
                    int app_height = qn_settings.get_int("height");
                    win.set_size_request(app_width, app_height);
                    this.manager.show_popover(indicatorBox);

                }
                return Gdk.EVENT_STOP;
            });
            popover.get_child().show_all();
            show_all();
        }

        public override void update_popovers(Budgie.PopoverManager? manager)
        {
            this.manager = manager;
            manager.register_popover(indicatorBox, popover);
        }
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module){
    /* boilerplate - all modules need this */
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(
        Budgie.Plugin), typeof(QuickNoteApplet.QuickNote)
    );
}
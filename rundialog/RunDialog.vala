/*
 * RunDialog.vala
 *
 * Copyright: 2014 Ikey Doherty <ikey.doherty@gmail.com>
 *                 Leo Iannacone <info@leoiannacone.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{


public class RunDialogItemImage : Gtk.Image
{
    private uint animation_duration = 100000; // default 200ms
    private int64 animation_start_time = -1;
    private int64 animation_elapsed = -1;
    private bool animation_show = false;
    private bool animation_destroy = false;

    public bool animated = true;

    public signal void animation_end();

    public override void show ()
    {
        if (animated) {
            animation_show = true;
            animation_start_time = get_monotonic_time();
            add_tick_callback (on_tick);
        } else {
            animation_end ();
        }
        base.show();
    }

    public override bool draw (Cairo.Context cr)
    {
        if (animated) {
            // if animation_show
            double factor = (double) animation_elapsed / animation_duration;
            if (factor > 1) {
                factor = 1;
            }
            if (animation_destroy) {
                factor = 1 - factor;
            }
            double x = get_allocated_width () * (1 - factor) / 2;
            cr.translate (x, 0);
            cr.scale(factor, 1);
        }
        base.draw(cr);
        return true;
    }

    public bool on_tick (Gtk.Widget widget, Gdk.FrameClock frame)
    {
        animation_elapsed = frame.get_frame_time() - animation_start_time;
        animated = animation_duration > animation_elapsed;
        widget.queue_draw ();
        if (!animated) {
            animation_end();
            return false;
        }
        return true;
    }
}


public class RunDialogItem : Gtk.Button
{
    public static int REQUEST_SIZE = 90;

    public new RunDialogItemImage image;

    public DesktopAppInfo app;

    public RunDialogItem(DesktopAppInfo app)
    {
        this.app = app;
        this.relief = Gtk.ReliefStyle.NONE;

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
        add(box);
        box.set_size_request (REQUEST_SIZE, 0);
        box.add (get_icon ());
        box.add (get_name ());
        clicked.connect(launch);
    }

    protected Gtk.Widget get_icon()
    {
        image = new RunDialogItemImage();
        image.set_from_gicon (app.get_icon (), Gtk.IconSize.DIALOG);
        return image;
    }

    protected Gtk.Label get_name()
    {
        var name = new Gtk.Label(app.get_name ());
        name.set_line_wrap (true);
        name.set_ellipsize (Pango.EllipsizeMode.END);
        name.max_width_chars = 1;
        return name;
    }

    public void launch()
    {
        try {
            app.launch (null, null);
        } catch (GLib.Error e) {
            stderr.printf("Error launching app: %s\n", e.message);
        }
    }
}
public class RunDialog : Gtk.Window
{

    private Gtk.SearchEntry entry;
    private Gtk.Grid grid;
    private RunDialogItem first_item;

    private static string DEFAULT_ICON = "system-run-symbolic";

    private static int GRID_COLUMS = 3;
    private static int GRID_ROWS = 3;

    protected Gtk.Revealer revealer;
    protected Gtk.Label exec;
    protected Gtk.Label description;

    public RunDialog()
    {
        // Initialisation stuffs
        window_position = Gtk.WindowPosition.CENTER;
        destroy.connect(() => Gtk.main_quit());
        set_keep_above(true);
        set_skip_taskbar_hint(true);
        set_skip_pager_hint(true);
        title = "Run Program...";
        icon_name = DEFAULT_ICON;
        set_resizable (false);
        set_size_request (410, -1);
        this.border_width = 4;

        entry = new Gtk.SearchEntry();
        var headerbar = init_headerbar (entry);
        set_focus_child (entry);

        grid = new Gtk.Grid();
        revealer = new Gtk.Revealer();
        exec = new Gtk.Label("");
        description = new Gtk.Label("");
        var box_results = init_results_box (grid, revealer, exec, description);

        var main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_layout.pack_start(headerbar, false, false, 0);
        main_layout.pack_end (box_results, false, false, 0);
        add(main_layout);

        get_style_context().add_class("budgie-run-dialog");
        get_style_context().add_class("header-bar");

        // Load our default styling
        try {
            var prov = new Gtk.CssProvider();
            var file = File.new_for_uri("resource://com/evolve-os/budgie/run-dialog/rundialog-style.css");
            prov.load_from_file(file);

            Gtk.StyleContext.add_provider_for_screen(this.screen, prov,
                    Gtk.STYLE_PROVIDER_PRIORITY_USER);
        } catch (GLib.Error e) {
            stderr.printf("CSS loading issue: %s\n", e.message);
        }

        entry.changed.connect(entry_changed);
        entry.activate.connect(entry_activated);

        /* Finally, handle ESC */
        key_press_event.connect((w, e) => {
            if (e.keyval == Gdk.Key.Escape) {
                this.destroy();
                return true;
            }
            return false;
        });

        var empty = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        empty.draw.connect((c) => {
            return true;
        });
        set_titlebar(empty);
        empty.get_style_context().add_class("invisi-header");
        empty.get_style_context().remove_class("titlebar");

        get_settings().set_property("gtk-application-prefer-dark-theme", true);
        hide_results ();
        show_all();
    }


    /**
     * Handle changes to the text entry, update the results if we can
     */
    protected void entry_changed ()
    {
        var old_items = grid.get_children().copy();
        // reverse the items, since we are going to check from position 0
        old_items.reverse();
        clean();

        if (entry.text.length <= 0) {
            hide_results ();
            return;
        }

        List<DesktopAppInfo> apps = this.search_applications (entry.text);

        if (apps.length () == 0) {
            hide_results ();
            return;
        }

        show_results ();
        int i = 0, current_column = -1, current_row = -1;

        foreach (DesktopAppInfo app in apps) {
            var item = new RunDialogItem(app);

            // Do not animate if Item is already in the current position
            var old_item = (RunDialogItem) old_items.nth_data(i);
            var animated = (old_item == null || app.get_filename() != old_item.app.get_filename());

            item.image.animated = animated;
            item.clicked.connect(() => this.destroy ());
            item.enter_notify_event.connect(() => this.set_info(item));
            item.leave_notify_event.connect(() => this.set_info(null));
            if (i == 0) {
                // first item
                first_item = item;
                this.set_info (item);
                item.get_style_context ().add_class ("suggested-action");
            }
            current_column = i % GRID_COLUMS;
            if (current_column == 0) {
                current_row++;
            }
            grid.attach (item, current_column, current_row, 1, 1);
            item.show_all();
            i++;
        }
    }


    /**
     * Launch the budgie-panel preferences and exit
     */
    protected void launch_panel_preferences ()
    {
        try {
            Process.spawn_command_line_async ("budgie-panel --prefs");
            this.destroy();
        } catch (SpawnError e) {
            stderr.printf ("Error launching budgie settings: %s\n",
                           e.message);
        }
    }

    /**
     * Build the headerbar
     */
    protected Gtk.Box init_headerbar (Gtk.SearchEntry entry)
    {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, (int) this.border_width);

        var preferences = new Gtk.Button.from_icon_name ("preferences-desktop",
                Gtk.IconSize.MENU);
        preferences.tooltip_text = "Budgie Settings";
        preferences.clicked.connect(launch_panel_preferences);

        var close = new Gtk.Button.from_icon_name ("window-close-symbolic",
                Gtk.IconSize.MENU);
        close.relief = Gtk.ReliefStyle.NONE;
        close.clicked.connect(() => this.destroy());

        box.add(preferences);
        box.add(new Gtk.Separator (Gtk.Orientation.VERTICAL));
        box.pack_start (entry, true, true, 0);
        box.add(close);

        return box;
    }

    /**
     * Build the box results
     */
    protected Gtk.Widget init_results_box (Gtk.Grid grid,
                                           Gtk.Revealer revealer,
                                           Gtk.Label exec,
                                           Gtk.Label description)
    {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL,
                               (int) this.border_width);
        box.margin_top = (int) this.border_width;

        description.halign = Gtk.Align.START;
        description.valign = Gtk.Align.START;
        description.set_line_wrap (true);
        description.set_ellipsize (Pango.EllipsizeMode.END);
        description.max_width_chars = 1;
        box.pack_start (description, true, true, this.border_width);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.get_style_context().add_class("entry");
        scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scrolled.set_size_request (-1, GRID_ROWS * RunDialogItem.REQUEST_SIZE);
        scrolled.add(grid);
        box.add(scrolled);

        exec.halign = Gtk.Align.START;
        exec.valign = Gtk.Align.START;
        exec.set_line_wrap (true);
        exec.set_ellipsize (Pango.EllipsizeMode.END);
        exec.max_width_chars = 1;
        box.pack_end(exec, true, true, this.border_width);

        revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
        revealer.set_transition_duration (100);
        revealer.add(box);

        return revealer;
    }

    /**
     * Set information about the application is going to be launched
     */
    public bool set_info(RunDialogItem? item)
    {
        if (item == null) {
            item = first_item;
        }
        description.set_text (item.app.get_description ());
        exec.set_text ("Execute command <%s>".printf(item.app.get_executable ()));
        return false;
    }

    /**
     * Remove results.
     */
    protected void clean ()
    {
        foreach (var c in grid.get_children()) {
            grid.remove(c);
        }
    }

    /**
     * Show results
     */
    protected void show_results()
    {
        revealer.set_reveal_child(true);
    }

    /**
     * Hide results
     */
    protected void hide_results()
    {
        revealer.set_reveal_child(false);
    }

    /**
     * Search for applications
     */
    private List<DesktopAppInfo> search_applications (string pattern)
    {
        var result = new List<DesktopAppInfo>();
        if (pattern.length == 0) {
            return result;
        }
        string **[] search = DesktopAppInfo.search(pattern);
        string **group;
        string desktop;
        int i = 0, j = 0;
        while ((group = search[i]) != null) {
            i++; j = 0;
            while ((desktop = group[j]) != null) {
                j++;
                var app = new DesktopAppInfo(desktop);
                if (app == null || app.get_nodisplay()) {
                    continue;
                }
                result.append(app);
            }
        }
        return result;
    }

    /**
     * Handle activation of the entry
     */
    protected void entry_activated()
    {
        if (entry.text.length == 0) {
            return;
        }
        if (first_item != null) {
            first_item.launch ();
            destroy();
        }
    }

} // End RunDialog

class RunDialogMain : GLib.Application
{

    static Budgie.RunDialog dialog;

    public override void activate()
    {
        hold();
        if (dialog == null) {
            dialog = new Budgie.RunDialog();
            Gtk.main();
        }
        dialog.present();
        release();
    }

    private RunDialogMain()
    {
        Object (application_id: "com.evolve_os.BudgieRunDialog", flags: 0);
    }
    /**
     * Main entry
     */

    public static int main(string[] args)
    {
        Budgie.RunDialogMain app;
        Gtk.init(ref args);

        app = new Budgie.RunDialogMain();

        return app.run(args);
    }
} // End RunDialogMain

} // End Budgie namespace

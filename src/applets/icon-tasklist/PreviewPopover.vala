

namespace Budgie {




    public class PreviewPopover : Budgie.Popover {

        const int MAX_WINDOWS = 6;

        public HashTable<ulong?, string?> window_id_to_name; // List of IDs to Names
        private HashTable<ulong?, Budgie.PreviewItem?> window_id_to_controls; // List of IDs to Controls
        //private List<Budgie.PreviewItem> workspace_items; // Our referenced list of workspaces
        private int workspace_count = 0;
        private bool pinned = false;
        private bool is_budgie_desktop_settings = false;
        private unowned string[] actions = null; // List of supported desktop actions
        private string preferred_action = ""; // Any preferred action from Desktop Actions like "new-window"
        private string name = null;

        //private unowned Wnck.Screen wnck_screen;

        private Gtk.Grid grid;
        private Gtk.Box window_box;
        private Gtk.Box quick_actions;
        public Gtk.Button? pin_button = null;
        public Gtk.Button? close_all_button = null;
        public Gtk.Button? launch_new_instance_button = null;
        public Gtk.Box launch_new_instance_box = null;
        public Gtk.Label launch_new_instance_label = null;

        private Gtk.Image non_starred_image = null;
        private Gtk.Image starred_image = null;


        // WINDOW_CSS
        string newpv_css = """
        .windowbutton {
        border-width: 2px;
        border-color: #5A5A5A;
        background-color: transparent;
        padding: 4px;
        border-radius: 1px;
        -gtk-icon-effect: none;
        border-style: solid;
        transition: 0.1s linear;
        }
        .windowbutton:hover {
        border-color: #E6E6E6;
        background-color: transparent;
        border-width: 1px;
        padding: 6px;
        border-radius: 1px;
        border-style: solid;
        }
        .label {
        color: white;
        padding-bottom: 0px;
        }
        """;
        /*
        
        .windowbutton:focus {
        border-color: white;
        background-color: transparent;
        border-width: 2px;
        padding: 3px;
        }
        */

        /**
         * Signals
         */
        public signal void added_window();
        public signal void closed_all();
        public signal void closed_window();
        public signal void activated_window();
        public signal void launch_new_instance();
        public signal void changed_pin_state(bool new_state);
        public signal void perform_action(string action);

        public PreviewPopover(Gtk.Widget relative_parent, DesktopAppInfo? app_info, int current_workspace_count) {
            Object(relative_to: relative_parent);

            get_style_context().add_class("icon-popover");
            this.workspace_count = current_workspace_count;
            this.window_id_to_name = new HashTable<ulong?, string?>(int_hash, int_equal);
            this.window_id_to_controls = new HashTable<ulong?, Budgie.PreviewItem?>(int_hash, int_equal);

            // TODO: put this in the theme?
            //get_style_context().add_class("icon-popover");
            Gtk.CssProvider css_provider = new Gtk.CssProvider();
            try {
                css_provider.load_from_data(newpv_css);
                Gtk.StyleContext.add_provider_for_screen(
                    this.get_screen(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
            }
            catch (Error e) {
            }


            if (app_info != null) {
                is_budgie_desktop_settings = app_info.get_startup_wm_class() == "budgie-desktop-settings";

                this.name = app_info.get_display_name();
                this.actions = app_info.list_actions();

                foreach (string action in this.actions) { // Now actually create the items
                    string action_name = app_info.get_action_name(action); // Get the name for this action

                    // Budgie.IconPopoverItem action_item = new Budgie.IconPopoverItem(action_name, longest_label_length);
                    // action_item.actionable_label.set_data("action", action);

                    // action_item.actionable_label.clicked.connect(() => {
                    //     string assigned_action = action_item.actionable_label.get_data("action");
                    //     this.perform_action(assigned_action);
                    // });

                    // this.actions_list.pack_end(action_item, true, false, 0);

                    if (action == "new-window") { // Generally supported new-window action
                        preferred_action = action;
                    }
                }
            }

            var new_window_image = new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.DIALOG);

            this.launch_new_instance_button = new Gtk.Button();

            string label_text = this.name != null ? "Launch ".concat(this.name) : "Launch Application";
            this.launch_new_instance_button.set_tooltip_text(_(label_text));

            // create window preview button
            //this.window_button = new Gtk.Button();
            this.launch_new_instance_button.set_size_request(280, 180);

            // set button style
            var st_ct = this.launch_new_instance_button.get_style_context();
            st_ct.add_class("windowbutton");
            st_ct.remove_class("image-button");

            this.launch_new_instance_button.set_relief(Gtk.ReliefStyle.NONE);

            this.launch_new_instance_button.set_image(new_window_image);

            // the names for this images appear to be swapped, so I've swapped them here
            this.non_starred_image = new Gtk.Image.from_icon_name("non-starred-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            this.starred_image = new Gtk.Image.from_icon_name("starred-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

            this.pin_button = new Gtk.Button();
            this.pin_button.set_image(non_starred_image);

            //this.close_all_button = new Gtk.Button();
            this.close_all_button = new Gtk.Button.from_icon_name("list-remove-all-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            this.close_all_button.set_tooltip_text(_("Close All Windows"));
            //this.close_all_button.set_image(close_all_image);
            this.close_all_button.sensitive = false;


            this.close_all_button.can_focus = false;
            this.pin_button.can_focus = false;


            this.pin_button.clicked.connect(() => { // When we click the pin button
                set_pinned_state(!this.pinned);
                changed_pin_state(this.pinned); // Call with new pinned state
            });


            this.launch_new_instance_button.clicked.connect(() => { // When we click to launch a new instance
                if (preferred_action != "" && this.window_id_to_name.length != 0) { // If we have a preferred action set
                    perform_action(preferred_action);
                } else { // Default to our launch_new_instance signal
                    launch_new_instance();
                }
            });

            this.close_all_button.clicked.connect(this.close_all_windows); // Close all windows

            this.quick_actions = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            this.quick_actions.homogeneous = true;

            this.quick_actions.pack_start(this.pin_button, true, true, 0);
            //this.quick_actions.pack_start(this.close_all_button, true, true, 0);

            // create grid to hold all content
            this.grid = new Gtk.Grid();
            this.grid.set_column_spacing(0);
            this.grid.set_row_spacing(0);

            // create box to hold window preview buttons
            this.window_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            this.window_box.margin_top = 10;
            this.window_box.margin_bottom = 10;
            this.window_box.margin_left = 5;
            this.window_box.margin_right = 5;
            //this.box.get_style_context().add_class("icon-popover-stack");


            this.launch_new_instance_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);

            this.launch_new_instance_label = new Gtk.Label(label_text);
            var label_ct = launch_new_instance_label.get_style_context();
            label_ct.add_class("label");
            launch_new_instance_label.set_can_focus(false);

            this.launch_new_instance_box.pack_start(this.launch_new_instance_label, false, false, 10); // changed from 0->10
            this.launch_new_instance_box.pack_start(this.launch_new_instance_button, false, false, 0);

            this.window_box.pack_end(this.launch_new_instance_box, false, false, 5);


            this.grid.attach(this.window_box, 1, 0, 1, 1);
            this.grid.attach(this.quick_actions, 1, 1, 1, 1);

            apply_button_style();

            /*
            this.grid.attach(new Gtk.Label(""), 0, 0, 1, 1);
            this.grid.attach(new Gtk.Label("\n"), 100, 100, 1, 1);
            this.grid.set_column_spacing(20);
            this.grid.set_row_spacing(20);
            */
            //prev_winexists = true;
            this.add(this.grid);

            this.title = "PreviewPopover";

        }

        public void apply_button_style(){

            this.pin_button.get_style_context().add_class("flat");
            this.pin_button.get_style_context().remove_class("button");
            this.launch_new_instance_button.get_style_context().add_class("flat");
            this.launch_new_instance_button.get_style_context().remove_class("button");
            this.close_all_button.get_style_context().add_class("flat");
            this.close_all_button.get_style_context().remove_class("button");
        }

        /**
         * set_pinned_state will change the icon of our pinned button and set pinned state
         */
        public void set_pinned_state(bool pinned_state) {
            this.pinned = pinned_state;
            this.pin_button.set_image(this.pinned ? this.starred_image : this.non_starred_image);
            this.pin_button.set_tooltip_text((this.pinned) ? _("Unfavorite") : _("Favorite"));
        }

        /**
         * add_window will add a window to our list
         */
        public void add_window(ulong xid, string name) {


            // first window?
            if(this.window_id_to_name.length == 0){

                // yes, move quick actions to left side
                
                this.window_box.margin_top = 5;

                // update text for new window button
                string label_text = this.name != null ? "Launch New ".concat(this.name, " Instance") : "Launch New Instance";
                this.launch_new_instance_button.set_tooltip_text(_(label_text));
                label_text = this.name != null ? "New ".concat(this.name, " Window") : "New Window";
                this.launch_new_instance_label.set_text(label_text);

                this.quick_actions.orientation = Gtk.Orientation.VERTICAL;
                this.quick_actions.pack_start(this.close_all_button, true, true, 0);

                // move quick actions to the beginning
                this.grid.remove(this.quick_actions);
                this.grid.attach(this.quick_actions, 0, 0, 1, 1);
                this.grid.attach(this.pin_button, 0, 0, 1, 1);
                apply_button_style();

            }
            if (!this.window_id_to_name.contains(xid)) {
                var window = Wnck.Window.@get(xid); // Get the window just to ensure it exists

                if (window == null) return;

                Budgie.PreviewItem item = new Budgie.PreviewItem(xid, name);

                item.window_button.clicked.connect(() => { // When we click on the window
                    this.activate_window(item.xid); // Toggle the window state
                });

                item.close_button.clicked.connect(() => { // Create our close button click handler
                    this.close_window(item.xid); // Close this window if we can
                });


                this.window_id_to_name.insert(xid, name);
                this.window_id_to_controls.insert(xid, item);

                this.window_box.pack_start(item, false, false, 5);

                this.render();

                added_window();
            }
            if(this.window_id_to_name.length == MAX_WINDOWS){
                // do we have the maximum number of windows already?
                // remove launch new instance button
                this.window_box.remove(this.launch_new_instance_box);
            }

            this.close_all_button.sensitive = (window_id_to_name.length != 0);
        }


        /**
         * remove_window will remove the respective item from our windows list and HashTables
         */
        public void remove_window(ulong xid) {

            if(this.window_id_to_name.length == MAX_WINDOWS){
                // are we currently at the max number of windows?
                // add the launch new instance button back
                this.window_box.pack_end(this.launch_new_instance_box);
            }

            if (this.window_id_to_name.contains(xid)) { // If we have this xid

                Budgie.PreviewItem item = this.window_id_to_controls.get(xid); // Get the control
                this.window_box.remove(item);
                //windows_list.remove(item); // Remove from the window list
                this.window_id_to_name.remove(xid);
                this.window_id_to_controls.remove(xid);

                this.render(); // Re-render

                closed_window();

                if (this.window_id_to_name.length == 0) {

                    // update new window box text
                    string label_text = this.name != null ? "Launch ".concat(this.name) : "Launch Application";
                    this.launch_new_instance_label.set_text(label_text);
                    this.launch_new_instance_button.set_tooltip_text(_(label_text));

                    // reset to empty layout
                    this.window_box.pack_start(this.launch_new_instance_box, false, false, 10);
                    this.window_box.margin_top = 10;

                    this.quick_actions.remove(this.close_all_button);
                    this.quick_actions.orientation = Gtk.Orientation.HORIZONTAL;

                    // move quick actions
                    this.grid.remove(this.quick_actions);
                    this.grid.attach(this.quick_actions, 1, 1, 1, 1);
                    apply_button_style();

                    // send signal
                    closed_all();
                }
            }

            this.close_all_button.sensitive = (window_id_to_name.length != 0);
        }

        /**
         * rename_window will rename a window we have listed
         */
        public void rename_window(ulong xid) {
            if (window_id_to_name.contains(xid)) { // If we have this window
                var selected_window = Wnck.Window.@get(xid); // Get the window

                if (selected_window != null) {
                    Budgie.PreviewItem item = window_id_to_controls.get(xid); // Get the control
                    item.name_label.set_text(selected_window.get_name());
                }
            }
        }

        /**
         * close_window will close a window and remove its respective IconPopoverItem
         */
        public void close_window(ulong xid) {
            var selected_window = Wnck.Window.@get(xid);

            if (selected_window != null) {
                selected_window.close(Gtk.get_current_event_time());
            }
        }

        /**
         * activate_window will activate a window
         */
        public void activate_window(ulong xid) {
            if (window_id_to_name.contains(xid)) { // If we have this xid
                Wnck.Window selected_window = Wnck.Window.@get(xid); // Get the window

                if (selected_window != null) {
                    selected_window.activate(Gtk.get_current_event_time());

                    activated_window();
                }
            }
        }


        public void close_all_windows() {
            if (window_id_to_name.length != 0) { // If there are windows to close
                window_id_to_name.foreach((xid, name) => {
                    close_window(xid); // Close this window
                });
            }
        }

        /**
         * render will update preview images for all windows and show them
         */
        public void render() {

            int num_windows = (int) window_id_to_name.length;

            // call display on all PreviewItem s
            int i = 0;
            this.window_id_to_controls.foreach((xid, item) => {
            
                if(xid == null) return;
                item.render();
                i++;
                if( i == MAX_WINDOWS){
                    return;
                }
            });

            this.grid.show_all();

        }
    } // PreviewPopover

    public class PreviewItem : Gtk.Grid {

        public ulong xid;
        private Gdk.X11.Display display;
        public Gtk.Button window_button;
        public Gtk.Label name_label;
        public Gtk.Button close_button;

        private Gdk.Screen gdk_scr;
        private Gdk.Window window;

        /* Create a new PreviewItem with app icon, title and window preview image and close button
         */
        public PreviewItem(ulong xid, string name){


            this.xid = xid;

            this.display = (Gdk.X11.Display) Gdk.Display.get_default();

            this.gdk_scr = Gdk.Screen.get_default();

            Wnck.Window wnck_window = Wnck.Window.@get(xid); // Get the window

            // this check was in the original code
            // if(wnck_window == null || wnck_window.get_window_type() != Wnck.WindowType.NORMAL) return;
            Gdk.Pixbuf icon = wnck_window.get_mini_icon();
            Gtk.Image app_icon = new Gtk.Image.from_pixbuf(icon);

            this.set_row_spacing(5);

            // create window preview button
            this.window_button = new Gtk.Button();
            this.window_button.set_size_request(280, 180);

            // set button style
            var st_ct = this.window_button.get_style_context();
            st_ct.add_class("windowbutton");
            st_ct.remove_class("image-button");

            this.window_button.set_relief(Gtk.ReliefStyle.NONE);

            // get window
            this.window = lookup_window(this.xid);

            if(this.window != null){ // window.is_viewable()
                // get resized window image
                Gtk.Image? window_image = get_preview(this.window);

                if(window_image != null){
                    this.window_button.set_image(window_image);
                }
            }

            if(name == null) name = "<Untitled>";


            // add button to Grid
            this.attach(this.window_button, 0, 1, 1, 1);

            // header box containing title, icon and close box
            Gtk.Box actionbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            this.attach(actionbar, 0, 0, 1, 1);

            // app icon
            actionbar.pack_start(app_icon, false, false, 0);

            // window title
            this.name_label = new Gtk.Label(name);
            this.name_label.set_ellipsize(Pango.EllipsizeMode.END);
            this.name_label.set_max_width_chars(22);
            var label_ct = this.name_label.get_style_context();
            label_ct.add_class("label");
            actionbar.pack_start(this.name_label, false, false, 10);
            this.name_label.set_can_focus(false);


            // create close X button
            this.close_button = new Gtk.Button.from_icon_name("window-close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            this.close_button.set_tooltip_text(_("Close Window"));
            this.close_button.set_can_focus(false);

            this.close_button.get_style_context().add_class("flat");
            this.close_button.get_style_context().remove_class("button");

            actionbar.pack_end(close_button, false, false, 0);

        }

        private Gdk.Window? get_gdkmatch (ulong xid) {
            // given an xid, find the (existing) Gdk.Window
            // Gdk.WindowTypeHint.NORMAL - check is done here
            GLib.List<Gdk.Window> gdk_winlist = gdk_scr.get_window_stack();

            foreach (Gdk.Window gdkwin in gdk_winlist) {
                if (gdkwin.get_type_hint() == Gdk.WindowTypeHint.NORMAL) {
                    Gdk.X11.Window x11conv = (Gdk.X11.Window)gdkwin; // check!!!
                    ulong x11_xid = x11conv.get_xid();
                    if (xid == x11_xid) {
                        return gdkwin;
                    }
                }
            }
            return null;
        }

        private Gdk.Window lookup_window(ulong xid){
            return new Gdk.X11.Window.foreign_for_display(this.display, xid);
        }

        /* Create the Image containing the window preview. Assumes window.is_viewable()

          from budgie-extras budgie-wpreviews previews_create.vala
         */
        private Gtk.Image? get_preview (Gdk.Window window) {

            this.display.error_trap_push();

            int width = window.get_width();
            int height = window.get_height();

            Gdk.Pixbuf? window_pixbuf = 
                Gdk.pixbuf_get_from_window(window, 0, 0, width, height);

            if(window_pixbuf == null) return null;

            int[] sizes = determine_sizes(window_pixbuf, (double)width, (double)height);

            window_pixbuf = window_pixbuf.scale_simple(sizes[0], sizes[1] , Gdk.InterpType.BILINEAR);
            
            if(window_pixbuf == null) return null;

            return new Gtk.Image.from_pixbuf(window_pixbuf);
        }

        private int[] determine_sizes (Gdk.Pixbuf? pre_shot, double xsize, double ysize) {
            // calculates targeted sizes
            int targetx = 0;
            int targety = 0;
            double prop = (double)(xsize / ysize);
            // see if we need to pick xsize or ysize as a reference
            double threshold = 260.0/160.0;
            if (prop >= threshold) {
                targetx = 260;
                targety = (int)((260 / xsize) * ysize);
            }
            else {
                targety = 160;
                targetx = (int)((160 / ysize) * xsize);
            }
            return {targetx, targety};
        }


        /* update window image
         */
        public void render(){

            if(this.window == null){
                this.window = lookup_window(this.xid);
            }
            
            if(this.window == null){ // || !window.is_viewable()
                return;
            }

            // get resized window image
            Gtk.Image? window_image = get_preview(this.window);

            if(window_image == null){
                return;
            }

            this.window_button.set_image(window_image);
        }

    } // PreviewItem

} // Budgie
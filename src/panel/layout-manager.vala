/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2017 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

/**
 * The LayoutManager is responsible for reading and writing Budgie Desktop
 * layout files.
 *
 * In essence, a Budgie layout file contains a definition for the base configurables
 * of the desktop, i.e. the fundamental panel layout with bootstrap for the internal
 * applets.
 *
 * This is read and written in the super basic INI file format to retain backwards
 * compatibility with the older `panel.ini` format used in the codebase.
 */
public class LayoutManager : GLib.Object {

    string[] layout_dirs;
    string storage_dir;

    /* The baked in layout file */
    const string builtin_layout = "resource:///com/solus-project/budgie/panel/panel.ini";

    /* Name to path mapping for layouts */
    HashTable<string,string> known_layouts;

    public LayoutManager()
    {
        /**
         * In order of priority:
         * ~/.config/budgie-desktop/layouts
         * /etc/budgie-desktop/layouts
         * /usr/share/budgie-desktop/layouts
         */
        layout_dirs = new string[] {
            "%s/budgie-desktop/layouts".printf(Environment.get_user_config_dir()),
            "%s/budgie-desktop/layouts".printf(Budgie.CONFDIR),
            "%s/budgie-desktop/layouts".printf(Budgie.DATADIR),
        };

        storage_dir = layout_dirs[0];

        known_layouts = new HashTable<string,string>(str_hash, str_equal);

        this.enumerate_layouts.begin(()=> {
            message("Layouts be got! %u", known_layouts.size());
        });
    }

    /**
     * Learn what layouts are available to us
     */
    async void enumerate_layouts() throws Error
    {
        const string peek_attribs = FileAttribute.STANDARD_NAME + "," +  FileAttribute.STANDARD_TYPE;

        known_layouts.remove_all();

        foreach (unowned string directory in layout_dirs) {
            File f = File.new_for_path(directory);

            if (!FileUtils.test(directory, FileTest.EXISTS|FileTest.IS_DIR)) {
                continue;
            }

            var enumf = yield f.enumerate_children_async(peek_attribs, FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, null);

            List<FileInfo>? files = null;

            /* Idly pull 5 files at a time from this directory */
            while ((files = yield enumf.next_files_async(5, Priority.DEFAULT, null)) != null) {
                foreach (unowned FileInfo? info in files) {
                    if (info.get_file_type() != FileType.REGULAR) {
                        continue;
                    }
                    string path_name = info.get_name();
                    if (!path_name.has_suffix(".layout")) {
                        continue;
                    }
                    string fpath = "%s/%s".printf(directory, path_name);
                    string name = path_name.split(".layout")[0].strip();
                    if (name.length < 1) {
                        message("Incorrectly named layout file: %s", fpath);
                        continue;
                    }

                    /* Do not replace older due to searching highest priority first */
                    if (this.known_layouts.lookup(name) != null) {
                        continue;
                    }

                    this.known_layouts.insert(name, path_name);
                }
            }
            yield enumf.close_async();
        }
    }

} /* End LayoutManager */

} /* End namespace */
/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */

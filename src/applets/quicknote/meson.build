# QuickNote Applet build

applet_quicknote_dir = applets_dir + '.quicknote'

custom_target('plugin-file-quicknote',
    input : 'QuickNoteApplet.plugin.in',
    output : 'QuickNoteApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_quicknote_dir)

applet_quicknote_sources = [
    'QuickNoteApplet.vala',
]

applet_quicknote_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    link_libplugin,
    meson.get_compiler('c').find_library('m', required: false)
]

shared_library(
    'quicknoteapplet',
    applet_quicknote_sources,
    dependencies: applet_quicknote_deps,
    vala_args: [
       '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gio-unix-2.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
    ],
    install: true,
    install_dir: applet_quicknote_dir,
)

install_data(
    'com.solus-project.quicknote.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

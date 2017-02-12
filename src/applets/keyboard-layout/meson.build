# Clock Applet build

applet_keyboardlayout_dir = applets_dir + '.keyboard-layout'

custom_target('plugin-file-keyboardlayout',
    input : 'KeyboardLayoutApplet.plugin.in',
    output : 'KeyboardLayoutApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_keyboardlayout_dir)

applet_keyboardlayout_sources = [
    'KeyboardLayoutApplet.vala',
]

applet_keyboardlayout_deps = [
    dep_gtk3,
    dep_peas,
    dep_gnomedesktop,
    dep_gsettings,
    dep_ibus,
    link_libplugin,
]

shared_library(
    'keyboardlayoutapplet',
    applet_keyboardlayout_sources,
    dependencies: applet_keyboardlayout_deps,
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'ibus-1.0',
        '--pkg', 'gnome-desktop-3.0',
        '--pkg', 'gsettings-desktop-schemas',
        '--vapidir', join_paths(meson.source_root(), 'vapi'),
    ],
    c_args: [
        '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    ],
    install: true,
    install_dir: applet_keyboardlayout_dir,
)

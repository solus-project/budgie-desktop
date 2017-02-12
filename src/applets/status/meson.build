# Status Applet build

applet_status_dir = applets_dir + '.status'

custom_target('plugin-file-status',
    input : 'StatusApplet.plugin.in',
    output : 'StatusApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_status_dir)

applet_status_sources = [
    'BluetoothIndicator.vala',
    'StatusApplet.vala',
    'PowerIndicator.vala',
    'SoundIndicator.vala',
]

applet_status_deps = [
    dep_gtk3,
    dep_peas,
    dep_accountsservice,
    dependency('gnome-bluetooth-1.0', version: gnome_minimum_version),
    dependency('upower-glib', version: '>= 0.99.0'),
    link_libplugin,
    gvc.get_variable('link_libgvc'),
]

shared_library(
    'statusapplet',
    applet_status_sources,
    dependencies: applet_status_deps,
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'accountsservice',
        '--pkg', 'gvc-1.0',
        '--vapidir', join_paths(meson.source_root(), 'vapi'),
    ],
    install: true,
    install_dir: applet_status_dir,
)

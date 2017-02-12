# Tray Applet build

applet_tray_dir = applets_dir + '.tray'

custom_target('plugin-file-tray',
    input : 'TrayApplet.plugin.in',
    output : 'TrayApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_tray_dir)

applet_tray_sources = [
    'TrayApplet.vala',
]

applet_tray_deps = [
    dep_gtk3,
    dep_peas,
    link_libnatray,
    link_libplugin,
]

shared_library(
    'trayapplet',
    applet_tray_sources,
    dependencies: applet_tray_deps,
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'natray-1.0',
        '--vapidir', join_paths(meson.source_root(), 'src', 'imports', 'natray'),
    ],
    install: true,
    install_dir: applet_tray_dir,
)

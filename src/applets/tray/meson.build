# Tray Applet build

subdir('carbontray')

applet_tray_dir = applets_dir + '.tray'

custom_target('plugin-file-tray',
    input : 'TrayApplet.plugin.in',
    output : 'TrayApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_tray_dir)

gresource = join_paths(meson.current_source_dir(), 'plugin.gresource.xml')

applet_tray_resources = gnome.compile_resources(
    'tray-applet-resources',
    gresource,
    source_dir: meson.current_source_dir(),
    c_name: 'budgie_tray',
)

applet_tray_sources = ['TrayApplet.vala', applet_tray_resources]

applet_tray_deps = [
    libplugin_vapi,
    dep_gtk3,
    dependency('x11'),
    dependency('gdk-x11-3.0'),
    dep_peas,
    link_libcarbontray,
    link_libplugin,
]

shared_library(
    'trayapplet',
    applet_tray_sources,
    dependencies: applet_tray_deps,
    vala_args: [
        '--pkg', 'libpeas-1.0',
        join_paths(meson.source_root(), 'src', 'applets', 'tray', 'carbontray', 'carbontray-1.0.vapi'),
    ],
    install: true,
    install_dir: applet_tray_dir,
)

install_data(
    'com.solus-project.tray.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

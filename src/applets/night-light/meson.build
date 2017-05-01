# Night Light Applet build

applet_nightlight_dir = applets_dir + '.night-light'

custom_target('plugin-file-nightlight',
    input : 'NightLight.plugin.in',
    output : 'NightLight.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_nightlight_dir)

gresource = join_paths(meson.current_source_dir(), 'org.budgie-desktop.night-light.gresource.xml')

# Compile the assets into the binary
applet_nightlight_resources = gnome.compile_resources(
    'nightlight-applet-resources',
    gresource,
    source_dir: meson.current_source_dir(),
    c_name: 'budgie_nightlight',
)

applet_nightlight_sources = [
    'NightLight.vala',
    'IndicatorWindow.vala',
    applet_nightlight_resources
]

applet_nightlight_deps = [
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'nightlightapplet',
    applet_nightlight_sources,
    dependencies: applet_nightlight_deps,
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--vapidir', dir_libplugin,
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource
    ],
    install: true,
    install_dir: applet_nightlight_dir,
)

# Places Indicator Build

applet_placesindicator_dir = applets_dir + '.places-indicator'

custom_target('plugin-file-placesindicator',
    input : 'PlacesIndicator.plugin.in',
    output : 'PlacesIndicator.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_placesindicator_dir)

gresource = join_paths(meson.current_source_dir(), 'plugin.gresource.xml')

# Compile the assets into the binary
applet_placesindicator_resources = gnome.compile_resources(
    'places-applet-resources',
    gresource,
    source_dir: meson.current_source_dir(),
    c_name: 'budgie_placesindicator',
)

applet_placesindicator_sources = [
    'PlacesIndicator.vala',
    'PlacesIndicatorWindow.vala',
    'MessageRevealer.vala',
    'PlacesSection.vala',
    'ListItem.vala',
    'VolumeItem.vala',
    'MountItem.vala',
    'PlaceItem.vala',
    'MountHelper.vala',
    applet_placesindicator_resources,
]

applet_placesindicator_deps = [
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'placesindicator',
    applet_placesindicator_sources,
    dependencies: applet_placesindicator_deps,
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--vapidir', dir_libplugin,
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
    ],
    install: true,
    install_dir: applet_placesindicator_dir,
)

install_data(
    'com.solus-project.places-indicator.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

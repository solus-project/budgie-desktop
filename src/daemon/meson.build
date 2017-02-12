# Provides budgie-daemon component

custom_target('desktop-file-daemon',
    input : 'budgie-daemon.desktop.in',
    output : 'budgie-daemon.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'applications'))

# Compile the assets into the binary
daemon_resources = gnome.compile_resources(
    'budgie-daemon-resources',
    'budgie-daemon.gresource.xml',
    source_dir: '.',
    c_name: 'budgie_polkit',
)

daemon_sources = [
    'endsession.vala',
    'main.vala',
    'manager.vala',
    'osd.vala',
    theme_resources,
]

daemon_deps = [
    dep_gtk3,
    link_libtheme,
    link_libsession,
    dependency('gdk-x11-3.0', version: gnome_minimum_version)
]


# Need absolute path to gresource
gresource = join_paths(meson.current_source_dir(), 'budgie-daemon.gresource.xml')

executable(
    'budgie-daemon', daemon_sources,
    dependencies: daemon_deps,
    include_directories: include_directories(dir_libconfig),
    vala_args: [
        '--vapidir', dir_libtheme,
        '--vapidir', dir_libconfig,
        '--pkg', 'theme',
        '--pkg', 'budgie-config',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gdk-x11-3.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
    ],
    install: true,
)

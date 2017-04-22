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
    'menus.vala',
    'osd.vala',
    'settings.vala',
    'tabswitcher.vala',
    daemon_resources,
]

daemon_deps = [
    dep_gtk3,
    dep_gdkx11,
    dep_wnck,
    link_libconfig,
    link_libtheme,
    link_libsession,
]


# Need absolute path to gresource
gresource = join_paths(meson.current_source_dir(), 'budgie-daemon.gresource.xml')

executable(
    'budgie-daemon', daemon_sources,
    dependencies: daemon_deps,
    vala_args: [
        '--vapidir', dir_libtheme,
        '--vapidir', dir_libconfig,
        '--pkg', 'theme',
        '--pkg', 'budgie-config',
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gdk-x11-3.0',
        '--pkg', 'libwnck-3.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
    ],
    c_args: [
        '-DWNCK_I_KNOW_THIS_IS_UNSTABLE',
    ],
    install: true,
)

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
    dep_notify,
    dep_wnck,
    link_libappsys,
    link_libconfig,
    link_libtheme,
    link_libsession,
]


# Need absolute path to gresource
gresource = join_paths(meson.current_source_dir(), 'budgie-daemon.gresource.xml')

daemon_vala_args = []

dep_gsd_doubles = dependency('gnome-settings-daemon', version: '>=3.33.90', required: false)
if dep_gsd.found()
    daemon_vala_args += ['-D', 'USE_GSD_DOUBLES']
    message('Found GNOME Settings Daemon >= 3.33.90')
endif

executable(
    'budgie-daemon', daemon_sources,
    dependencies: daemon_deps,
    vala_args: [
        '--vapidir', dir_libtheme,
        '--vapidir', dir_libconfig,
        '--vapidir', dir_libappsys,
        '--pkg', 'theme',
        '--pkg', 'budgie-config',
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gdk-x11-3.0',
        '--pkg', 'libwnck-3.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
        daemon_vala_args,
    ],
    c_args: [
        '-DWNCK_I_KNOW_THIS_IS_UNSTABLE',
    ],
    install: true,
)

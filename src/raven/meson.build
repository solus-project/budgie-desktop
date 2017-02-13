# Provides budgie's Raven component

gresource = join_paths(meson.current_source_dir(), 'ui', 'budgie-raven.gresource.xml')

# Compile the assets into the binary
libraven_resources = gnome.compile_resources(
    'budgie-raven-resources',
    gresource,
    'budgie-daemon.gresource.xml',
    source_dir: join_paths(meson.current_source_dir(), 'ui'),
    c_name: 'budgie_raven',
)

libraven_sources = [
    'calendar.vala',
    'headerwidget.vala',
    'main_view.vala',
    'notifications_view.vala',
    'powerstrip.vala',
    'raven.vala',
    'settings_view.vala',
    'sound.vala',
    'themes.vala',
    'mpris/MprisClient.vala',
    'mpris/MprisGui.vala',
    'mpris/MprisWidget.vala',
    libraven_resources,
]

libraven_deps = [
    dep_gtk3,
    dep_peas,
    link_libconfig,
    link_libplugin,
    link_libtoplevel,
    link_libtheme,
    gvc.get_variable('link_libgvc'),
]

top_vapidir = join_paths(meson.source_root(), 'vapi')

libraven = shared_library(
    'raven', libraven_sources,
    version: '0.0.0',
    dependencies: libraven_deps,
    vala_args: [
        '--vapidir', dir_libtheme,
        '--vapidir', dir_libconfig,
        '--vapidir', dir_libplugin,
        '--vapidir', top_vapidir,
        '--pkg', 'theme',
        '--pkg', 'budgie-config',
        '--pkg', 'gvc-1.0',
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gdk-x11-3.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
    ],
    install: true,
)

link_libraven = declare_dependency(
    link_with: libraven,
    include_directories: include_directories(meson.current_source_dir()),
    include_directories: include_directories(meson.current_build_dir()),
)

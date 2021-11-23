# Provides budgie's Raven component

gresource = join_paths(meson.current_source_dir(), 'ui', 'budgie-raven.gresource.xml')

# Compile the assets into the binary
libraven_resources = gnome.compile_resources(
    'budgie-raven-resources',
    gresource,
    source_dir: join_paths(meson.current_source_dir(), 'ui'),
    c_name: 'budgie_raven',
)

libraven_sources = [
    'app_sound_control.vala',
    'calendar.vala',
    'headerwidget.vala',
    'main_view.vala',
    'mpris/MprisClient.vala',
    'mpris/MprisGui.vala',
    'mpris/MprisWidget.vala',
    'notification_clone.vala',
    'notifications_group.vala',
    'notifications_view.vala',
    'powerstrip.vala',
    'raven.vala',
    'sound.vala',
    'start_listening.vala',
    'widget.vala',
    libraven_resources,
]

libraven_deps = [
    # XXX: Keep this order the same to work around
    # https://github.com/mesonbuild/meson/issues/2096
    link_libbudgieprivate,
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    link_libconfig,
    link_libplugin,
    link_libtheme,
    gvc.get_variable('libgvc_dep'),
    meson.get_compiler('c').find_library('m', required: false),
]

top_vapidir = join_paths(meson.source_root(), 'vapi')

libraven = shared_library(
    'raven', libraven_sources,
    version: '0.0.0',
    dependencies: libraven_deps,
    vala_args: [
        '--vapidir', dir_libtheme,
        '--vapidir', dir_libconfig,
        '--vapidir', top_vapidir,
        '--pkg', 'theme',
        '--pkg', 'budgie-config',
        '--pkg', 'gvc-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gdk-x11-3.0',
        '--pkg', 'gio-unix-2.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
    ],
    install: true,
    install_rpath: rpath_libdir,
)

link_libraven = declare_dependency(
    link_with: libraven,
    include_directories: include_directories('.'),
)

# gschemas
install_data(
    'com.solus-project.budgie.raven.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

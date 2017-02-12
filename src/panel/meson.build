# Provides budgie's main panel component

# Handle i18n on the .desktop file
# Stole from TingPing:
# https://github.com/vinszent/gnome-twitch/blob/master/data/meson.build
custom_target('desktop-file-panel',
    input : 'budgie-panel.desktop.in',
    output : 'budgie-panel.desktop',
    command : [msgfmt, '--desktop', '--template', '@INPUT@', '-d', podir, '-o', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'applications'))

gresource = join_paths(meson.source_root(), 'data', 'budgie-panel.gresource.xml')

# Compile the assets into the binary
panel_resources = gnome.compile_resources(
    'budgie-panel-resources',
    gresource,
    'budgie-daemon.gresource.xml',
    source_dir: join_paths(meson.source_root(), 'data'),
    c_name: 'budgie_panel',
)

panel_sources = [
    'main.vala',
    'manager.vala',
    'panel.vala',
    'popovers.vala',
    'uuid.vala',
    panel_resources,
]

panel_deps = [
    dep_gtk3,
    dep_peas,
    dep_libuuid,
    link_libsession,
    link_libtoplevel,
    link_libtheme,
    link_libplugin,
    link_libraven,
    gvc.get_variable('link_libgvc'),
]

top_vapidir = join_paths(meson.source_root(), 'vapi')

executable(
    'budgie-panel', panel_sources,
    dependencies: panel_deps,
    include_directories: include_directories(dir_libconfig),
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

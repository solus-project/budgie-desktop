# Provides budgie-polkit component

custom_target('desktop-file-polkit',
    input : 'budgie-polkit.desktop.in',
    output : 'budgie-polkit.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'applications'))

# Compile the assets into the binary
polkit_resources = gnome.compile_resources(
    'budgie-polkit-resources',
    'budgie-polkit.gresource.xml',
    source_dir: '.',
    c_name: 'budgie_polkit',
)

polkit_sources = [
    'polkitdialog.vala',
    theme_resources,
]

# Don't need APIs from anything older than this
pkversion = '>= 0.105'

polkit_deps = [
    dep_gtk3,
    link_libconfig,
    link_libtheme,
    link_libsession,
    dependency('polkit-gobject-1', version: pkversion),
    dependency('polkit-agent-1', version: pkversion),
]

# polkit vapi files are in top vapi dir
pkvapi = join_paths(meson.source_root(), 'vapi')

# Need absolute path to gresource
gresource = join_paths(meson.current_source_dir(), 'budgie-polkit.gresource.xml')

executable(
    'budgie-polkit-dialog', polkit_sources,
    dependencies: polkit_deps,
    vala_args: [
        '--vapidir', dir_libtheme,
        '--vapidir', dir_libconfig,
        '--vapidir', pkvapi,
        '--pkg', 'theme',
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'budgie-config',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'polkit-gobject-1',
        '--pkg', 'polkit-agent-1',
        '--pkg', 'posix',
        '--pkg', 'theme',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
    ],
    c_args: [
        '-DPOLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE',
    ],
    install: true,
)

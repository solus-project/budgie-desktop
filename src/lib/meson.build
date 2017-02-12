# libtoplevel provides an in-tree ABI for Raven + Panel

libtoplevel_sources = [
    'animation.vala',
    'toplevel.vala',
    'shadow.vala',
    'manager.vala',
]

libtoplevel = static_library(
    'toplevel',
    libtoplevel_sources,
    dependencies: [
        link_libplugin,
        dep_peas,
        dep_gtk3,
        meson.get_compiler('c').find_library('m', required: false),
    ],
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'libpeas-1.0',
        '--vapidir', dir_libplugin,
        '-H', 'BudgieToplevel.h',
    ],
)

link_libtoplevel = declare_dependency(
    link_with: libtoplevel,
    include_directories: include_directories('.'),
)

# Expose the current directory so that we can use vapidir
dir_libtoplevel = meson.current_source_dir()

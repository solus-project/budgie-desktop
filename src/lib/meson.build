# libbudgieprivate provides a private ABI for Raven + Panel

libbudgieprivate_sources = [
    'animation.vala',
    'toplevel.vala',
    'shadow.vala',
    'manager.vala',
]

libbudgieprivate = shared_library(
    'budgie-private',
    libbudgieprivate_sources,
    dependencies: [
        libplugin_vapi,
        link_libplugin,
        dep_peas,
        dep_gtk3,
        meson.get_compiler('c').find_library('m', required: false),
    ],
    vala_args: [
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'libpeas-1.0',
    ],
    version: '0.0.0',
    install: true,
)

link_libbudgieprivate = declare_dependency(
    link_with: libbudgieprivate,
    include_directories: [
        include_directories('.'),
    ],
)

# Expose the current directory so that we can use vapidir
dir_libbudgieprivate = meson.current_source_dir()

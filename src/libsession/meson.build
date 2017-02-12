# libsesion is just a vala .a archive

libsession_sources = [
    'libsession.vala',
]

libsession = static_library(
    'session',
    libsession_sources,
    dependencies: dep_glib,
    vala_args: [
        '--pkg', 'gio-unix-2.0',
    ],
)

link_libsession = declare_dependency(
    link_with: libsession,
    include_directories: include_directories('.'),
)

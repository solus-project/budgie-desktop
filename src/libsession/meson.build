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
        '-H', 'BudgieSession.h',
    ],
)

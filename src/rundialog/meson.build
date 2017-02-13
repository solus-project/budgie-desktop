# Provides budgie-run-dialog binary
rundialog_sources = [
    'RunDialog.vala'
]

rundialog_deps = [
    dep_gtk3,
    link_libconfig,
    link_libtheme,
]

executable(
    'budgie-run-dialog', rundialog_sources,
    dependencies: rundialog_deps,
    vala_args: [
        '--vapidir', dir_libtheme,
        '--vapidir', dir_libconfig,
        '--pkg', 'theme',
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'budgie-config',
    ],
    install: true,
)

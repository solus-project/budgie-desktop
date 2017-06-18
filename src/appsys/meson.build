# libappsys provides an in-tree ABI for Raven + Panel

libappsys_sources = [
    'AppSystem.vala',
]

libappsys = static_library(
    'appsys',
    libappsys_sources,
    dependencies: [
        dep_gtk3,
        dep_gdkx11,
        dep_wnck,
        link_libconfig,
    ],
    vala_args: [
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gdk-x11-3.0',
        '--pkg', 'libwnck-3.0',
        '-H', 'BudgieAppSystem.h',
    ],
    c_args: [
        '-DWNCK_I_KNOW_THIS_IS_UNSTABLE',
    ],
)

link_libappsys = declare_dependency(
    link_with: libappsys,
    include_directories: [
        include_directories('.'),
        include_directories('../../'),
    ],
)

# Expose the current directory so that we can use vapidir
dir_libappsys = meson.current_build_dir()

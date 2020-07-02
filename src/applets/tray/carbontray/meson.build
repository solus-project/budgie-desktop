libcarbontray_deps = [
    dep_gtk3,
    dependency('gtk+-x11-3.0'),
    dependency('x11'),
]

libcarbontray_sources = [
    'tray.c',
    'child.c'
]

libcarbontray_marshal_files = gnome.genmarshal('marshal', sources: 'marshal.list')

libcarbontray = static_library(
    'carbontray',
    libcarbontray_sources + libcarbontray_marshal_files,
    dependencies: libcarbontray_deps,
    include_directories: [
        include_directories('.'),
        include_directories(join_paths('..', '..', '..')),
    ],
)

link_libcarbontray = declare_dependency(
    link_with: libcarbontray,
    include_directories: include_directories('.'),
)

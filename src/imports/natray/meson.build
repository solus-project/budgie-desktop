# libnatray provides the old GNOME Panel natray code for use in Budgie

gnome = import('gnome')
marshal_files = gnome.genmarshal('na-marshal',
  sources: 'na-marshal.list',
)

libnatray_deps = [
    dep_gtk3,
    dependency('gtk+-x11-3.0', version: gnome_minimum_version),
    dependency('x11'),
]

libnatray_sources = [
    'na-grid.c',
    'na-item.c',
    'na-host.c',
    'na-tray.c',
    'na-tray-child.c',
    'na-tray-manager.c',
]

libnatray = static_library(
    'natray',
    libnatray_sources + marshal_files,
    dependencies: libnatray_deps,
    include_directories: [
        include_directories('.'),
        include_directories(join_paths('..', '..', '..')),
    ],
)

link_libnatray = declare_dependency(
    link_with: libnatray,
    include_directories: include_directories('.'),
)

# Expose the current directory so that we can use vapidir
dir_libnatray = meson.current_source_dir()

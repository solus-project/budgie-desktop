# libnatray provides the old GNOME Panel natray code for use in Budgie

libnatray_deps = [
    dep_gtk3,
    dependency('gtk+-x11-3.0', version: gnome_minimum_version),
    dependency('x11'),
]

libnatray_sources = [
    'na-tray.c',
    'na-tray-child.c',
    'na-tray-manager.c',
    'fixedtip.c',
]

libnatray = static_library(
    'natray',
    libnatray_sources,
    dependencies: libnatray_deps,
)

link_libnatray = declare_dependency(
    link_with: libnatray,
    include_directories: include_directories('.'),
)

# Expose the current directory so that we can use vapidir
dir_libnatray = meson.current_source_dir()

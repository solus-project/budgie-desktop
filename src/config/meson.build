# libbudgieconfig is just a simple .a archive to fix linking in vala
# builds by restricting defines to one place.

libconfig_sources = [
    'budgie-config.c',
]

libconfig = static_library(
    'config',
    libconfig_sources,
    include_directories: extra_includes,
)

link_libconfig = declare_dependency(
    link_with: libconfig,
    include_directories: [
        include_directories('.'),
        extra_includes,
    ],
)

# Expose the current directory so that we can use vapidir
dir_libconfig = meson.current_source_dir()

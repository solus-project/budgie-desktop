# Provides the core API for budgie 10 plugins
gnome = import('gnome')
pkgconfig = import('pkgconfig')

# Generate enums for gobject typing
plugin_enums = gnome.mkenums(
    'budgie-enums',
    sources: [
        'applet.h',
        'popover.h',
    ],
    c_template: 'budgie-enums.c.template',
    h_template: 'budgie-enums.h.template',
    install_header: true,
    install_dir: join_paths(get_option('includedir'), 'budgie-desktop'),
)

# Fight meson race conditions..
libenum = static_library(
    'enum',
    plugin_enums,
    dependencies: dep_gtk3,
)

link_libenum = declare_dependency(
    sources: plugin_enums,
    include_directories: include_directories('.'),
)

# install headers
plugin_headers = [
	'plugin.h',
	'applet.h',
	'applet-info.h',
    'popover.h',
	'popover-manager.h',
]

plugin_sources = [
    'applet.c',
    'applet-info.c',
    'plugin.c',
    'popover.c',
    'popover-manager.c',
]

plugin_deps = [
    dep_gtk3,
    dep_peas,
]

# build plugin
libplugin = shared_library(
    'budgie-plugin',
    plugin_sources,
    dependencies: [
        plugin_deps,
        link_libenum,
    ],
    version: '0.0.0',
    install: true,
)

install_headers(plugin_headers, subdir: 'budgie-desktop')

# Generate .gir
libplugin_gir = gnome.generate_gir(
    libplugin,
    sources: plugin_sources + plugin_headers + plugin_enums,
    namespace: 'Budgie',
    nsversion: '1.0',
    dependencies: plugin_deps,
    includes: [
        'GObject-2.0',
        'Gio-2.0',
        'Gtk-3.0',
        'Peas-1.0',
    ],
    symbol_prefix: 'budgie',
    identifier_prefix: 'Budgie',
    install: true,
    extra_args: [
        '--warn-all',
        '--c-include', 'plugin.h',
    ],
)

libplugin_vapi = gnome.generate_vapi(
    'budgie-1.0',
    sources: [libplugin_gir[0]],
    packages: [
        'gtk+-3.0',
        'gio-unix-2.0',
        'libpeas-1.0',
    ],
    install: true,
)

# Install pkgconfig file to enable building against budgie-plugin
pkgconfig.generate(
    name: 'Budgie',
    description: 'Budgie Plugin Library',
    version: '2',
    filebase: 'budgie-1.0',
    subdirs: 'budgie-desktop',
    libraries: ['-L${libdir}', '-lbudgie-plugin'],
    requires: [
        'gtk+-3.0 >= 3.18.0',
        'libpeas-1.0 >= 1.8.0',
        'glib-2.0 >= 2.46.0',
        'gio-unix-2.0 >= 2.46.0',
    ],
)


link_libplugin = declare_dependency(
    link_with: libplugin,
    dependencies: plugin_deps,
    include_directories: [
        include_directories('.'),
    ],
)

# Expose the current directory so that we can use vapidir
dir_libplugin = meson.current_source_dir()

# Provides the core API for budgie 10 plugins
gnome = import('gnome')
pkgconfig = import('pkgconfig')

# Generate enums for gobject typing
plugin_enums = gnome.mkenums(
    'budgie-enums',
    sources: 'applet.h',
    c_template: 'budgie-enums.c.template',
    h_template: 'budgie-enums.h.template',
    install_header: true,
    install_dir: join_paths(get_option('includedir'), 'budgie-desktop'),
)

# install headers
plugin_headers = [
	'plugin.h',
	'applet.h',
	'applet-info.h',
	'popover-manager.h',
]

plugin_sources = [
    'applet.c',
    'applet-info.c',
    'plugin.c',
    'popover-manager.c',
]

# build plugin
libplugin = shared_library(
    'budgie-plugin',
    plugin_sources + plugin_enums,
    dependencies: [
        dep_gtk3,
        dep_peas,
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
    includes: [
        'GObject-2.0',
        'Gio-2.0',
        'Gtk-3.0',
        'Peas-1.0',
    ],
    symbol_prefix: 'budgie',
    install: true,
    extra_args: [
        '--warn-all',
        '--c-include', 'plugin.h',
    ],
)

# Install the (hand written..) vapi binding
plugin_vapi = [
    'budgie-1.0.vapi',
    'budgie-1.0.deps',
]
install_data(plugin_vapi, install_dir: join_paths(get_option('datadir'), 'vala', 'vapi'))

# Install pkgconfig file to enable building against budgie-plugin
pkgconfig.generate(
    name: 'Budgie',
    description: 'Budgie Plugin Library',
    version: '2',
    filebase: 'budgie-1.0',
    libraries: ['-L${libdir}', '-lbudgie-plugin'],
    requires: [
        'gtk+-3.0 >= 3.18.0',
        'libpeas-1.0 >= 1.8.0',
        'libpeas-gtk-1.0 >= 1.8.0',
        'glib-2.0 >= 2.46.0',
        'gio-unix-2.0 >= 2.46.0',
    ],
)

link_libplugin = declare_dependency(
    link_with: libplugin,
    include_directories: include_directories('.'),
)

# Expose the current directory so that we can use vapidir
dir_libplugin = meson.current_source_dir()

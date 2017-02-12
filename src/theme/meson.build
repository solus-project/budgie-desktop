gnome = import('gnome')
pkgconfig = import('pkgconfig')

# Compile the assets into the .so
theme_resources = gnome.compile_resources(
    'budgie-theme-resources',
    'budgie-theme.gresource.xml',
    source_dir: '.',
    c_name: 'budgie_desktop_theme',
)

theme_sources = [
    'theme.c',
    'theme-manager.c',
    theme_resources,
]

lib_theme = shared_library(
    'budgietheme',
    theme_sources,
    dependencies: [
        dep_gtk3,
        dep_glib,
    ],
    version: '0.0.0',
    install: true,
)

theme_headers = [
    'theme.h',
]

install_headers(theme_headers, subdir: 'budgie-desktop')

# Allow building against libbudgietheme
pkgconfig.generate(
    name: 'Budgie Theme',
    description: 'Budgie Theme Library',
    version: '2',
    filebase: 'budgie-theme-1.0',
    libraries: ['-L${libdir}', '-lbudgietheme'],
    requires: ['gtk+-3.0 >= 3.18.0'],
)

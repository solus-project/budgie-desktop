gnome = import('gnome')
pkgconfig = import('pkgconfig')

# Compile to CSS dynamically.
sassc = find_program('sassc')

# Normal and high contrast
theme_variants = [
    '',
    '_hc',
]

theme_deps = []
theme_versions = [
    '3.20',
]

foreach version : theme_versions
    foreach variant : theme_variants
        # Build the main CSS stylesheet
        theme_deps += custom_target('theme' + variant + '_' + version + '.css',
            input: version + '/theme' + variant + '.scss',
            output: 'theme' + variant + '_' + version + '.css',
            command: [sassc, '-M', '-t', 'compressed', '@INPUT@', '@OUTPUT@'],
        )
    endforeach
endforeach

# Compile the assets into the .so
theme_resources = gnome.compile_resources(
    'budgie-theme-resources',
    'budgie-theme.gresource.xml',
    source_dir: meson.current_build_dir(),
    dependencies: theme_deps,
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
    requires: ['gtk+-3.0 >= 3.22.0'],
)

link_libtheme = declare_dependency(
    link_with: lib_theme,
    include_directories: include_directories('.'),
)

# Expose the current directory so that we can use vapidir
dir_libtheme = meson.current_source_dir()

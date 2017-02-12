project(
    'budgie-desktop',
    ['c', 'vala'],
    version: '10.2.9',
    license: [
        'GPL-2.0',
        'LGPL-2.1',
    ],
    default_options: [
        'c_std=c11',
    ],
)

# Budgie needs a minimum 3.18 GNOME stack
gnome_minimum_version = '>= 3.18.0'

dep_gtk3 = dependency('gtk+-3.0', version: gnome_minimum_version)
dep_glib = dependency('glib-2.0', version: '>= 2.46.0')

# Create config.h
cdata = configuration_data()
cdata.set_quoted('PACKAGE_VERSION', meson.project_version())

# Write config.h
configure_file(
    output: 'config.h',
    configuration: cdata,
)

# Enable others to find this .h file
extra_includes = [
    include_directories('.'),
]

subdir('src')

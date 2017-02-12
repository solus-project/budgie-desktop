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
dep_peas = dependency('libpeas-gtk-1.0', version: '>= 1.8.0')

# Create config.h
cdata = configuration_data()
cdata.set_quoted('PACKAGE_VERSION', meson.project_version())

# Make gettext work
cdata.set_quoted('GETTEXT_PACKAGE', meson.project_name())
add_global_arguments('-DGETTEXT_PACKAGE="budgie-desktop"', language: 'c')

prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
confdir = join_paths(prefix, get_option('sysconfdir'))
datadir = join_paths(prefix, get_option('datadir'))
localedir = join_paths(prefix, get_option('localedir'))

cdata.set_quoted('MODULEDIR', join_paths(libdir, meson.project_name(), 'plugins'))
cdata.set_quoted('MODULE_DATA_DIR', join_paths(datadir, meson.project_name(), 'plugins'))
cdata.set_quoted('DATADIR', datadir)
cdata.set_quoted('SYSCONFDIR', confdir)
cdata.set_quoted('LOCALEDIR', localedir)
cdata.set_quoted('PACKAGE_URL', 'https://budgie-desktop.org')

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

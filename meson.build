project(
    'budgie-desktop',
    ['c', 'vala'],
    version: '10.4',
    license: [
        'GPL-2.0',
        'LGPL-2.1',
    ],
    default_options: [
        'c_std=c11',
    ],
)

git = find_program('git', required: false)

am_cflags = [
    '-fstack-protector',
    '-pedantic',
    '-Wstrict-prototypes',
    '-Wundef',
    '-Werror-implicit-function-declaration',
    '-Wformat',
    '-Wformat-security',
    '-Werror=format-security',
    '-Wconversion',
    '-Wunused-variable',
    '-Wunreachable-code',
    '-Wall',
    '-W',
]

add_global_arguments(am_cflags, language: 'c')
meson.add_install_script('meson_post_install.sh')

# Budgie needs a minimum 3.18 GNOME stack
gnome_minimum_version = '>= 3.18.0'

dep_gtk3 = dependency('gtk+-3.0', version: gnome_minimum_version)
dep_glib = dependency('glib-2.0', version: '>= 2.46.0')
dep_giounix = dependency('gio-unix-2.0', version: '>= 2.46.0')
dep_peas = dependency('libpeas-1.0', version: '>= 1.8.0')
dep_gdkx11 = dependency('gdk-x11-3.0', version: gnome_minimum_version)
dep_libuuid = dependency('uuid')

# gtk 3.18 needed for old APIs
dep_gtk318 = dependency('gtk+-3.0', version: '< 3.19', required: false)

# Needed for keyboardy bits
dep_ibus = dependency('ibus-1.0', verion: '>= 1.5.10')
dep_gnomedesktop = dependency('gnome-desktop-3.0', version: gnome_minimum_version)
dep_gsettings = dependency('gsettings-desktop-schemas', version: gnome_minimum_version)

# wnck used all over the place..
dep_wnck = dependency('libwnck-3.0', version: '>= 3.14.0')

# accountsservice in multiple applets
dep_accountsservice = dependency('accountsservice', version: '>= 0.6.40')

# Create config.h
cdata = configuration_data()

# Inspired by https://github.com/GNOME/recipes/blob/master/meson.build
package_version = meson.project_version()

if git.found()
    git_version = run_command('git', ['describe'])
    if git_version.returncode() == 0
        package_version = git_version.stdout().strip()
    endif
endif

cdata.set_quoted('PACKAGE_VERSION', package_version)

# Make gettext work
cdata.set_quoted('GETTEXT_PACKAGE', meson.project_name())
add_global_arguments('-DGETTEXT_PACKAGE="budgie-desktop"', language: 'c')

# Globals that we need
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
confdir = join_paths(prefix, get_option('sysconfdir'))
datadir = join_paths(prefix, get_option('datadir'))
localedir = join_paths(prefix, get_option('localedir'))
podir = join_paths(meson.source_root(), 'po')

# Handle i18n on the .desktop file
# Originally stolem from TingPing:
# https://github.com/vinszent/gnome-twitch/blob/master/data/meson.build
# Later changed to use intltool as we use _Key style files
intltool = find_program('intltool-merge')

# Make sure this is accessible to panel applet builds
plugin_libdir = join_paths(libdir, meson.project_name(), 'plugins')

cdata.set_quoted('MODULEDIR', plugin_libdir)
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

# Determine if polkit is allowed.
with_polkit = get_option('with-polkit')

# Get gvc built before we do anything
gvc = subproject('gvc',
    default_options: [
    'c_std=c89',
    'static=true',
  ]
)

# Prep translations prior to build
subdir('po')

# Now build Budgie proper
subdir('src')

# Documentation...
if get_option('with-gtk-doc') == true
    subdir('docs')
endif

# And lastly, data bits
subdir('data')

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
dep_ibus = dependency('ibus-1.0', version: '>= 1.5.10')
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
plugin_datadir = join_paths(datadir, meson.project_name(), 'plugins')

cdata.set_quoted('MODULEDIR', plugin_libdir)
cdata.set_quoted('MODULE_DATA_DIR', plugin_datadir)
cdata.set_quoted('DATADIR', datadir)
cdata.set_quoted('SYSCONFDIR', confdir)
cdata.set_quoted('LOCALEDIR', localedir)
cdata.set_quoted('PACKAGE_URL', 'https://budgie-desktop.org')

with_desktop_icons = get_option('with-desktop-icons')
if with_desktop_icons ==  'nautilus'
  #  warning('You must have Nautilus 3.26 or older for desktop icons with Budgie')
endif

with_stateless = get_option('with-stateless')
if with_stateless == true
  #  warning('Only use stateless option with a supported OS like Solus')
endif

# GVC rpath. it's evil, but gvc will bomb out glib2 due to static linking weirdness now,
# so we have to use a shared library to prevent multiple registration of the same types..
rpath_libdir = join_paths(libdir, meson.project_name())

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
    'package-name=@0@'.format(meson.project_name()),
    'static=false',
    'pkglibdir=@0@'.format(rpath_libdir),
  ],
)

# Prep translations prior to build
subdir('po')

# Now build Budgie proper
subdir('src')

# Documentation...
with_gtk_doc = get_option('with-gtk-doc')
if with_gtk_doc == true
    subdir('docs')
endif

# And lastly, data bits
subdir('data')

report = [
    '    Build configuration:',
    '    ====================',
    '',
    '    prefix:                                 @0@'.format(prefix),
    '    datadir:                                @0@'.format(datadir),
    '    sysconfdir:                             @0@'.format(confdir),
    '    localedir:                              @0@'.format(localedir),
    '    libdir:                                 @0@'.format(libdir),
    '    module library directory:               @0@'.format(plugin_libdir),
    '    module data directory:                  @0@'.format(plugin_datadir),
    '',
    '    Extra options:',
    '    ==============',
    '',
    '    gtk-doc:                                @0@'.format(with_gtk_doc),
    '    desktop icons:                          @0@'.format(with_desktop_icons),
    '    stateless:                              @0@'.format(with_stateless),
]


# Output some stuff to validate the build config
message('\n\n\n' + '\n'.join(report) + '\n\n')

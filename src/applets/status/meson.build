# Status Applet build

applet_status_dir = applets_dir + '.status'

custom_target('plugin-file-status',
    input : 'StatusApplet.plugin.in',
    output : 'StatusApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_status_dir)

applet_status_sources = [
    'StatusApplet.vala',
    'PowerIndicator.vala',
    'SoundIndicator.vala',
]

applet_status_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    dep_accountsservice,
    dependency('upower-glib', version: '>= 0.99.0'),
    link_libplugin,
    gvc.get_variable('libgvc_dep'),
    meson.get_compiler('c').find_library('m', required: false),
]

# Bluetooth is optional to allow smaller builds
with_bluetooth = get_option('with-bluetooth')
applet_status_vala_args = []

if with_bluetooth == true
    applet_status_deps += dependency('gnome-bluetooth-1.0', version: gnome_minimum_version)
    applet_status_sources += 'BluetoothIndicator.vala'
    applet_status_vala_args += ['-D', 'WITH_BLUETOOTH']
endif

# For old schemas that don't have show-battery-percentage
if dep_gtk318.found()
    applet_status_vala_args += ['-D', 'HAVE_GTK_318']
endif

shared_library(
    'statusapplet',
    applet_status_sources,
    dependencies: applet_status_deps,
    c_args: [
        '-lm'
    ],
    vala_args: [
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'accountsservice',
        '--pkg', 'gvc-1.0',
        '--pkg', 'gio-unix-2.0',
        '--vapidir', join_paths(meson.source_root(), 'vapi'),
        applet_status_vala_args,
    ],
    install: true,
    install_dir: applet_status_dir,
    install_rpath: rpath_libdir,
)

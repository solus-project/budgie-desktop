# Clock Applet build

applet_clock_dir = applets_dir + '.clock'

custom_target('plugin-file-clock',
    input : 'ClockApplet.plugin.in',
    output : 'ClockApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_clock_dir)

applet_clock_sources = [
    'ClockApplet.vala',
]

applet_clock_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'clockapplet',
    applet_clock_sources,
    dependencies: applet_clock_deps,
    vala_args: [
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'gtk+-3.0',
    ],
    install: true,
    install_dir: applet_clock_dir,
)

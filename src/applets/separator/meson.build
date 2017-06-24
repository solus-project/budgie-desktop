# Separator Applet build

applet_separator_dir = applets_dir + '.separator'

custom_target('plugin-file-separator',
    input : 'SeparatorApplet.plugin.in',
    output : 'SeparatorApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_separator_dir)

applet_separator_sources = [
    'SeparatorApplet.vala',
]

applet_separator_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'separatorapplet',
    applet_separator_sources,
    dependencies: applet_separator_deps,
    vala_args: [
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
    ],
    install: true,
    install_dir: applet_separator_dir,
)

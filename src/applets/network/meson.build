# Network Applet build

applet_network_dir = applets_dir + '.network'

custom_target('plugin-file-network',
    input : 'NetworkApplet.plugin.in',
    output : 'NetworkApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_network_dir)

applet_network_sources = [
    'applet.c',
    'plugin.c',
]

applet_network_deps = [
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'networkapplet',
    applet_network_sources,
    dependencies: applet_network_deps,
    install: true,
    install_dir: applet_network_dir,
)

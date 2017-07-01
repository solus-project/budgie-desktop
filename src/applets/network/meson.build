# Network Applet build

# This is the only version I can test with, if lower is needed and validated
# as working, I'll lower the version requirement.
dep_nm = dependency('libnm-glib', version: '>= 1.4.4')

applet_network_dir = applets_dir + '.network'

custom_target('plugin-file-network',
    input : 'NetworkApplet.plugin.in',
    output : 'NetworkApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_network_dir)

applet_network_sources = [
    'applet.c',
    'ap-item.c',
    'common.c',
    'ethernet-item.c',
    'plugin.c',
    'wifi-item.c',
]

applet_network_deps = [
    dep_gtk3,
    dep_peas,
    dep_nm,
    link_libplugin,
]

shared_library(
    'networkapplet',
    applet_network_sources,
    dependencies: applet_network_deps,
    install: true,
    install_dir: applet_network_dir,
)

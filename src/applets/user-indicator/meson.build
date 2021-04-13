# User Indicator Applet build

applet_userindicator_dir = applets_dir + '.user-indicator'

custom_target('plugin-file-userindicator',
    input : 'UserIndicator.plugin.in',
    output : 'UserIndicator.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_userindicator_dir)

applet_userindicator_sources = [
    'DBusInterfaces.vala',
    'UserIndicator.vala',
    'UserIndicatorWindow.vala',
]

applet_userindicator_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    dep_accountsservice,
    link_libplugin,
]

shared_library(
    'userindicator',
    applet_userindicator_sources,
    dependencies: applet_userindicator_deps,
    vala_args: [
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'accountsservice',
        '--vapidir', join_paths(meson.source_root(), 'vapi'),
    ],
    install: true,
    install_dir: applet_userindicator_dir,
)

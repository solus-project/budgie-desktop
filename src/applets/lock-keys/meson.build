# Lock Keys Applet build

applet_lockkeys_dir = applets_dir + '.lock-keys'

custom_target('plugin-file-lockkeys',
    input : 'LockKeysApplet.plugin.in',
    output : 'LockKeysApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_lockkeys_dir)

applet_lockkeys_sources = [
    'LockKeysApplet.vala',
]

applet_lockkeys_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'lockkeysapplet',
    applet_lockkeys_sources,
    dependencies: applet_lockkeys_deps,
    vala_args: [
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--vapidir', dir_libplugin,
    ],
    install: true,
    install_dir: applet_lockkeys_dir,
)

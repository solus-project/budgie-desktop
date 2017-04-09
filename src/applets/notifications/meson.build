# Notifications Applet build

applet_notifications_dir = applets_dir + '.notifications'

custom_target('plugin-file-notifications',
    input : 'NotificationsApplet.plugin.in',
    output : 'NotificationsApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_notifications_dir)

applet_notifications_sources = [
    'NotificationsApplet.vala',
]

applet_notifications_deps = [
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'notificationsapplet',
    applet_notifications_sources,
    dependencies: applet_notifications_deps,
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--vapidir', dir_libplugin,
    ],
    install: true,
    install_dir: applet_notifications_dir,
)

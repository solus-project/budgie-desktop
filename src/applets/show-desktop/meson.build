# Show Desktop Applet build

applet_showdesktop_dir = applets_dir + '.show-desktop'

custom_target('plugin-file-showdesktop',
    input : 'ShowDesktopApplet.plugin.in',
    output : 'ShowDesktopApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_showdesktop_dir)

applet_showdesktop_sources = [
    'ShowDesktopApplet.vala',
]

applet_showdesktop_deps = [
    dep_gtk3,
    dep_wnck,
    dep_peas,
    link_libplugin,
]

shared_library(
    'showdesktopapplet',
    applet_showdesktop_sources,
    dependencies: applet_showdesktop_deps,
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'libwnck-3.0',
        '--vapidir', dir_libplugin,
    ],
    c_args: [
        '-DWNCK_I_KNOW_THIS_IS_UNSTABLE',
    ],
    install: true,
    install_dir: applet_showdesktop_dir,
)

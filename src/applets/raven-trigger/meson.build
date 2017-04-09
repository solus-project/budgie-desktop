# Raven Trigger Applet build

applet_raventrigger_dir = applets_dir + '.raven-trigger'

custom_target('plugin-file-raventrigger',
    input : 'RavenTriggerApplet.plugin.in',
    output : 'RavenTriggerApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_raventrigger_dir)

applet_raventrigger_sources = [
    'RavenTriggerApplet.vala',
]

applet_raventrigger_deps = [
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'raventriggerapplet',
    applet_raventrigger_sources,
    dependencies: applet_raventrigger_deps,
    vala_args: [
        '--pkg', 'budgie-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--vapidir', dir_libplugin,
    ],
    install: true,
    install_dir: applet_raventrigger_dir,
)

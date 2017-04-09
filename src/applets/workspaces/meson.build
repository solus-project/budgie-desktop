# Workspaces Applet build

applet_workspaces_dir = applets_dir + '.workspaces'

custom_target('plugin-file-workspaces',
    input : 'WorkspacesApplet.plugin.in',
    output : 'WorkspacesApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_workspaces_dir)

applet_workspaces_sources = [
    'WorkspacesApplet.vala',
]

applet_workspaces_deps = [
    dep_gtk3,
    dep_wnck,
    dep_peas,
    link_libplugin,
]

shared_library(
    'workspacesapplet',
    applet_workspaces_sources,
    dependencies: applet_workspaces_deps,
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
    install_dir: applet_workspaces_dir,
)

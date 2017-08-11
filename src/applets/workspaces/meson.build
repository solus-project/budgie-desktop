# Workspaces Applet build

applet_workspaces_dir = applets_dir + '.workspaces'

custom_target('plugin-file-workspaces',
    input : 'WorkspacesApplet.plugin.in',
    output : 'WorkspacesApplet.plugin',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : applet_workspaces_dir)

gresource = join_paths(meson.current_source_dir(), 'plugin.gresource.xml')

# Compile the assets into the binary
applet_workspaces_resources = gnome.compile_resources(
    'workspaces-applet-resources',
    gresource,
    source_dir: meson.current_source_dir(),
    c_name: 'budgie_workspaces',
)

applet_workspaces_sources = [
    'WorkspacesApplet.vala',
    'WorkspaceItem.vala',
    'WindowIcon.vala',
    applet_workspaces_resources,
]

applet_workspaces_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_wnck,
    dep_peas,
    link_libappsys,
    link_libplugin,
]

shared_library(
    'workspacesapplet',
    applet_workspaces_sources,
    dependencies: applet_workspaces_deps,
    vala_args: [
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'libwnck-3.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
    ],
    c_args: [
        '-DWNCK_I_KNOW_THIS_IS_UNSTABLE',
    ],
    install: true,
    install_dir: applet_workspaces_dir,
)

install_data(
    'com.solus-project.workspaces.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)
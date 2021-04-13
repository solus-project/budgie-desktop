# Provides budgie's main panel component

custom_target('desktop-file-panel',
    input : 'budgie-panel.desktop.in',
    output : 'budgie-panel.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'applications'))

gresource = join_paths(meson.current_source_dir(), 'budgie-panel.gresource.xml')

# Compile the assets into the binary
panel_resources = gnome.compile_resources(
    'budgie-panel-resources',
    gresource,
    source_dir: meson.current_source_dir(),
    c_name: 'budgie_panel',
)

panel_sources = [
    'main.vala',
    'manager.vala',
    'panel.vala',
    'uuid.vala',
    'settings/settings_applet_chooser.vala',
    'settings/settings_autostart.vala',
    'settings/settings_desktop.vala',
    'settings/settings_fonts.vala',
    'settings/settings_item.vala',
    'settings/settings_main.vala',
    'settings/settings_page.vala',
    'settings/settings_panel_applets.vala',
    'settings/settings_panel_dialogs.vala',
    'settings/settings_panel.vala',
    'settings/settings_raven.vala',
    'settings/settings_style.vala',
    'settings/settings_wm.vala',
    'settings/themes.vala',
    panel_resources,
]

panel_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    dep_libuuid,
    dep_wnck,
    link_libconfig,
    link_libsession,
    link_libbudgieprivate,
    link_libtheme,
    link_libplugin,
    link_libraven,
    gvc.get_variable('libgvc_dep'),
]

top_vapidir = join_paths(meson.source_root(), 'vapi')

budgie_panel_vala_args = [
        '--vapidir', dir_libtheme,
        '--vapidir', dir_libconfig,
        '--vapidir', top_vapidir,
        '--pkg', 'theme',
        '--pkg', 'budgie-config',
        '--pkg', 'gvc-1.0',
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gdk-x11-3.0',
        '--pkg', 'gio-unix-2.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
]

if dep_gsd.version().version_compare('>=40.0')
    budgie_panel_vala_args += ['-D', 'HAVE_GSD_40']
endif

budgie_panel_c_args = [
    '-DWNCK_I_KNOW_THIS_IS_UNSTABLE'
]

executable(
    'budgie-panel', panel_sources,
    dependencies: panel_deps,
    vala_args: budgie_panel_vala_args,
    c_args: budgie_panel_c_args,
    install: true,
)

executable(
    'budgie-desktop-settings',
    'budgie-desktop-settings.vala',
    dependencies: [
        dep_glib,
        dep_giounix,
    ],
    vala_args: [
        '--pkg', 'gio-unix-2.0',
    ],
    install: true,
    install_rpath: rpath_libdir,
)

# Now merge the translations of the .desktop.in to a .desktop
custom_target('desktop-file-settings',
    input : 'budgie-desktop-settings.desktop.in',
    output : 'budgie-desktop-settings.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'applications'),
)

# gschemas
install_data(
    'com.solus-project.budgie-panel.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

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
    'settings/settings_item.vala',
    'settings/settings_main.vala',
    'settings/settings_page.vala',
    'settings/settings_theme.vala',
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
    link_libtoplevel,
    link_libtheme,
    link_libplugin,
    link_libraven,
    gvc.get_variable('link_libgvc'),
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
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,
]

# For popdown/popup methods
if dep_gtk322.found()
    budgie_panel_vala_args += ['-D', 'HAVE_GTK_322']
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

# gschemas
install_data(
    'com.solus-project.budgie-panel.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

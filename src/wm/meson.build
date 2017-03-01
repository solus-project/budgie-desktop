custom_target('desktop-file-wm',
    input : 'budgie-wm.desktop.in',
    output : 'budgie-wm.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'applications'))


budgie_wm_sources = [
    'background.vala',
    'ibus.vala',
    'keyboard.vala',
    'main.vala',
    'shim.vala',
    'windowmenu.vala',
    'wm.vala',
]

dep_mutter = dependency('libmutter', version: gnome_minimum_version)

budgie_wm_deps = [
    link_libconfig,
    dep_mutter,
    dep_gnomedesktop,
    dep_gsettings,
    dep_ibus,
]

rpath = ''

if dep_mutter.version().version_compare('>=3.21.0')
    rpath = dep_mutter.get_pkgconfig_variable('typelibdir')
endif

executable(
    'budgie-wm', budgie_wm_sources,
    dependencies: budgie_wm_deps,
    include_directories: extra_includes,
    install: true,
    vala_args: [
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'ibus-1.0',
        '--pkg', 'gnome-desktop-3.0',
        '--pkg', 'libmutter',
        '--pkg', 'budgie-config',
        '--pkg', 'gsettings-desktop-schemas',
        '--vapidir', join_paths(meson.source_root(), 'vapi'),
        '--vapidir', dir_libconfig,
    ],
    c_args: [
        '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    ],
    install_rpath: rpath,
)

# gschemas
install_data(
    'com.solus-project.budgie.wm.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

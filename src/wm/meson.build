custom_target('desktop-file-wm',
    input : 'budgie-wm.desktop.in',
    output : 'budgie-wm.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'applications'))


budgie_wm_sources = [
    'core.c',
    'impl/destroy.c',
    'impl/map.c',
    'impl/menus.c',
    'impl/minimize.c',
    'impl/tiling.c',
    'impl/tile-widget.c',
    'impl/unminimize.c',
    'impl/workspaces.c',
    'main.c',
    'plugin.c',
]

dep_mutter = dependency('libmutter', version: gnome_minimum_version, required: false)

if not dep_mutter.found()
    dep_mutter = dependency('libmutter-0', version: gnome_minimum_version)
    message('Using new libmutter-0 ABI from GNOME 3.24')
endif

budgie_wm_deps = [
    dep_mutter,
]

rpath = ''

# Newer mutter uses rpath'd libraries..
if dep_mutter.version().version_compare('>=3.21.0')
    rpath = dep_mutter.get_pkgconfig_variable('typelibdir')
endif

executable(
    'budgie-wm', budgie_wm_sources,
    dependencies: budgie_wm_deps,
    include_directories: extra_includes,
    install: true,
    install_rpath: rpath,
)

# gschemas
install_data(
    'com.solus-project.budgie.wm.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

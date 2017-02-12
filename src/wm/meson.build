budgie_wm_sources = [
    'core.c',
    'impl/destroy.c',
    'impl/map.c',
    'impl/menus.c',
    'impl/minimize.c',
    'impl/tiling.c',
    'impl/unminimize.c',
    'impl/workspaces.c',
    'main.c',
    'plugin.c',
]

dep_mutter = dependency('libmutter', version: gnome_minimum_version)

budgie_wm_deps = [
    dep_mutter,
]

executable(
    'budgie-wm', budgie_wm_sources,
    dependencies: budgie_wm_deps,
    include_directories: extra_includes,
    install: true,
)

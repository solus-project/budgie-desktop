project(
    'gvc', 'c',
    version: '1.0',
    license: [
        'GPL-2.0',
    ],
    default_options: [
        'c_std=c89',
    ],
)

libgvc_deps = [
    dependency('libpulse', version: '>= 2.0'),
    dependency('libpulse-mainloop-glib', version: '>= 2.0'),
]

top_dir = meson.source_root()

libgvc_sources = [
    join_paths(top_dir, 'src/gvc/gvc-channel-map.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-card.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-control.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-event-role.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-sink.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-sink-input.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-source.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-source-output.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-stream.c'),
    join_paths(top_dir, 'src/gvc/gvc-mixer-ui-device.c'),
    join_paths(top_dir, 'src/gvc/test-audio-device-selection.c'),
]

libgvc = static_library(
    'gvc',
    libgvc_sources,
    dependencies: libgvc_deps,
    include_directories: [
        include_directories(meson.build_root()),
        include_directories(join_paths(top_dir, 'src', 'gvc')),
    ],
    c_args: [
        '-DG_LOG_DOMAIN="Gvc"',
        '-Wno-pedantic',
        '-Wno-unused-parameter',
        '-Wno-conversion',
        '-Wno-sign-compare',
    ],
)

link_libgvc = declare_dependency(
    link_with: libgvc,
    include_directories: [
        include_directories('.'),
        include_directories(join_paths(top_dir, 'src', 'gvc')),
    ],
)

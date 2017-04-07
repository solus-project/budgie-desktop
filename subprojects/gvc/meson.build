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

libgvc_sources = [
    '../../src/gvc/gvc-channel-map.c',
    '../../src/gvc/gvc-mixer-card.c',
    '../../src/gvc/gvc-mixer-control.c',
    '../../src/gvc/gvc-mixer-event-role.c',
    '../../src/gvc/gvc-mixer-sink.c',
    '../../src/gvc/gvc-mixer-sink-input.c',
    '../../src/gvc/gvc-mixer-source.c',
    '../../src/gvc/gvc-mixer-source-output.c',
    '../../src/gvc/gvc-mixer-stream.c',
    '../../src/gvc/gvc-mixer-ui-device.c',
    '../../src/gvc/test-audio-device-selection.c',
]

libgvc = static_library(
    'gvc',
    libgvc_sources,
    dependencies: libgvc_deps,
    include_directories: [
        include_directories('.'),
        include_directories(join_paths('..', '..')),
        include_directories(join_paths('..', '..', 'src', 'gvc')),
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
        include_directories(join_paths('..', '..')),
        include_directories(join_paths('..', '..', 'src', 'gvc')),
    ],
)

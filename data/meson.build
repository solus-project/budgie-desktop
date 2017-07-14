# This build ships the icon files for budgie desktop

actions_icons = [
    join_paths('.', 'icons', 'actions', 'notification-alert-symbolic.svg'),
    join_paths('.', 'icons', 'actions', 'pane-hide-symbolic.svg'),
    join_paths('.', 'icons', 'actions', 'pane-show-symbolic.svg'),
]

app_icons = [
    join_paths('.', 'icons', 'apps', 'budgie-desktop-symbolic.svg'),
    join_paths('.', 'icons', 'apps', 'system-tray-symbolic.svg'),
    join_paths('.', 'icons', 'apps', 'icon-task-list-symbolic.svg'),
    join_paths('.', 'icons', 'apps', 'spacer-symbolic.svg'),
    join_paths('.', 'icons', 'apps', 'clock-applet-symbolic.svg'),
    join_paths('.', 'icons', 'apps', 'workspace-switcher-symbolic.svg'),
    join_paths('.', 'icons', 'apps', 'notifications-applet-symbolic.svg'),
    join_paths('.', 'icons', 'apps', 'separator-symbolic.svg'),
    join_paths('.', 'icons', 'apps', 'task-list-symbolic.svg'),
]

status_icons = [
    join_paths('.', 'icons', 'status', 'num-lock-symbolic.svg'),
    join_paths('.', 'icons', 'status', 'caps-lock-symbolic.svg'),
]


install_data(
    actions_icons,
    install_dir: join_paths(datadir, 'icons', 'hicolor', 'scalable', 'actions'),
)

install_data(
    app_icons,
    install_dir: join_paths(datadir, 'icons', 'hicolor', 'scalable', 'apps'),
)

install_data(
    status_icons,
    install_dir: join_paths(datadir, 'icons', 'hicolor', 'scalable', 'status'),
)


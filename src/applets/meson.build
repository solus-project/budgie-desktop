# None of these applets depend on one another

applet_namespace = 'org.budgie-desktop.applet'
applets_dir = join_paths(plugin_libdir, applet_namespace)

subdir('budgie-menu')
subdir('clock')
subdir('caffeine')
subdir('icon-tasklist')
subdir('keyboard-layout')
subdir('lock-keys')

if dep_mutter.version().version_compare('>=3.24')
    subdir('night-light')
endif

subdir('notifications')
subdir('raven-trigger')
subdir('places-indicator')
subdir('separator')
subdir('show-desktop')
subdir('spacer')
subdir('status')
subdir('tasklist')
subdir('tray')
subdir('user-indicator')
subdir('workspaces')

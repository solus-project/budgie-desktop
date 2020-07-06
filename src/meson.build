# Control the order and relation between the subcomponents in Budgie

# Library components
subdir('plugin')
subdir('config')
subdir('libsession')

# Needed for daemon + applets
subdir('appsys')
subdir('abomination')

subdir('theme')
subdir('lib')
subdir('raven')

# Executable components
subdir('daemon')

if with_polkit == true
    subdir('polkit')
endif

subdir('rundialog')
subdir('wm')
subdir('panel')

# Now build applets
subdir('applets')

# Finish up by doing the session
subdir('session')

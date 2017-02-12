# Main session scripts

# We bash-quote already.
session_data = configuration_data()
session_data.set('PACKAGE_VERSION', meson.project_version())

# TODO: If GNOME version >= 3.24.0, use different components
gnome_session_components = [
    'gnome-settings-daemon',
]

# Always in Budgie
budgie_components = [
    'budgie-wm',
    'budgie-daemon',
    'budgie-panel',
    'budgie-polkit',
]

# Merge the list
session_components = gnome_session_components + budgie_components

# Set the session list
session_data.set('SESSION_COMPONENTS', ';'.join(session_components))
# Set the prefix
session_data.set('prefix', join_paths(get_option('prefix')))

# Write the budgie-desktop.session.in file from the .in.in
session_conf = configure_file(
    input: 'budgie-desktop.session.in.in',
    output: 'budgie-desktop.session.in',
    configuration: session_data,
)

# Now merge the translations of the .desktop.in to a .desktop
custom_target('desktop-file-session-main',
    input : session_conf,
    output : 'budgie-desktop.session',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'gnome-session', 'sessions'),
)

# Write /usr/bin/budgie-desktop script
configure_file(
    input: 'budgie-desktop.in',
    output: 'budgie-desktop',
    configuration: session_data,
    install_dir: join_paths(get_option('prefix'), get_option('bindir')),
)

# Configure the xsession file
xsession_conf = configure_file(
    input: 'budgie-desktop.desktop.in.in',
    output: 'budgie-desktop.desktop.in',
    configuration: session_data,
)

# Now merge the translations of the .desktop.in to a .desktop
custom_target('desktop-file-xsession',
    input : xsession_conf,
    output : 'budgie-desktop.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : join_paths(datadir, 'xsessions'),
)

# Solus only allows stateless XDG (/usr/share/xdg/autostart) in packaging
if get_option('enable-stateless') == true
    xdg_appdir = join_paths(datadir, 'xdg', 'autostart')
else
    xdg_appdir = join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
endif

# Merge + install nm-applet
custom_target('desktop-file-nm-applet',
    input : 'budgie-desktop-nm-applet.desktop.in',
    output : 'budgie-desktop-nm-applet.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : xdg_appdir,
)

# Merge + install screensaver
custom_target('desktop-file-screensaver',
    input : 'budgie-desktop-screensaver.desktop.in',
    output : 'budgie-desktop-screensaver.desktop',
    command : [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : xdg_appdir,
)

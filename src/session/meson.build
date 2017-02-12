# Main session scripts

# We bash-quote already.
session_data = configuration_data()
session_data.set('PACKAGE_VERSION', meson.project_version())

gnome_session_components = [
    'gnome-settings-daemon',
]

gnome_session_324_components = [
    'org.gnome.SettingsDaemon.A11yKeyboard',
    'org.gnome.SettingsDaemon.A11ySettings',
    'org.gnome.SettingsDaemon.Clipboard',
    'org.gnome.SettingsDaemon.Color',
    'org.gnome.SettingsDaemon.Datetime',
    'org.gnome.SettingsDaemon.Housekeeping',
    'org.gnome.SettingsDaemon.Keyboard',
    'org.gnome.SettingsDaemon.MediaKeys',
    'org.gnome.SettingsDaemon.Mouse',
    'org.gnome.SettingsDaemon.Orientation',
    'org.gnome.SettingsDaemon.Power',
    'org.gnome.SettingsDaemon.PrintNotifications',
    'org.gnome.SettingsDaemon.Rfkill',
    'org.gnome.SettingsDaemon.ScreensaverProxy',
    'org.gnome.SettingsDaemon.Sharing',
    'org.gnome.SettingsDaemon.Smartcard',
    'org.gnome.SettingsDaemon.Sound',
    'org.gnome.SettingsDaemon.Wacom',
    'org.gnome.SettingsDaemon.XRANDR',
    'org.gnome.SettingsDaemon.XSettings',
]

# Always in Budgie
budgie_components = [
    'budgie-wm',
    'budgie-daemon',
    'budgie-panel',
]

if with_polkit == true
    budgie_components += 'budgie-polkit'
endif

# Merge the list depending on the GNOME version. We pick mutter arbitrarily.
if dep_mutter.version().version_compare('>=3.23.3')
    session_components = budgie_components + gnome_session_324_components
else
    session_components = gnome_session_components + budgie_components
endif

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
if get_option('with-stateless') == true
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

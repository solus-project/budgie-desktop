namespace GDesktop
{

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_PROXY_")]
    public enum ProxyMode
    {
            NONE,
            MANUAL,
            AUTO
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_TOOLBAR_")]
    public enum ToolbarStyle
    {
            BOTH,
            BOTH_HORIZ,
            ICONS,
            TEXT
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_TOOLBAR_ICON_SIZE_")]
    public enum ToolbarIconSize
    {
            SMALL,
            LARGE
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_BACKGROUND_STYLE_")]
    public enum BackgroundStyle
    {
            NONE,
            WALLPAPER,
            CENTERED,
            SCALED,
            STRETCHED,
            ZOOM,
            SPANNED
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_BACKGROUND_SHADING_")]
    public enum BackgroundShading
    {
            SOLID,
            VERTICAL,
            HORIZONTAL
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_MOUSE_DWELL_MODE_")]
    public enum MouseDwellMode
    {
            WINDOW,
            GESTURE
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_MOUSE_DWELL_DIRECTION_")]
    public enum MouseDwellDirection
    {
            LEFT,
            RIGHT,
            UP,
            DOWN
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_CLOCK_FORMAT_")]
    public enum ClockFormat
    {
            24H,
            12H
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_SCREENSAVER_MODE_")]
    public enum ScreensaverMode
    {
            BLANK_ONLY,
            RANDOM,
            SINGLE
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_MAGNIFIER_MOUSE_TRACKING_MODE_")]
    public enum MagnifierMouseTrackingMode
    {
            NONE,
            CENTERED,
            PROPORTIONAL,
            PUSH
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_MAGNIFIER_FOCUS_TRACKING_MODE_")]
    public enum MagnifierFocusTrackingMode
    {
            NONE,
            CENTERED,
            PROPORTIONAL,
            PUSH
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_MAGNIFIER_CARET_TRACKING_MODE_")]
    public enum MagnifierCaretTrackingMode
    {
            NONE,
            CENTERED,
            PROPORTIONAL,
            PUSH
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_MAGNIFIER_SCREEN_POSITION_")]
    public enum MagnifierScreenPosition
    {
            NONE,
            FULL_SCREEN,
            TOP_HALF,
            BOTTOM_HALF,
            LEFT_HALF,
            RIGHT_HALF,
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_TITLEBAR_ACTION_")]
    public enum TitlebarAction
    {
            TOGGLE_SHADE,
            TOGGLE_MAXIMIZE,
            TOGGLE_MAXIMIZE_HORIZONTALLY,
            TOGGLE_MAXIMIZE_VERTICALLY,
            MINIMIZE,
            NONE,
            LOWER,
            MENU,
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_FOCUS_MODE_")]
    public enum FocusMode
    {
            CLICK,
            SLOPPY,
            MOUSE,
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_FOCUS_NEW_WINDOWS_")]
    public enum FocusNewWindows
    {
            SMART,
            STRICT,
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_VISUAL_BELL_")]
    public enum VisualBellType
    {
            FULLSCREEN_FLASH,
            FRAME_FLASH,
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_LOCATION_ACCURACY_LEVEL_")]
    public enum LocationAccuracyLevel
    {
            COUNTRY,
            CITY,
            NEIGHBORHOOD,
            STREET,
            EXACT
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_TOUCHPAD_SCROLL_METHOD_")]
    public enum TouchpadScrollMethod
    {
            DISABLED,
            EDGE_SCROLLING,
            TWO_FINGER_SCROLLING
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_TOUCHPAD_HANDEDNESS_")]
    public enum TouchpadHandedness
    {
            RIGHT,
            LEFT,
            MOUSE
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_TOUCHPAD_CLICK_METHOD_")]
    public enum TouchpadClickMethod
    {
            DEFAULT,
            NONE,
            AREAS,
            FINGERS
    }

    [CCode (cheader_filename = "gsettings-desktop-schemas/gdesktop-enums.h", cprefix = "G_DESKTOP_DEVICE_SEND_EVENTS_")]
    public enum DeviceSendEvents
    {
            ENABLED,
            DISABLED,
            DISABLED_ON_EXTERNAL_MOUSE
    }
}

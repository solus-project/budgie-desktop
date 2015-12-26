/* Injects compile time defines into BudgiePanel.vala */

namespace Budgie {
    [CCode (cheader_filename = "panelconfig.h")]
    public static extern const string MODULE_DIRECTORY;

    [CCode (cheader_filename = "panelconfig.h")]
    public static extern const string MODULE_DATA_DIRECTORY;

    [CCode (cheader_filename = "panelconfig.h")]
    public static extern const string DATADIR;

    [CCode (cheader_filename = "panelconfig.h")]
    public static extern const string VERSION;

    [CCode (cheader_filename = "panelconfig.h")]
    public static extern const string WEBSITE;

    [CCode (cheader_filename = "panelconfig.h")]
    public static extern const string GETTEXT_PACKAGE;

    [CCode (cheader_filename = "panelconfig.h")]
    public static extern const string LOCALEDIR;
    
}

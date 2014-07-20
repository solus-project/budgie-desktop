/* Injects compile time defines into BudgiePanel.vala */

namespace Budgie {
	[CCode (cheader_filename = "panelconfig.h")]
    public extern const string MODULE_DIRECTORY;

	[CCode (cheader_filename = "panelconfig.h")]
    public extern const string MODULE_DATA_DIRECTORY;
}

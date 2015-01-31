/* Injects compile time defines into BudgieSession.vala */

namespace Budgie {
	[CCode (cheader_filename = "sessionconfig.h")]
    public extern const string GNOME_XDG_DIR;
}

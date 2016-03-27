Panel
-----
 * [ ] Steal some PopoverManager changes from the wingpanel guys back into Budgie Panel
 * [ ] Steal the focus-manager trick from Wingpanel too (Nice work guys!)
 * [x] Fix startup issues:
    * [x] Only expose when startup is complete
    * [x] Reveal the Panel using an animation (cairo+buffer offset)
    * [x] Disable automatic sorting until the panel is fully loaded, and then go
      back and sort them all to fix weird placement issues
 * [ ] Use an animation to reveal new applets, looks fugly just BAM there's a new applet.
 * [ ] Add garbage collection for unloaded modules
 * [ ] Approved "new" applets needed:
   * [ ] Screencast indicator for integration with WM (Status Applet?)
   * [ ] Keyboard layout indicator
 * [ ] Add pinning capabilities to the Budgie Menu itself
 * [x] Disallow Ugly Apps from overriding the icon (main chrome instance, hexchat, etc)
 * [ ] Turn Power Icon into a user menu (Hibernate, Switch User, etc)
 * [ ] Ensure all popover-associated applets use this as  the *primary* action, no
       more right-click left-click nonsense. Left click only.
 * [ ] Just because it's at the end of the panel, doesn't mean it needs to launch
       feckin Raven. Notification icon + sound are sufficient.
 * [ ] Add intellihide.
 * [ ] More popovers.
 * [ ] Add workaround for clicking on the desktop to allow dismissing of Raven
       for when Nautilus isn't being used..

 ![Popovers Everywhere](http://cdn.meme.am/instances/500x/63501402.jpg)
 
Raven
------
 * [ ] Add proper Raven API for applets (single instance, unlike Budgie Panel)
 * [ ] Enforce constant sizes
 * [ ] Enhance discoverability. People seem to not know that it exists ....
 * [ ] Actually add some applets:
   * [ ] "System Monitor"
   * [ ] Ticker?
 * [ ] It might be GTK but make these things more alive!!
 * [x] Add all relevant options to allow deprecation of gnome-tweak-tool usage by us.
 * [ ] Fix notifications (Yes you Spotify..)
   - Probably sign up with Spotify too. Sure as shit beats using YouTube all the time.
 * [ ] Clean up the UI.

Window Manager
---------------
 * [ ] Fix derpy-ass alt+tab
 * [ ] Add proper ibus support
 * [ ] Add screen recording and screenshot support (see GNOME Shell)
 * [ ] Low Priority: "Blur Behind" effect based on wm_class
 * [ ] Extend the d-bus API so that the Panel and Raven are positioned by us for future
   Wayland work (Also require an accessible strut mechanism from the compositor.
   Sync with elementary + Jasper St Pierre over this) [Low Priority]


General
-------

 * [ ] Make it suck less.
 * [ ] Need a sexy LightDM greeter.
 * [ ] Take over the world.
 * Focus on X11 for now, even thinking about Wayland atm will make my head asplode.

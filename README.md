# Orion Compact Tabs
My Technical Task for Orion. Supports macOS 10.14 and above, developed on macOS 12.5. Built to be a mimick of Safari's Compact Tabs, using Orion's concept at https://orionfeedback.org/d/92-compact-tabs/82.

## Unique Additions
1. **Zoom out to expand tab temporarily**. A large pain of compact tabs is that it gets harder to identify tabs, especially when they have similar favicons and are in their compact favicon-only mode. My solution was to allow the user to expand the width of a tab temporarily (eg. to see the tab title) by means of a zoom gesture, which is an intuitive way to reveal the tab's title.
2. **Double click on tab or click on currently active tab to focus address field**. Reading through the Orion Feedback thread, I saw a few comments saying how clicking on a tab and then clicking the address bar is a bit troublesome in Orion's concept (click on tab -> move cursor -> click on address bar), wheras its a lot simpler in Safari's (click on tab -> click on tab again to focus in-tab address bar). I made it so that clicking on the active tab focuses the address bar, so that one can simply double click on a tab to switch to it and focus the URL bar. 

## How it works + Interesting things to note
### Architecture:
- `MainWindowController`: Serves as the master for the window, and interfaces between the appdelegate, the `CompactTabsToolbarView`, and the `ViewController`.
  - `CompactTabsToolbarView`: The view for the compact tabs toolbar item. This manages the compact tabs UI, each of which is in a `TabView`.
    - `TabView`: The view responsible for a single tab, including favicon, title, closing (via the X button), zooming, moving, and focusing the tab.
  - `ViewController`: The view responsible for containing all the web views, each in a `WebPageView`. Responsible for creating and deleting tabs, plus being a middleman for other commands like refresh, back and forward to ensure the commands go to the right page.
  	- `WebPageView`: A single web page, which notifies the `ViewController` when it has succeeded or failed to navigate to a new page.

### Making the toolbar item fill up the available space
When the window is created and when it resizes, a piece of code adds together the total maximum width of all other toolbar items (excluding flexible spaces), then uses that and sets the new width of the compact tabs toolbar item. Currently, toolbar customisation does not work because it somehow messes with this function.

### Favicons and Tab Titles
I use a Google API to get the favicon for each tab. Its not the best, because its google, but for the purposes of getting a favicon it works. Favicons are cached to avoid excessively requesting them every time a change happens to a tab. I use the webkit view's `title` value to get the current tab title. These are both refreshed when the tab navigates to a new page or when the refresh button is pressed.

### Compact Tabs + Resizing + Animations
The compact tabs toolbar item does two things when it is setting up or refreshing tabs:
- It creates and marks tabs for deletion so that the compact tab toolbar item's tab index is up to date with the ViewController's
- The frames of the toolbar item are updated to their new positions and sizes, with or without animations, depending on if its triggered by a window resize or a change in the tab system.
- If a tab was created, the scroll view is scrolled to reveal the new tab.
- If a tab was marked as deleted, it is removed from the view and the index after its closing animation finished
Due to the way the code was made, tab creation/deletion should be spam proof. I've tested it with excessively spamming cmd-t, cmd-w, and both at the same time.

### Switching Tabs
The compact tabs have a click gesture recogniser that tells the ViewController to focus that tab. The ViewController then removes the previous tab from its view, adds the new tab to the view, and sends a message to the compact tab toolbar item to refresh tabs.

### Zoom out to expand tab temporarily
Each tab has a magnify gesture recogniser. When it is trigerred, the tab view expands by the `magnification` amount, and reverting to its normal width when the gesture ends. This allows the user to reveal a tab's title in an intuitive way.

### Tab Reordering
Each tab has a drage gesture recogniser. When it is trigerred, the tab's frame moves along with the mouse's current location. If the center of the moving tab enters the left half of another tab's frame, it then moves to the left of that tab, and vice versa. The view controller's tabs are also updated to reflect the new tab order at the end of the gesture.

## Difficulties
- No SF Symbols due to version requirement (instead I just added the sf images to assets)

## Potential Bugs
- Due to how the compact tab bar works, currently toolbar customisation does not work. However, you can add/remove dummy extension items in the toolbar delegate to mimick how it would be like when the user has extensions.
- The tab scrollview acts very oddly in fullscreen. The background somehow has a different colour, even though the background is set to clear.  

## Rough Order of Development
1. Add web view
2. Add back/forward buttons
3. Add URL Bar
4. Add tabbing + temporary buttons to switch left/right a tab
5. Allow URL Bar to automatically resize to fill the space
6. Design tabs
7. Implement tabs view (dummy favicon + dummy titles)
8. Implement clicking to switch tabs
9. On web view refresh, update tabs titles (no favicon yet)
10. Implement shrinking of non-main tabs if not enough space
11. Implement hiding of tab title, center aligning favicon if the tab is smaller than a certain width
12. Implement scrolling of tab bar if non-main tabs are minimum width but theres still not enough space
13. Allow all tabs (both selected and non-selected) to expand in width if theres excess space
14. Allow closing of tabs
15. Allow middle click to close tab
16. Implement favicons
17. Implement animations for when tabs go from no title to with title
18. Implement animations for when tabs resize (eg. when main tab changed, tab added or removed)
19. Re-architecture and clean up code
20. Center the URL bar when no tabs are open
21. Fix crashes related to doing certain actions when animations are playing
22. Added the ability to use a zoom out trackpad gesture to expand the width of a tab temporarily
23. Added the ability to reorder tabs

## Todo:
- Re-enable Toolbar Customisation

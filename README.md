# Orion Compact Tabs
My Technical Task for Orion

## Unique Additions
1. Zoom out to expand tab temporarily. A large pain of compact tabs is that it gets harder to identify tabs, especially when they have similar favicons and are in their compact favicon-only mode. My solution was to allow the user to expand the width of a tab temporarily (eg. to see the tab title) by means of a zoom gesture, which is an intuitive way to reveal the tab's title.
2. Double click on tab or click on currently active tab to focus address field. Reading through the Orion Feedback thread, I saw a few comments saying how clicking on a tab and then clicking the address bar is a bit troublesome in Orion's concept (click on tab -> move cursor -> click on address bar), wheras its a lot simpler in Safari's (click on tab -> click on tab again to focus in-tab address bar). I made it so that clicking on the active tab focuses the address bar, so that one can simply double click on a tab to switch to it and focus the URL bar. 

## How it works + Interesting things to note
### Making the toolbar item fill up the available space
### Changing the URL
### Favicons and Tab Titles
### Tabs + Resizing + Animations
### Switching Tabs
### Closing/opening new tabs
### Zoom out to expand tab temporarily
### Tab Reordering

## Difficulties
- No SF Symbols due to version requirement (instead I just added the sf images to assets)

## Potential Bugs
- Due to "hard coding" the SF Symbols in the toolbar, light mode does not work
- Due to how the compact tab bar works, currently toolbar customisation does not work.

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
- Tab reordering
- Re-enable Toolbar Customisation

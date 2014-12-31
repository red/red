State of implementation of the new console sub-system
------------------------

The main goal of the new console implementation is to get rid of libreadline and libhistory dependencies, because 32-bit versions are not built-in 64-bit systems. This is problematic when trying to run the console the first time. In addition to that, we need:

- simple way to catch TAB key to enable Red-specific completion and have full-control over it.
- provide real-time help while the user is typing
- control of history at Red level (and not have it black-boxed).

In order to achieve that, we need to support:

* basic line-oriented editing features

* multi-line editing support

* catching UP/DOWN arrow keys for history control

* catching TAB key

We want to have a cross-platform core console engine that could be used to implement a Red console on any system, in text-oriented or graphic windows.

The first prototype implements the INPUT native for Unix platforms using only vt100 escape sequences. The prototype is almost completed, but still need to address:

* double-width characters support using a custom implementation of wcwidth().

* address some multi-line bugs

* implement a Windows console version

* isolate the cross-platform parts

Later, once the port/device model will be available, the code needs to be refactored as a _device_.

Note: we could use ncurses for achieving these goals faster, but the poor integration of ncurses with the display scroll buffer has been critized by many Rebol2 user (including myself), so we are aiming at a better solution. That said, a ncurses version will be added too at some point in order to provide a more sophisticated console (having some realtime information at the top of the display for example).
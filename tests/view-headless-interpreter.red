Red [
	Title:   "Headless test-backend interpreter for the View/VID test suite"
	File: 	 %view-headless-interpreter.red
	Author:  "Red test suite"
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Needs:	 View
	Config:	 [GUI-engine: 'test]
	Purpose: {
		Builds a tiny standalone interpreter that runs Red/View scripts on the
		headless `test` GUI backend. It lets the View/VID unit tests be *run by
		interpretation* with the exact same deterministic geometry they get when
		compiled with Config: [GUI-engine: 'test] -- no per-test compilation and
		no display required.

		This complements %run-view-headless-tests.r (which compiles each test):
		compile this interpreter ONCE, then interpret the whole suite in seconds.

		Build it (run from the repo root). -r is essential: the encapped
		compiler otherwise links a prebuilt libRedRT built with the *native* GUI
		backend, which is incompatible with the `test` backend. Swap the -t
		target per host (MSDOS = Windows console, Darwin = macOS, Linux = else):

			rebpro.exe -qws red.r -r -t MSDOS -o red-t.exe tests/view-headless-interpreter.red

		Run a single test (interpreted, headless):

			red-t.exe tests/source/view/vid-styles-test.red

		Run the whole suite + tally failures:

			bash:        for f in tests/source/view/*-test.red; do red-t.exe "$f"; done
			PowerShell:  Get-ChildItem tests/source/view/*-test.red | % { & ./red-t.exe $_.FullName }

		`do` on a file auto-expands #include / #macro (see do-file in
		%environment/functions.red), so quick-test.red's macros work when the
		test files are interpreted rather than compiled.
	}
]

args: system/options/args
do to-file either block? args [first args][args]

Red [needs: CLI]

#include  %../../../quick-test/quick-test.red

do find any [
	attempt [load %cli-test.red]
	attempt [load %source/cli/cli-test.red]
] [~~~start-file~~~]

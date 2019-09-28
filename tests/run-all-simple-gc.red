Red []

do %../quick-test/quick-test.red
--test--: func spec-of :--test-- append body-of :--test-- 'recycle

all-tests: read/lines %source/units/all-tests.txt

foreach test all-tests [
	do clean-path append copy %source/units/ test	
]

do %source/units/auto-tests/run-all-comp1.red
do %source/units/auto-tests/run-all-comp2.red
do %source/units/auto-tests/run-all-interp.red


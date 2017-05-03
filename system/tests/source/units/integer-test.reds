Red/System [
	Title:		"Red/System integer test script"
	Author:		"Peter W A Wood"
	File:			%integer-test.reds
	Tabs:			4
	Rights:		"Copyright (C) 2011-2016 Nenad Rakocevic, Peter W A Wood. All rights reserved."
	License:	"BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "integer"

===start-group=== "integer-add"

	--test-- "integer-add1"
		--assert -1 + -1 = -2
		i: -1
		j: -1
		--assert i + j = -2
	--test-- "integer-add2"
		--assert -1 + 0 = -1
		i: -1
		j: 0
		--assert i + j = -1
	--test-- "integer-add3"
		--assert -1 + 1 = 0
		i: -1
		j: 1
		--assert i + j = 0
	--test-- "integer-add4"
		--assert -1 + 255 = 254
		i: -1
		j: 255
		--assert i + j = 254
	--test-- "integer-add5"
		--assert -1 + 256 = 255
		i: -1
		j: 256
		--assert i + j = 255
	--test-- "integer-add6"
		--assert -1 + 65535 = 65534
		i: -1
		j: 65535
		--assert i + j = 65534
	--test-- "integer-add7"
		--assert -1 + 65536 = 65535
		i: -1
		j: 65536
		--assert i + j = 65535
	--test-- "integer-add8"
		--assert -1 + 2147483647 = 2147483646
		i: -1
		j: 2147483647
		--assert i + j = 2147483646
	--test-- "integer-add9"
		--assert -1 + -2147483647 = -2147483648
		i: -1
		j: -2147483647
		--assert i + j = -2147483648
	--test-- "integer-add10"
		--assert -1 + -2147483648 = 2147483647
		i: -1
		j: -2147483648
		--assert i + j = 2147483647
	--test-- "integer-add11"
		--assert 0 + 0 = 0
		i: 0
		j: 0
		--assert i + j = 0
	--test-- "integer-add12"
		--assert 0 + 1 = 1
		i: 0
		j: 1
		--assert i + j = 1
	--test-- "integer-add13"
		--assert 0 + 255 = 255
		i: 0
		j: 255
		--assert i + j = 255
	--test-- "integer-add14"
		--assert 0 + 256 = 256
		i: 0
		j: 256
		--assert i + j = 256
	--test-- "integer-add15"
		--assert 0 + 65535 = 65535
		i: 0
		j: 65535
		--assert i + j = 65535
	--test-- "integer-add16"
		--assert 0 + 65536 = 65536
		i: 0
		j: 65536
		--assert i + j = 65536
	--test-- "integer-add17"
		--assert 0 + 2147483647 = 2147483647
		i: 0
		j: 2147483647
		--assert i + j = 2147483647
	--test-- "integer-add18"
		--assert 0 + -2147483647 = -2147483647
		i: 0
		j: -2147483647
		--assert i + j = -2147483647
	--test-- "integer-add19"
		--assert 0 + -2147483648 = -2147483648
		i: 0
		j: -2147483648
		--assert i + j = -2147483648
	--test-- "integer-add20"
		--assert 1 + 1 = 2
		i: 1
		j: 1
		--assert i + j = 2
	--test-- "integer-add21"
		--assert 1 + 255 = 256
		i: 1
		j: 255
		--assert i + j = 256
	--test-- "integer-add22"
		--assert 1 + 256 = 257
		i: 1
		j: 256
		--assert i + j = 257
	--test-- "integer-add23"
		--assert 1 + 65535 = 65536
		i: 1
		j: 65535
		--assert i + j = 65536
	--test-- "integer-add24"
		--assert 1 + 65536 = 65537
		i: 1
		j: 65536
		--assert i + j = 65537
	--test-- "integer-add25"
		--assert 1 + 2147483647 = -2147483648
		i: 1
		j: 2147483647
		--assert i + j = -2147483648
	--test-- "integer-add26"
		--assert 1 + -2147483647 = -2147483646
		i: 1
		j: -2147483647
		--assert i + j = -2147483646
	--test-- "integer-add27"
		--assert 1 + -2147483648 = -2147483647
		i: 1
		j: -2147483648
		--assert i + j = -2147483647
	--test-- "integer-add28"
		--assert 255 + 255 = 510
		i: 255
		j: 255
		--assert i + j = 510
	--test-- "integer-add29"
		--assert 255 + 256 = 511
		i: 255
		j: 256
		--assert i + j = 511
	--test-- "integer-add30"
		--assert 255 + 65535 = 65790
		i: 255
		j: 65535
		--assert i + j = 65790
	--test-- "integer-add31"
		--assert 255 + 65536 = 65791
		i: 255
		j: 65536
		--assert i + j = 65791
	--test-- "integer-add32"
		--assert 255 + 2147483647 = -2147483394
		i: 255
		j: 2147483647
		--assert i + j = -2147483394
	--test-- "integer-add33"
		--assert 255 + -2147483647 = -2147483392
		i: 255
		j: -2147483647
		--assert i + j = -2147483392
	--test-- "integer-add34"
		--assert 255 + -2147483648 = -2147483393
		i: 255
		j: -2147483648
		--assert i + j = -2147483393
	--test-- "integer-add35"
		--assert 256 + 256 = 512
		i: 256
		j: 256
		--assert i + j = 512
	--test-- "integer-add36"
		--assert 256 + 65535 = 65791
		i: 256
		j: 65535
		--assert i + j = 65791
	--test-- "integer-add37"
		--assert 256 + 65536 = 65792
		i: 256
		j: 65536
		--assert i + j = 65792
	--test-- "integer-add38"
		--assert 256 + 2147483647 = -2147483393
		i: 256
		j: 2147483647
		--assert i + j = -2147483393
	--test-- "integer-add39"
		--assert 256 + -2147483647 = -2147483391
		i: 256
		j: -2147483647
		--assert i + j = -2147483391
	--test-- "integer-add40"
		--assert 256 + -2147483648 = -2147483392
		i: 256
		j: -2147483648
		--assert i + j = -2147483392
	--test-- "integer-add41"
		--assert 65535 + 65535 = 131070
		i: 65535
		j: 65535
		--assert i + j = 131070
	--test-- "integer-add42"
		--assert 65535 + 65536 = 131071
		i: 65535
		j: 65536
		--assert i + j = 131071
	--test-- "integer-add43"
		--assert 65535 + 2147483647 = -2147418114
		i: 65535
		j: 2147483647
		--assert i + j = -2147418114
	--test-- "integer-add44"
		--assert 65535 + -2147483647 = -2147418112
		i: 65535
		j: -2147483647
		--assert i + j = -2147418112
	--test-- "integer-add45"
		--assert 65535 + -2147483648 = -2147418113
		i: 65535
		j: -2147483648
		--assert i + j = -2147418113
	--test-- "integer-add46"
		--assert 65536 + 65536 = 131072
		i: 65536
		j: 65536
		--assert i + j = 131072
	--test-- "integer-add47"
		--assert 65536 + 2147483647 = -2147418113
		i: 65536
		j: 2147483647
		--assert i + j = -2147418113
	--test-- "integer-add48"
		--assert 65536 + -2147483647 = -2147418111
		i: 65536
		j: -2147483647
		--assert i + j = -2147418111
	--test-- "integer-add49"
		--assert 65536 + -2147483648 = -2147418112
		i: 65536
		j: -2147483648
		--assert i + j = -2147418112
	--test-- "integer-add50"
		--assert 2147483647 + 2147483647 = -2
		i: 2147483647
		j: 2147483647
		--assert i + j = -2
	--test-- "integer-add51"
		--assert 2147483647 + -2147483647 = 0
		i: 2147483647
		j: -2147483647
		--assert i + j = 0
	--test-- "integer-add52"
		--assert 2147483647 + -2147483648 = -1
		i: 2147483647
		j: -2147483648
		--assert i + j = -1
	--test-- "integer-add53"
		--assert -2147483647 + -2147483647 = 2
		i: -2147483647
		j: -2147483647
		--assert i + j = 2
	--test-- "integer-add54"
		--assert -2147483647 + -2147483648 = 1
		i: -2147483647
		j: -2147483648
		--assert i + j = 1
	--test-- "integer-add55"
		--assert -2147483648 + -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i + j = 0
	--test-- "integer-add56"
		--assert -1 + -1 = -2
		i: -1
		j: -1
		--assert i + j = -2
	--test-- "integer-add57"
		--assert 0 + 0 = 0
		i: 0
		j: 0
		--assert i + j = 0
	--test-- "integer-add58"
		--assert 1 + 1 = 2
		i: 1
		j: 1
		--assert i + j = 2
	--test-- "integer-add59"
		--assert 255 + 255 = 510
		i: 255
		j: 255
		--assert i + j = 510
	--test-- "integer-add60"
		--assert 256 + 256 = 512
		i: 256
		j: 256
		--assert i + j = 512
	--test-- "integer-add61"
		--assert 65535 + 65535 = 131070
		i: 65535
		j: 65535
		--assert i + j = 131070
	--test-- "integer-add62"
		--assert 65536 + 65536 = 131072
		i: 65536
		j: 65536
		--assert i + j = 131072
	--test-- "integer-add63"
		--assert 2147483647 + 2147483647 = -2
		i: 2147483647
		j: 2147483647
		--assert i + j = -2
	--test-- "integer-add64"
		--assert -2147483647 + -2147483647 = 2
		i: -2147483647
		j: -2147483647
		--assert i + j = 2
	--test-- "integer-add65"
		--assert -2147483648 + -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i + j = 0

===end-group===

===start-group=== "integer-subtract"

	--test-- "integer-subtract1"
		--assert -1 - -1 = 0
		i: -1
		j: -1
		--assert i - j = 0
	--test-- "integer-subtract2"
		--assert -1 - 0 = -1
		i: -1
		j: 0
		--assert i - j = -1
	--test-- "integer-subtract3"
		--assert -1 - 1 = -2
		i: -1
		j: 1
		--assert i - j = -2
	--test-- "integer-subtract4"
		--assert -1 - 255 = -256
		i: -1
		j: 255
		--assert i - j = -256
	--test-- "integer-subtract5"
		--assert -1 - 256 = -257
		i: -1
		j: 256
		--assert i - j = -257
	--test-- "integer-subtract6"
		--assert -1 - 65535 = -65536
		i: -1
		j: 65535
		--assert i - j = -65536
	--test-- "integer-subtract7"
		--assert -1 - 65536 = -65537
		i: -1
		j: 65536
		--assert i - j = -65537
	--test-- "integer-subtract8"
		--assert -1 - 2147483647 = -2147483648
		i: -1
		j: 2147483647
		--assert i - j = -2147483648
	--test-- "integer-subtract9"
		--assert -1 - -2147483647 = 2147483646
		i: -1
		j: -2147483647
		--assert i - j = 2147483646
	--test-- "integer-subtract10"
		--assert -1 - -2147483648 = 2147483647
		i: -1
		j: -2147483648
		--assert i - j = 2147483647
	--test-- "integer-subtract11"
		--assert 0 - -1 = 1
		i: 0
		j: -1
		--assert i - j = 1
	--test-- "integer-subtract12"
		--assert 0 - 0 = 0
		i: 0
		j: 0
		--assert i - j = 0
	--test-- "integer-subtract13"
		--assert 0 - 1 = -1
		i: 0
		j: 1
		--assert i - j = -1
	--test-- "integer-subtract14"
		--assert 0 - 255 = -255
		i: 0
		j: 255
		--assert i - j = -255
	--test-- "integer-subtract15"
		--assert 0 - 256 = -256
		i: 0
		j: 256
		--assert i - j = -256
	--test-- "integer-subtract16"
		--assert 0 - 65535 = -65535
		i: 0
		j: 65535
		--assert i - j = -65535
	--test-- "integer-subtract17"
		--assert 0 - 65536 = -65536
		i: 0
		j: 65536
		--assert i - j = -65536
	--test-- "integer-subtract18"
		--assert 0 - 2147483647 = -2147483647
		i: 0
		j: 2147483647
		--assert i - j = -2147483647
	--test-- "integer-subtract19"
		--assert 0 - -2147483647 = 2147483647
		i: 0
		j: -2147483647
		--assert i - j = 2147483647
	--test-- "integer-subtract20"
		--assert 0 - -2147483648 = -2147483648
		i: 0
		j: -2147483648
		--assert i - j = -2147483648
	--test-- "integer-subtract21"
		--assert 1 - -1 = 2
		i: 1
		j: -1
		--assert i - j = 2
	--test-- "integer-subtract22"
		--assert 1 - 0 = 1
		i: 1
		j: 0
		--assert i - j = 1
	--test-- "integer-subtract23"
		--assert 1 - 1 = 0
		i: 1
		j: 1
		--assert i - j = 0
	--test-- "integer-subtract24"
		--assert 1 - 255 = -254
		i: 1
		j: 255
		--assert i - j = -254
	--test-- "integer-subtract25"
		--assert 1 - 256 = -255
		i: 1
		j: 256
		--assert i - j = -255
	--test-- "integer-subtract26"
		--assert 1 - 65535 = -65534
		i: 1
		j: 65535
		--assert i - j = -65534
	--test-- "integer-subtract27"
		--assert 1 - 65536 = -65535
		i: 1
		j: 65536
		--assert i - j = -65535
	--test-- "integer-subtract28"
		--assert 1 - 2147483647 = -2147483646
		i: 1
		j: 2147483647
		--assert i - j = -2147483646
	--test-- "integer-subtract29"
		--assert 1 - -2147483647 = -2147483648
		i: 1
		j: -2147483647
		--assert i - j = -2147483648
	--test-- "integer-subtract30"
		--assert 1 - -2147483648 = -2147483647
		i: 1
		j: -2147483648
		--assert i - j = -2147483647
	--test-- "integer-subtract31"
		--assert 255 - -1 = 256
		i: 255
		j: -1
		--assert i - j = 256
	--test-- "integer-subtract32"
		--assert 255 - 0 = 255
		i: 255
		j: 0
		--assert i - j = 255
	--test-- "integer-subtract33"
		--assert 255 - 1 = 254
		i: 255
		j: 1
		--assert i - j = 254
	--test-- "integer-subtract34"
		--assert 255 - 255 = 0
		i: 255
		j: 255
		--assert i - j = 0
	--test-- "integer-subtract35"
		--assert 255 - 256 = -1
		i: 255
		j: 256
		--assert i - j = -1
	--test-- "integer-subtract36"
		--assert 255 - 65535 = -65280
		i: 255
		j: 65535
		--assert i - j = -65280
	--test-- "integer-subtract37"
		--assert 255 - 65536 = -65281
		i: 255
		j: 65536
		--assert i - j = -65281
	--test-- "integer-subtract38"
		--assert 255 - 2147483647 = -2147483392
		i: 255
		j: 2147483647
		--assert i - j = -2147483392
	--test-- "integer-subtract39"
		--assert 255 - -2147483647 = -2147483394
		i: 255
		j: -2147483647
		--assert i - j = -2147483394
	--test-- "integer-subtract40"
		--assert 255 - -2147483648 = -2147483393
		i: 255
		j: -2147483648
		--assert i - j = -2147483393
	--test-- "integer-subtract41"
		--assert 256 - -1 = 257
		i: 256
		j: -1
		--assert i - j = 257
	--test-- "integer-subtract42"
		--assert 256 - 0 = 256
		i: 256
		j: 0
		--assert i - j = 256
	--test-- "integer-subtract43"
		--assert 256 - 1 = 255
		i: 256
		j: 1
		--assert i - j = 255
	--test-- "integer-subtract44"
		--assert 256 - 255 = 1
		i: 256
		j: 255
		--assert i - j = 1
	--test-- "integer-subtract45"
		--assert 256 - 256 = 0
		i: 256
		j: 256
		--assert i - j = 0
	--test-- "integer-subtract46"
		--assert 256 - 65535 = -65279
		i: 256
		j: 65535
		--assert i - j = -65279
	--test-- "integer-subtract47"
		--assert 256 - 65536 = -65280
		i: 256
		j: 65536
		--assert i - j = -65280
	--test-- "integer-subtract48"
		--assert 256 - 2147483647 = -2147483391
		i: 256
		j: 2147483647
		--assert i - j = -2147483391
	--test-- "integer-subtract49"
		--assert 256 - -2147483647 = -2147483393
		i: 256
		j: -2147483647
		--assert i - j = -2147483393
	--test-- "integer-subtract50"
		--assert 256 - -2147483648 = -2147483392
		i: 256
		j: -2147483648
		--assert i - j = -2147483392
	--test-- "integer-subtract51"
		--assert 65535 - -1 = 65536
		i: 65535
		j: -1
		--assert i - j = 65536
	--test-- "integer-subtract52"
		--assert 65535 - 0 = 65535
		i: 65535
		j: 0
		--assert i - j = 65535
	--test-- "integer-subtract53"
		--assert 65535 - 1 = 65534
		i: 65535
		j: 1
		--assert i - j = 65534
	--test-- "integer-subtract54"
		--assert 65535 - 255 = 65280
		i: 65535
		j: 255
		--assert i - j = 65280
	--test-- "integer-subtract55"
		--assert 65535 - 256 = 65279
		i: 65535
		j: 256
		--assert i - j = 65279
	--test-- "integer-subtract56"
		--assert 65535 - 65535 = 0
		i: 65535
		j: 65535
		--assert i - j = 0
	--test-- "integer-subtract57"
		--assert 65535 - 65536 = -1
		i: 65535
		j: 65536
		--assert i - j = -1
	--test-- "integer-subtract58"
		--assert 65535 - 2147483647 = -2147418112
		i: 65535
		j: 2147483647
		--assert i - j = -2147418112
	--test-- "integer-subtract59"
		--assert 65535 - -2147483647 = -2147418114
		i: 65535
		j: -2147483647
		--assert i - j = -2147418114
	--test-- "integer-subtract60"
		--assert 65535 - -2147483648 = -2147418113
		i: 65535
		j: -2147483648
		--assert i - j = -2147418113
	--test-- "integer-subtract61"
		--assert 65536 - -1 = 65537
		i: 65536
		j: -1
		--assert i - j = 65537
	--test-- "integer-subtract62"
		--assert 65536 - 0 = 65536
		i: 65536
		j: 0
		--assert i - j = 65536
	--test-- "integer-subtract63"
		--assert 65536 - 1 = 65535
		i: 65536
		j: 1
		--assert i - j = 65535
	--test-- "integer-subtract64"
		--assert 65536 - 255 = 65281
		i: 65536
		j: 255
		--assert i - j = 65281
	--test-- "integer-subtract65"
		--assert 65536 - 256 = 65280
		i: 65536
		j: 256
		--assert i - j = 65280
	--test-- "integer-subtract66"
		--assert 65536 - 65535 = 1
		i: 65536
		j: 65535
		--assert i - j = 1
	--test-- "integer-subtract67"
		--assert 65536 - 65536 = 0
		i: 65536
		j: 65536
		--assert i - j = 0
	--test-- "integer-subtract68"
		--assert 65536 - 2147483647 = -2147418111
		i: 65536
		j: 2147483647
		--assert i - j = -2147418111
	--test-- "integer-subtract69"
		--assert 65536 - -2147483647 = -2147418113
		i: 65536
		j: -2147483647
		--assert i - j = -2147418113
	--test-- "integer-subtract70"
		--assert 65536 - -2147483648 = -2147418112
		i: 65536
		j: -2147483648
		--assert i - j = -2147418112
	--test-- "integer-subtract71"
		--assert 2147483647 - -1 = -2147483648
		i: 2147483647
		j: -1
		--assert i - j = -2147483648
	--test-- "integer-subtract72"
		--assert 2147483647 - 0 = 2147483647
		i: 2147483647
		j: 0
		--assert i - j = 2147483647
	--test-- "integer-subtract73"
		--assert 2147483647 - 1 = 2147483646
		i: 2147483647
		j: 1
		--assert i - j = 2147483646
	--test-- "integer-subtract74"
		--assert 2147483647 - 255 = 2147483392
		i: 2147483647
		j: 255
		--assert i - j = 2147483392
	--test-- "integer-subtract75"
		--assert 2147483647 - 256 = 2147483391
		i: 2147483647
		j: 256
		--assert i - j = 2147483391
	--test-- "integer-subtract76"
		--assert 2147483647 - 65535 = 2147418112
		i: 2147483647
		j: 65535
		--assert i - j = 2147418112
	--test-- "integer-subtract77"
		--assert 2147483647 - 65536 = 2147418111
		i: 2147483647
		j: 65536
		--assert i - j = 2147418111
	--test-- "integer-subtract78"
		--assert 2147483647 - 2147483647 = 0
		i: 2147483647
		j: 2147483647
		--assert i - j = 0
	--test-- "integer-subtract79"
		--assert 2147483647 - -2147483647 = -2
		i: 2147483647
		j: -2147483647
		--assert i - j = -2
	--test-- "integer-subtract80"
		--assert 2147483647 - -2147483648 = -1
		i: 2147483647
		j: -2147483648
		--assert i - j = -1
	--test-- "integer-subtract81"
		--assert -2147483647 - -1 = -2147483646
		i: -2147483647
		j: -1
		--assert i - j = -2147483646
	--test-- "integer-subtract82"
		--assert -2147483647 - 0 = -2147483647
		i: -2147483647
		j: 0
		--assert i - j = -2147483647
	--test-- "integer-subtract83"
		--assert -2147483647 - 1 = -2147483648
		i: -2147483647
		j: 1
		--assert i - j = -2147483648
	--test-- "integer-subtract84"
		--assert -2147483647 - 255 = 2147483394
		i: -2147483647
		j: 255
		--assert i - j = 2147483394
	--test-- "integer-subtract85"
		--assert -2147483647 - 256 = 2147483393
		i: -2147483647
		j: 256
		--assert i - j = 2147483393
	--test-- "integer-subtract86"
		--assert -2147483647 - 65535 = 2147418114
		i: -2147483647
		j: 65535
		--assert i - j = 2147418114
	--test-- "integer-subtract87"
		--assert -2147483647 - 65536 = 2147418113
		i: -2147483647
		j: 65536
		--assert i - j = 2147418113
	--test-- "integer-subtract88"
		--assert -2147483647 - 2147483647 = 2
		i: -2147483647
		j: 2147483647
		--assert i - j = 2
	--test-- "integer-subtract89"
		--assert -2147483647 - -2147483647 = 0
		i: -2147483647
		j: -2147483647
		--assert i - j = 0
	--test-- "integer-subtract90"
		--assert -2147483647 - -2147483648 = 1
		i: -2147483647
		j: -2147483648
		--assert i - j = 1
	--test-- "integer-subtract91"
		--assert -2147483648 - -1 = -2147483647
		i: -2147483648
		j: -1
		--assert i - j = -2147483647
	--test-- "integer-subtract92"
		--assert -2147483648 - 0 = -2147483648
		i: -2147483648
		j: 0
		--assert i - j = -2147483648
	--test-- "integer-subtract93"
		--assert -2147483648 - 1 = 2147483647
		i: -2147483648
		j: 1
		--assert i - j = 2147483647
	--test-- "integer-subtract94"
		--assert -2147483648 - 255 = 2147483393
		i: -2147483648
		j: 255
		--assert i - j = 2147483393
	--test-- "integer-subtract95"
		--assert -2147483648 - 256 = 2147483392
		i: -2147483648
		j: 256
		--assert i - j = 2147483392
	--test-- "integer-subtract96"
		--assert -2147483648 - 65535 = 2147418113
		i: -2147483648
		j: 65535
		--assert i - j = 2147418113
	--test-- "integer-subtract97"
		--assert -2147483648 - 65536 = 2147418112
		i: -2147483648
		j: 65536
		--assert i - j = 2147418112
	--test-- "integer-subtract98"
		--assert -2147483648 - 2147483647 = 1
		i: -2147483648
		j: 2147483647
		--assert i - j = 1
	--test-- "integer-subtract99"
		--assert -2147483648 - -2147483647 = -1
		i: -2147483648
		j: -2147483647
		--assert i - j = -1
	--test-- "integer-subtract100"
		--assert -2147483648 - -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i - j = 0
	--test-- "integer-subtract101"
		--assert -1 - -1 = 0
		i: -1
		j: -1
		--assert i - j = 0
	--test-- "integer-subtract102"
		--assert 0 - 0 = 0
		i: 0
		j: 0
		--assert i - j = 0
	--test-- "integer-subtract103"
		--assert 1 - 1 = 0
		i: 1
		j: 1
		--assert i - j = 0
	--test-- "integer-subtract104"
		--assert 255 - 255 = 0
		i: 255
		j: 255
		--assert i - j = 0
	--test-- "integer-subtract105"
		--assert 256 - 256 = 0
		i: 256
		j: 256
		--assert i - j = 0
	--test-- "integer-subtract106"
		--assert 65535 - 65535 = 0
		i: 65535
		j: 65535
		--assert i - j = 0
	--test-- "integer-subtract107"
		--assert 65536 - 65536 = 0
		i: 65536
		j: 65536
		--assert i - j = 0
	--test-- "integer-subtract108"
		--assert 2147483647 - 2147483647 = 0
		i: 2147483647
		j: 2147483647
		--assert i - j = 0
	--test-- "integer-subtract109"
		--assert -2147483647 - -2147483647 = 0
		i: -2147483647
		j: -2147483647
		--assert i - j = 0
	--test-- "integer-subtract110"
		--assert -2147483648 - -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i - j = 0

===end-group===

===start-group=== "integer-multiply"

	--test-- "integer-multiply1"
		--assert -1 * -1 = 1
		i: -1
		j: -1
		--assert i * j = 1
	--test-- "integer-multiply2"
		--assert -1 * 0 = 0
		i: -1
		j: 0
		--assert i * j = 0
	--test-- "integer-multiply3"
		--assert -1 * 1 = -1
		i: -1
		j: 1
		--assert i * j = -1
	--test-- "integer-multiply4"
		--assert -1 * 255 = -255
		i: -1
		j: 255
		--assert i * j = -255
	--test-- "integer-multiply5"
		--assert -1 * 256 = -256
		i: -1
		j: 256
		--assert i * j = -256
	--test-- "integer-multiply6"
		--assert -1 * 65535 = -65535
		i: -1
		j: 65535
		--assert i * j = -65535
	--test-- "integer-multiply7"
		--assert -1 * 65536 = -65536
		i: -1
		j: 65536
		--assert i * j = -65536
	--test-- "integer-multiply8"
		--assert -1 * 2147483647 = -2147483647
		i: -1
		j: 2147483647
		--assert i * j = -2147483647
	--test-- "integer-multiply9"
		--assert -1 * -2147483647 = 2147483647
		i: -1
		j: -2147483647
		--assert i * j = 2147483647
	--test-- "integer-multiply10"
		--assert -1 * -2147483648 = -2147483648
		i: -1
		j: -2147483648
		--assert i * j = -2147483648
	--test-- "integer-multiply11"
		--assert 0 * 0 = 0
		i: 0
		j: 0
		--assert i * j = 0
	--test-- "integer-multiply12"
		--assert 0 * 1 = 0
		i: 0
		j: 1
		--assert i * j = 0
	--test-- "integer-multiply13"
		--assert 0 * 255 = 0
		i: 0
		j: 255
		--assert i * j = 0
	--test-- "integer-multiply14"
		--assert 0 * 256 = 0
		i: 0
		j: 256
		--assert i * j = 0
	--test-- "integer-multiply15"
		--assert 0 * 65535 = 0
		i: 0
		j: 65535
		--assert i * j = 0
	--test-- "integer-multiply16"
		--assert 0 * 65536 = 0
		i: 0
		j: 65536
		--assert i * j = 0
	--test-- "integer-multiply17"
		--assert 0 * 2147483647 = 0
		i: 0
		j: 2147483647
		--assert i * j = 0
	--test-- "integer-multiply18"
		--assert 0 * -2147483647 = 0
		i: 0
		j: -2147483647
		--assert i * j = 0
	--test-- "integer-multiply19"
		--assert 0 * -2147483648 = 0
		i: 0
		j: -2147483648
		--assert i * j = 0
	--test-- "integer-multiply20"
		--assert 1 * 1 = 1
		i: 1
		j: 1
		--assert i * j = 1
	--test-- "integer-multiply21"
		--assert 1 * 255 = 255
		i: 1
		j: 255
		--assert i * j = 255
	--test-- "integer-multiply22"
		--assert 1 * 256 = 256
		i: 1
		j: 256
		--assert i * j = 256
	--test-- "integer-multiply23"
		--assert 1 * 65535 = 65535
		i: 1
		j: 65535
		--assert i * j = 65535
	--test-- "integer-multiply24"
		--assert 1 * 65536 = 65536
		i: 1
		j: 65536
		--assert i * j = 65536
	--test-- "integer-multiply25"
		--assert 1 * 2147483647 = 2147483647
		i: 1
		j: 2147483647
		--assert i * j = 2147483647
	--test-- "integer-multiply26"
		--assert 1 * -2147483647 = -2147483647
		i: 1
		j: -2147483647
		--assert i * j = -2147483647
	--test-- "integer-multiply27"
		--assert 1 * -2147483648 = -2147483648
		i: 1
		j: -2147483648
		--assert i * j = -2147483648
	--test-- "integer-multiply28"
		--assert 255 * 255 = 65025
		i: 255
		j: 255
		--assert i * j = 65025
	--test-- "integer-multiply29"
		--assert 255 * 256 = 65280
		i: 255
		j: 256
		--assert i * j = 65280
	--test-- "integer-multiply30"
		--assert 255 * 65535 = 16711425
		i: 255
		j: 65535
		--assert i * j = 16711425
	--test-- "integer-multiply31"
		--assert 255 * 65536 = 16711680
		i: 255
		j: 65536
		--assert i * j = 16711680
	--test-- "integer-multiply32"
		--assert 255 * 2147483647 = 2147483393
		i: 255
		j: 2147483647
		--assert i * j = 2147483393
	--test-- "integer-multiply33"
		--assert 255 * -2147483647 = -2147483393
		i: 255
		j: -2147483647
		--assert i * j = -2147483393
	--test-- "integer-multiply34"
		--assert 255 * -2147483648 = -2147483648
		i: 255
		j: -2147483648
		--assert i * j = -2147483648
	--test-- "integer-multiply35"
		--assert 256 * 256 = 65536
		i: 256
		j: 256
		--assert i * j = 65536
	--test-- "integer-multiply36"
		--assert 256 * 65535 = 16776960
		i: 256
		j: 65535
		--assert i * j = 16776960
	--test-- "integer-multiply37"
		--assert 256 * 65536 = 16777216
		i: 256
		j: 65536
		--assert i * j = 16777216
	--test-- "integer-multiply38"
		--assert 256 * 2147483647 = -256
		i: 256
		j: 2147483647
		--assert i * j = -256
	--test-- "integer-multiply39"
		--assert 256 * -2147483647 = 256
		i: 256
		j: -2147483647
		--assert i * j = 256
	--test-- "integer-multiply40"
		--assert 256 * -2147483648 = 0
		i: 256
		j: -2147483648
		--assert i * j = 0
	--test-- "integer-multiply41"
		--assert 65535 * 65535 = -131071
		i: 65535
		j: 65535
		--assert i * j = -131071
	--test-- "integer-multiply42"
		--assert 65535 * 65536 = -65536
		i: 65535
		j: 65536
		--assert i * j = -65536
	--test-- "integer-multiply43"
		--assert 65535 * 2147483647 = 2147418113
		i: 65535
		j: 2147483647
		--assert i * j = 2147418113
	--test-- "integer-multiply44"
		--assert 65535 * -2147483647 = -2147418113
		i: 65535
		j: -2147483647
		--assert i * j = -2147418113
	--test-- "integer-multiply45"
		--assert 65535 * -2147483648 = -2147483648
		i: 65535
		j: -2147483648
		--assert i * j = -2147483648
	--test-- "integer-multiply46"
		--assert 65536 * 65536 = 0
		i: 65536
		j: 65536
		--assert i * j = 0
	--test-- "integer-multiply47"
		--assert 65536 * 2147483647 = -65536
		i: 65536
		j: 2147483647
		--assert i * j = -65536
	--test-- "integer-multiply48"
		--assert 65536 * -2147483647 = 65536
		i: 65536
		j: -2147483647
		--assert i * j = 65536
	--test-- "integer-multiply49"
		--assert 65536 * -2147483648 = 0
		i: 65536
		j: -2147483648
		--assert i * j = 0
	--test-- "integer-multiply50"
		--assert 2147483647 * 2147483647 = 1
		i: 2147483647
		j: 2147483647
		--assert i * j = 1
	--test-- "integer-multiply51"
		--assert 2147483647 * -2147483647 = -1
		i: 2147483647
		j: -2147483647
		--assert i * j = -1
	--test-- "integer-multiply52"
		--assert 2147483647 * -2147483648 = -2147483648
		i: 2147483647
		j: -2147483648
		--assert i * j = -2147483648
	--test-- "integer-multiply53"
		--assert -2147483647 * -2147483647 = 1
		i: -2147483647
		j: -2147483647
		--assert i * j = 1
	--test-- "integer-multiply54"
		--assert -2147483647 * -2147483648 = -2147483648
		i: -2147483647
		j: -2147483648
		--assert i * j = -2147483648
	--test-- "integer-multiply55"
		--assert -2147483648 * -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i * j = 0
	--test-- "integer-multiply56"
		--assert -1 * -1 = 1
		i: -1
		j: -1
		--assert i * j = 1
	--test-- "integer-multiply57"
		--assert 0 * 0 = 0
		i: 0
		j: 0
		--assert i * j = 0
	--test-- "integer-multiply58"
		--assert 1 * 1 = 1
		i: 1
		j: 1
		--assert i * j = 1
	--test-- "integer-multiply59"
		--assert 255 * 255 = 65025
		i: 255
		j: 255
		--assert i * j = 65025
	--test-- "integer-multiply60"
		--assert 256 * 256 = 65536
		i: 256
		j: 256
		--assert i * j = 65536
	--test-- "integer-multiply61"
		--assert 65535 * 65535 = -131071
		i: 65535
		j: 65535
		--assert i * j = -131071
	--test-- "integer-multiply62"
		--assert 65536 * 65536 = 0
		i: 65536
		j: 65536
		--assert i * j = 0
	--test-- "integer-multiply63"
		--assert 2147483647 * 2147483647 = 1
		i: 2147483647
		j: 2147483647
		--assert i * j = 1
	--test-- "integer-multiply64"
		--assert -2147483647 * -2147483647 = 1
		i: -2147483647
		j: -2147483647
		--assert i * j = 1
	--test-- "integer-multiply65"
		--assert -2147483648 * -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i * j = 0

===end-group===

===start-group=== "integer-divide"

	--test-- "integer-divide1"
		--assert -1 / -1 = 1
		i: -1
		j: -1
		--assert i / j = 1
	--test-- "integer-divide2"
		--assert -1 / 1 = -1
		i: -1
		j: 1
		--assert i / j = -1
	--test-- "integer-divide3"
		--assert -1 / 255 = 0
		i: -1
		j: 255
		--assert i / j = 0
	--test-- "integer-divide4"
		--assert -1 / 256 = 0
		i: -1
		j: 256
		--assert i / j = 0
	--test-- "integer-divide5"
		--assert -1 / 65535 = 0
		i: -1
		j: 65535
		--assert i / j = 0
	--test-- "integer-divide6"
		--assert -1 / 65536 = 0
		i: -1
		j: 65536
		--assert i / j = 0
	--test-- "integer-divide7"
		--assert -1 / 2147483647 = 0
		i: -1
		j: 2147483647
		--assert i / j = 0
	--test-- "integer-divide8"
		--assert -1 / -2147483647 = 0
		i: -1
		j: -2147483647
		--assert i / j = 0
	--test-- "integer-divide9"
		--assert -1 / -2147483648 = 0
		i: -1
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide10"
		--assert 0 / -1 = 0
		i: 0
		j: -1
		--assert i / j = 0
	--test-- "integer-divide11"
		--assert 0 / 1 = 0
		i: 0
		j: 1
		--assert i / j = 0
	--test-- "integer-divide12"
		--assert 0 / 255 = 0
		i: 0
		j: 255
		--assert i / j = 0
	--test-- "integer-divide13"
		--assert 0 / 256 = 0
		i: 0
		j: 256
		--assert i / j = 0
	--test-- "integer-divide14"
		--assert 0 / 65535 = 0
		i: 0
		j: 65535
		--assert i / j = 0
	--test-- "integer-divide15"
		--assert 0 / 65536 = 0
		i: 0
		j: 65536
		--assert i / j = 0
	--test-- "integer-divide16"
		--assert 0 / 2147483647 = 0
		i: 0
		j: 2147483647
		--assert i / j = 0
	--test-- "integer-divide17"
		--assert 0 / -2147483647 = 0
		i: 0
		j: -2147483647
		--assert i / j = 0
	--test-- "integer-divide18"
		--assert 0 / -2147483648 = 0
		i: 0
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide19"
		--assert 1 / -1 = -1
		i: 1
		j: -1
		--assert i / j = -1
	--test-- "integer-divide20"
		--assert 1 / 1 = 1
		i: 1
		j: 1
		--assert i / j = 1
	--test-- "integer-divide21"
		--assert 1 / 255 = 0
		i: 1
		j: 255
		--assert i / j = 0
	--test-- "integer-divide22"
		--assert 1 / 256 = 0
		i: 1
		j: 256
		--assert i / j = 0
	--test-- "integer-divide23"
		--assert 1 / 65535 = 0
		i: 1
		j: 65535
		--assert i / j = 0
	--test-- "integer-divide24"
		--assert 1 / 65536 = 0
		i: 1
		j: 65536
		--assert i / j = 0
	--test-- "integer-divide25"
		--assert 1 / 2147483647 = 0
		i: 1
		j: 2147483647
		--assert i / j = 0
	--test-- "integer-divide26"
		--assert 1 / -2147483647 = 0
		i: 1
		j: -2147483647
		--assert i / j = 0
	--test-- "integer-divide27"
		--assert 1 / -2147483648 = 0
		i: 1
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide28"
		--assert 255 / -1 = -255
		i: 255
		j: -1
		--assert i / j = -255
	--test-- "integer-divide29"
		--assert 255 / 1 = 255
		i: 255
		j: 1
		--assert i / j = 255
	--test-- "integer-divide30"
		--assert 255 / 255 = 1
		i: 255
		j: 255
		--assert i / j = 1
	--test-- "integer-divide31"
		--assert 255 / 256 = 0
		i: 255
		j: 256
		--assert i / j = 0
	--test-- "integer-divide32"
		--assert 255 / 65535 = 0
		i: 255
		j: 65535
		--assert i / j = 0
	--test-- "integer-divide33"
		--assert 255 / 65536 = 0
		i: 255
		j: 65536
		--assert i / j = 0
	--test-- "integer-divide34"
		--assert 255 / 2147483647 = 0
		i: 255
		j: 2147483647
		--assert i / j = 0
	--test-- "integer-divide35"
		--assert 255 / -2147483647 = 0
		i: 255
		j: -2147483647
		--assert i / j = 0
	--test-- "integer-divide36"
		--assert 255 / -2147483648 = 0
		i: 255
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide37"
		--assert 256 / -1 = -256
		i: 256
		j: -1
		--assert i / j = -256
	--test-- "integer-divide38"
		--assert 256 / 1 = 256
		i: 256
		j: 1
		--assert i / j = 256
	--test-- "integer-divide39"
		--assert 256 / 255 = 1
		i: 256
		j: 255
		--assert i / j = 1
	--test-- "integer-divide40"
		--assert 256 / 256 = 1
		i: 256
		j: 256
		--assert i / j = 1
	--test-- "integer-divide41"
		--assert 256 / 65535 = 0
		i: 256
		j: 65535
		--assert i / j = 0
	--test-- "integer-divide42"
		--assert 256 / 65536 = 0
		i: 256
		j: 65536
		--assert i / j = 0
	--test-- "integer-divide43"
		--assert 256 / 2147483647 = 0
		i: 256
		j: 2147483647
		--assert i / j = 0
	--test-- "integer-divide44"
		--assert 256 / -2147483647 = 0
		i: 256
		j: -2147483647
		--assert i / j = 0
	--test-- "integer-divide45"
		--assert 256 / -2147483648 = 0
		i: 256
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide46"
		--assert 65535 / -1 = -65535
		i: 65535
		j: -1
		--assert i / j = -65535
	--test-- "integer-divide47"
		--assert 65535 / 1 = 65535
		i: 65535
		j: 1
		--assert i / j = 65535
	--test-- "integer-divide48"
		--assert 65535 / 255 = 257
		i: 65535
		j: 255
		--assert i / j = 257
	--test-- "integer-divide49"
		--assert 65535 / 256 = 255
		i: 65535
		j: 256
		--assert i / j = 255
	--test-- "integer-divide50"
		--assert 65535 / 65535 = 1
		i: 65535
		j: 65535
		--assert i / j = 1
	--test-- "integer-divide51"
		--assert 65535 / 65536 = 0
		i: 65535
		j: 65536
		--assert i / j = 0
	--test-- "integer-divide52"
		--assert 65535 / 2147483647 = 0
		i: 65535
		j: 2147483647
		--assert i / j = 0
	--test-- "integer-divide53"
		--assert 65535 / -2147483647 = 0
		i: 65535
		j: -2147483647
		--assert i / j = 0
	--test-- "integer-divide54"
		--assert 65535 / -2147483648 = 0
		i: 65535
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide55"
		--assert 65536 / -1 = -65536
		i: 65536
		j: -1
		--assert i / j = -65536
	--test-- "integer-divide56"
		--assert 65536 / 1 = 65536
		i: 65536
		j: 1
		--assert i / j = 65536
	--test-- "integer-divide57"
		--assert 65536 / 255 = 257
		i: 65536
		j: 255
		--assert i / j = 257
	--test-- "integer-divide58"
		--assert 65536 / 256 = 256
		i: 65536
		j: 256
		--assert i / j = 256
	--test-- "integer-divide59"
		--assert 65536 / 65535 = 1
		i: 65536
		j: 65535
		--assert i / j = 1
	--test-- "integer-divide60"
		--assert 65536 / 65536 = 1
		i: 65536
		j: 65536
		--assert i / j = 1
	--test-- "integer-divide61"
		--assert 65536 / 2147483647 = 0
		i: 65536
		j: 2147483647
		--assert i / j = 0
	--test-- "integer-divide62"
		--assert 65536 / -2147483647 = 0
		i: 65536
		j: -2147483647
		--assert i / j = 0
	--test-- "integer-divide63"
		--assert 65536 / -2147483648 = 0
		i: 65536
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide64"
		--assert 2147483647 / -1 = -2147483647
		i: 2147483647
		j: -1
		--assert i / j = -2147483647
	--test-- "integer-divide65"
		--assert 2147483647 / 1 = 2147483647
		i: 2147483647
		j: 1
		--assert i / j = 2147483647
	--test-- "integer-divide66"
		--assert 2147483647 / 255 = 8421504
		i: 2147483647
		j: 255
		--assert i / j = 8421504
	--test-- "integer-divide67"
		--assert 2147483647 / 256 = 8388607
		i: 2147483647
		j: 256
		--assert i / j = 8388607
	--test-- "integer-divide68"
		--assert 2147483647 / 65535 = 32768
		i: 2147483647
		j: 65535
		--assert i / j = 32768
	--test-- "integer-divide69"
		--assert 2147483647 / 65536 = 32767
		i: 2147483647
		j: 65536
		--assert i / j = 32767
	--test-- "integer-divide70"
		--assert 2147483647 / 2147483647 = 1
		i: 2147483647
		j: 2147483647
		--assert i / j = 1
	--test-- "integer-divide71"
		--assert 2147483647 / -2147483647 = -1
		i: 2147483647
		j: -2147483647
		--assert i / j = -1
	--test-- "integer-divide72"
		--assert 2147483647 / -2147483648 = 0
		i: 2147483647
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide73"
		--assert -2147483647 / -1 = 2147483647
		i: -2147483647
		j: -1
		--assert i / j = 2147483647
	--test-- "integer-divide74"
		--assert -2147483647 / 1 = -2147483647
		i: -2147483647
		j: 1
		--assert i / j = -2147483647
	--test-- "integer-divide75"
		--assert -2147483647 / 255 = -8421504
		i: -2147483647
		j: 255
		--assert i / j = -8421504
	--test-- "integer-divide76"
		--assert -2147483647 / 256 = -8388607
		i: -2147483647
		j: 256
		--assert i / j = -8388607
	--test-- "integer-divide77"
		--assert -2147483647 / 65535 = -32768
		i: -2147483647
		j: 65535
		--assert i / j = -32768
	--test-- "integer-divide78"
		--assert -2147483647 / 65536 = -32767
		i: -2147483647
		j: 65536
		--assert i / j = -32767
	--test-- "integer-divide79"
		--assert -2147483647 / 2147483647 = -1
		i: -2147483647
		j: 2147483647
		--assert i / j = -1
	--test-- "integer-divide80"
		--assert -2147483647 / -2147483647 = 1
		i: -2147483647
		j: -2147483647
		--assert i / j = 1
	--test-- "integer-divide81"
		--assert -2147483647 / -2147483648 = 0
		i: -2147483647
		j: -2147483648
		--assert i / j = 0
	--test-- "integer-divide82"
		;--assert -2147483648 / -1 = -2147483648
		i: -2147483648
		j: -1
		;--assert i / j = -2147483648
	--test-- "integer-divide83"
		--assert -2147483648 / 1 = -2147483648
		i: -2147483648
		j: 1
		--assert i / j = -2147483648
	--test-- "integer-divide84"
		--assert -2147483648 / 255 = -8421504
		i: -2147483648
		j: 255
		--assert i / j = -8421504
	--test-- "integer-divide85"
		--assert -2147483648 / 256 = -8388608
		i: -2147483648
		j: 256
		--assert i / j = -8388608
	--test-- "integer-divide86"
		--assert -2147483648 / 65535 = -32768
		i: -2147483648
		j: 65535
		--assert i / j = -32768
	--test-- "integer-divide87"
		--assert -2147483648 / 65536 = -32768
		i: -2147483648
		j: 65536
		--assert i / j = -32768
	--test-- "integer-divide88"
		--assert -2147483648 / 2147483647 = -1
		i: -2147483648
		j: 2147483647
		--assert i / j = -1
	--test-- "integer-divide89"
		--assert -2147483648 / -2147483647 = 1
		i: -2147483648
		j: -2147483647
		--assert i / j = 1
	--test-- "integer-divide90"
		--assert -2147483648 / -2147483648 = 1
		i: -2147483648
		j: -2147483648
		--assert i / j = 1
	--test-- "integer-divide91"
		--assert -1 / -1 = 1
		i: -1
		j: -1
		--assert i / j = 1
	--test-- "integer-divide92"
		--assert 1 / 1 = 1
		i: 1
		j: 1
		--assert i / j = 1
	--test-- "integer-divide93"
		--assert 255 / 255 = 1
		i: 255
		j: 255
		--assert i / j = 1
	--test-- "integer-divide94"
		--assert 256 / 256 = 1
		i: 256
		j: 256
		--assert i / j = 1
	--test-- "integer-divide95"
		--assert 65535 / 65535 = 1
		i: 65535
		j: 65535
		--assert i / j = 1
	--test-- "integer-divide96"
		--assert 65536 / 65536 = 1
		i: 65536
		j: 65536
		--assert i / j = 1
	--test-- "integer-divide97"
		--assert 2147483647 / 2147483647 = 1
		i: 2147483647
		j: 2147483647
		--assert i / j = 1
	--test-- "integer-divide98"
		--assert -2147483647 / -2147483647 = 1
		i: -2147483647
		j: -2147483647
		--assert i / j = 1
	--test-- "integer-divide99"
		--assert -2147483648 / -2147483648 = 1
		i: -2147483648
		j: -2147483648
		--assert i / j = 1

===end-group===

===start-group=== "integer-modulo"

	--test-- "integer-modulo1"
		--assert -1 % -1 = 0
		i: -1
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo2"
		--assert -1 % 1 = 0
		i: -1
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo3"
		--assert -1 % 255 = -1
		i: -1
		j: 255
		--assert i % j = -1
	--test-- "integer-modulo4"
		--assert -1 % 256 = -1
		i: -1
		j: 256
		--assert i % j = -1
	--test-- "integer-modulo5"
		--assert -1 % 65535 = -1
		i: -1
		j: 65535
		--assert i % j = -1
	--test-- "integer-modulo6"
		--assert -1 % 65536 = -1
		i: -1
		j: 65536
		--assert i % j = -1
	--test-- "integer-modulo7"
		--assert -1 % 2147483647 = -1
		i: -1
		j: 2147483647
		--assert i % j = -1
	--test-- "integer-modulo8"
		--assert -1 % -2147483647 = -1
		i: -1
		j: -2147483647
		--assert i % j = -1
	--test-- "integer-modulo9"
		--assert -1 % -2147483648 = -1
		i: -1
		j: -2147483648
		--assert i % j = -1
	--test-- "integer-modulo10"
		--assert 0 % -1 = 0
		i: 0
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo11"
		--assert 0 % 1 = 0
		i: 0
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo12"
		--assert 0 % 255 = 0
		i: 0
		j: 255
		--assert i % j = 0
	--test-- "integer-modulo13"
		--assert 0 % 256 = 0
		i: 0
		j: 256
		--assert i % j = 0
	--test-- "integer-modulo14"
		--assert 0 % 65535 = 0
		i: 0
		j: 65535
		--assert i % j = 0
	--test-- "integer-modulo15"
		--assert 0 % 65536 = 0
		i: 0
		j: 65536
		--assert i % j = 0
	--test-- "integer-modulo16"
		--assert 0 % 2147483647 = 0
		i: 0
		j: 2147483647
		--assert i % j = 0
	--test-- "integer-modulo17"
		--assert 0 % -2147483647 = 0
		i: 0
		j: -2147483647
		--assert i % j = 0
	--test-- "integer-modulo18"
		--assert 0 % -2147483648 = 0
		i: 0
		j: -2147483648
		--assert i % j = 0
	--test-- "integer-modulo19"
		--assert 1 % -1 = 0
		i: 1
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo20"
		--assert 1 % 1 = 0
		i: 1
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo21"
		--assert 1 % 255 = 1
		i: 1
		j: 255
		--assert i % j = 1
	--test-- "integer-modulo22"
		--assert 1 % 256 = 1
		i: 1
		j: 256
		--assert i % j = 1
	--test-- "integer-modulo23"
		--assert 1 % 65535 = 1
		i: 1
		j: 65535
		--assert i % j = 1
	--test-- "integer-modulo24"
		--assert 1 % 65536 = 1
		i: 1
		j: 65536
		--assert i % j = 1
	--test-- "integer-modulo25"
		--assert 1 % 2147483647 = 1
		i: 1
		j: 2147483647
		--assert i % j = 1
	--test-- "integer-modulo26"
		--assert 1 % -2147483647 = 1
		i: 1
		j: -2147483647
		--assert i % j = 1
	--test-- "integer-modulo27"
		--assert 1 % -2147483648 = 1
		i: 1
		j: -2147483648
		--assert i % j = 1
	--test-- "integer-modulo28"
		--assert 255 % -1 = 0
		i: 255
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo29"
		--assert 255 % 1 = 0
		i: 255
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo30"
		--assert 255 % 255 = 0
		i: 255
		j: 255
		--assert i % j = 0
	--test-- "integer-modulo31"
		--assert 255 % 256 = 255
		i: 255
		j: 256
		--assert i % j = 255
	--test-- "integer-modulo32"
		--assert 255 % 65535 = 255
		i: 255
		j: 65535
		--assert i % j = 255
	--test-- "integer-modulo33"
		--assert 255 % 65536 = 255
		i: 255
		j: 65536
		--assert i % j = 255
	--test-- "integer-modulo34"
		--assert 255 % 2147483647 = 255
		i: 255
		j: 2147483647
		--assert i % j = 255
	--test-- "integer-modulo35"
		--assert 255 % -2147483647 = 255
		i: 255
		j: -2147483647
		--assert i % j = 255
	--test-- "integer-modulo36"
		--assert 255 % -2147483648 = 255
		i: 255
		j: -2147483648
		--assert i % j = 255
	--test-- "integer-modulo37"
		--assert 256 % -1 = 0
		i: 256
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo38"
		--assert 256 % 1 = 0
		i: 256
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo39"
		--assert 256 % 255 = 1
		i: 256
		j: 255
		--assert i % j = 1
	--test-- "integer-modulo40"
		--assert 256 % 256 = 0
		i: 256
		j: 256
		--assert i % j = 0
	--test-- "integer-modulo41"
		--assert 256 % 65535 = 256
		i: 256
		j: 65535
		--assert i % j = 256
	--test-- "integer-modulo42"
		--assert 256 % 65536 = 256
		i: 256
		j: 65536
		--assert i % j = 256
	--test-- "integer-modulo43"
		--assert 256 % 2147483647 = 256
		i: 256
		j: 2147483647
		--assert i % j = 256
	--test-- "integer-modulo44"
		--assert 256 % -2147483647 = 256
		i: 256
		j: -2147483647
		--assert i % j = 256
	--test-- "integer-modulo45"
		--assert 256 % -2147483648 = 256
		i: 256
		j: -2147483648
		--assert i % j = 256
	--test-- "integer-modulo46"
		--assert 65535 % -1 = 0
		i: 65535
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo47"
		--assert 65535 % 1 = 0
		i: 65535
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo48"
		--assert 65535 % 255 = 0
		i: 65535
		j: 255
		--assert i % j = 0
	--test-- "integer-modulo49"
		--assert 65535 % 256 = 255
		i: 65535
		j: 256
		--assert i % j = 255
	--test-- "integer-modulo50"
		--assert 65535 % 65535 = 0
		i: 65535
		j: 65535
		--assert i % j = 0
	--test-- "integer-modulo51"
		--assert 65535 % 65536 = 65535
		i: 65535
		j: 65536
		--assert i % j = 65535
	--test-- "integer-modulo52"
		--assert 65535 % 2147483647 = 65535
		i: 65535
		j: 2147483647
		--assert i % j = 65535
	--test-- "integer-modulo53"
		--assert 65535 % -2147483647 = 65535
		i: 65535
		j: -2147483647
		--assert i % j = 65535
	--test-- "integer-modulo54"
		--assert 65535 % -2147483648 = 65535
		i: 65535
		j: -2147483648
		--assert i % j = 65535
	--test-- "integer-modulo55"
		--assert 65536 % -1 = 0
		i: 65536
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo56"
		--assert 65536 % 1 = 0
		i: 65536
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo57"
		--assert 65536 % 255 = 1
		i: 65536
		j: 255
		--assert i % j = 1
	--test-- "integer-modulo58"
		--assert 65536 % 256 = 0
		i: 65536
		j: 256
		--assert i % j = 0
	--test-- "integer-modulo59"
		--assert 65536 % 65535 = 1
		i: 65536
		j: 65535
		--assert i % j = 1
	--test-- "integer-modulo60"
		--assert 65536 % 65536 = 0
		i: 65536
		j: 65536
		--assert i % j = 0
	--test-- "integer-modulo61"
		--assert 65536 % 2147483647 = 65536
		i: 65536
		j: 2147483647
		--assert i % j = 65536
	--test-- "integer-modulo62"
		--assert 65536 % -2147483647 = 65536
		i: 65536
		j: -2147483647
		--assert i % j = 65536
	--test-- "integer-modulo63"
		--assert 65536 % -2147483648 = 65536
		i: 65536
		j: -2147483648
		--assert i % j = 65536
	--test-- "integer-modulo64"
		--assert 2147483647 % -1 = 0
		i: 2147483647
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo65"
		--assert 2147483647 % 1 = 0
		i: 2147483647
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo66"
		--assert 2147483647 % 255 = 127
		i: 2147483647
		j: 255
		--assert i % j = 127
	--test-- "integer-modulo67"
		--assert 2147483647 % 256 = 255
		i: 2147483647
		j: 256
		--assert i % j = 255
	--test-- "integer-modulo68"
		--assert 2147483647 % 65535 = 32767
		i: 2147483647
		j: 65535
		--assert i % j = 32767
	--test-- "integer-modulo69"
		--assert 2147483647 % 65536 = 65535
		i: 2147483647
		j: 65536
		--assert i % j = 65535
	--test-- "integer-modulo70"
		--assert 2147483647 % 2147483647 = 0
		i: 2147483647
		j: 2147483647
		--assert i % j = 0
	--test-- "integer-modulo71"
		--assert 2147483647 % -2147483647 = 0
		i: 2147483647
		j: -2147483647
		--assert i % j = 0
	--test-- "integer-modulo72"
		--assert 2147483647 % -2147483648 = 2147483647
		i: 2147483647
		j: -2147483648
		--assert i % j = 2147483647
	--test-- "integer-modulo73"
		--assert -2147483647 % -1 = 0
		i: -2147483647
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo74"
		--assert -2147483647 % 1 = 0
		i: -2147483647
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo75"
		--assert -2147483647 % 255 = -127
		i: -2147483647
		j: 255
		--assert i % j = -127
	--test-- "integer-modulo76"
		--assert -2147483647 % 256 = -255
		i: -2147483647
		j: 256
		--assert i % j = -255
	--test-- "integer-modulo77"
		--assert -2147483647 % 65535 = -32767
		i: -2147483647
		j: 65535
		--assert i % j = -32767
	--test-- "integer-modulo78"
		--assert -2147483647 % 65536 = -65535
		i: -2147483647
		j: 65536
		--assert i % j = -65535
	--test-- "integer-modulo79"
		--assert -2147483647 % 2147483647 = 0
		i: -2147483647
		j: 2147483647
		--assert i % j = 0
	--test-- "integer-modulo80"
		--assert -2147483647 % -2147483647 = 0
		i: -2147483647
		j: -2147483647
		--assert i % j = 0
	--test-- "integer-modulo81"
		--assert -2147483647 % -2147483648 = -2147483647
		i: -2147483647
		j: -2147483648
		--assert i % j = -2147483647
	--test-- "integer-modulo82"
		;--assert -2147483648 % -1 = 0
		i: -2147483648
		j: -1
		;--assert i % j = 0
	--test-- "integer-modulo83"
		--assert -2147483648 % 1 = 0
		i: -2147483648
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo84"
		--assert -2147483648 % 255 = -128
		i: -2147483648
		j: 255
		--assert i % j = -128
	--test-- "integer-modulo85"
		--assert -2147483648 % 256 = 0
		i: -2147483648
		j: 256
		--assert i % j = 0
	--test-- "integer-modulo86"
		--assert -2147483648 % 65535 = -32768
		i: -2147483648
		j: 65535
		--assert i % j = -32768
	--test-- "integer-modulo87"
		--assert -2147483648 % 65536 = 0
		i: -2147483648
		j: 65536
		--assert i % j = 0
	--test-- "integer-modulo88"
		--assert -2147483648 % 2147483647 = -1
		i: -2147483648
		j: 2147483647
		--assert i % j = -1
	--test-- "integer-modulo89"
		--assert -2147483648 % -2147483647 = -1
		i: -2147483648
		j: -2147483647
		--assert i % j = -1
	--test-- "integer-modulo90"
		--assert -2147483648 % -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i % j = 0
	--test-- "integer-modulo91"
		--assert -1 % -1 = 0
		i: -1
		j: -1
		--assert i % j = 0
	--test-- "integer-modulo92"
		--assert 1 % 1 = 0
		i: 1
		j: 1
		--assert i % j = 0
	--test-- "integer-modulo93"
		--assert 255 % 255 = 0
		i: 255
		j: 255
		--assert i % j = 0
	--test-- "integer-modulo94"
		--assert 256 % 256 = 0
		i: 256
		j: 256
		--assert i % j = 0
	--test-- "integer-modulo95"
		--assert 65535 % 65535 = 0
		i: 65535
		j: 65535
		--assert i % j = 0
	--test-- "integer-modulo96"
		--assert 65536 % 65536 = 0
		i: 65536
		j: 65536
		--assert i % j = 0
	--test-- "integer-modulo97"
		--assert 2147483647 % 2147483647 = 0
		i: 2147483647
		j: 2147483647
		--assert i % j = 0
	--test-- "integer-modulo98"
		--assert -2147483647 % -2147483647 = 0
		i: -2147483647
		j: -2147483647
		--assert i % j = 0
	--test-- "integer-modulo99"
		--assert -2147483648 % -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i % j = 0

===end-group===

===start-group=== "integer-and"

	--test-- "integer-and1"
		--assert -1 and -1 = -1
		i: -1
		j: -1
		--assert i and j = -1
	--test-- "integer-and2"
		--assert -1 and 0 = 0
		i: -1
		j: 0
		--assert i and j = 0
	--test-- "integer-and3"
		--assert -1 and 1 = 1
		i: -1
		j: 1
		--assert i and j = 1
	--test-- "integer-and4"
		--assert -1 and 255 = 255
		i: -1
		j: 255
		--assert i and j = 255
	--test-- "integer-and5"
		--assert -1 and 256 = 256
		i: -1
		j: 256
		--assert i and j = 256
	--test-- "integer-and6"
		--assert -1 and 65535 = 65535
		i: -1
		j: 65535
		--assert i and j = 65535
	--test-- "integer-and7"
		--assert -1 and 65536 = 65536
		i: -1
		j: 65536
		--assert i and j = 65536
	--test-- "integer-and8"
		--assert -1 and 2147483647 = 2147483647
		i: -1
		j: 2147483647
		--assert i and j = 2147483647
	--test-- "integer-and9"
		--assert -1 and -2147483647 = -2147483647
		i: -1
		j: -2147483647
		--assert i and j = -2147483647
	--test-- "integer-and10"
		--assert -1 and -2147483648 = -2147483648
		i: -1
		j: -2147483648
		--assert i and j = -2147483648
	--test-- "integer-and11"
		--assert 0 and -1 = 0
		i: 0
		j: -1
		--assert i and j = 0
	--test-- "integer-and12"
		--assert 0 and 0 = 0
		i: 0
		j: 0
		--assert i and j = 0
	--test-- "integer-and13"
		--assert 0 and 1 = 0
		i: 0
		j: 1
		--assert i and j = 0
	--test-- "integer-and14"
		--assert 0 and 255 = 0
		i: 0
		j: 255
		--assert i and j = 0
	--test-- "integer-and15"
		--assert 0 and 256 = 0
		i: 0
		j: 256
		--assert i and j = 0
	--test-- "integer-and16"
		--assert 0 and 65535 = 0
		i: 0
		j: 65535
		--assert i and j = 0
	--test-- "integer-and17"
		--assert 0 and 65536 = 0
		i: 0
		j: 65536
		--assert i and j = 0
	--test-- "integer-and18"
		--assert 0 and 2147483647 = 0
		i: 0
		j: 2147483647
		--assert i and j = 0
	--test-- "integer-and19"
		--assert 0 and -2147483647 = 0
		i: 0
		j: -2147483647
		--assert i and j = 0
	--test-- "integer-and20"
		--assert 0 and -2147483648 = 0
		i: 0
		j: -2147483648
		--assert i and j = 0
	--test-- "integer-and21"
		--assert 1 and -1 = 1
		i: 1
		j: -1
		--assert i and j = 1
	--test-- "integer-and22"
		--assert 1 and 0 = 0
		i: 1
		j: 0
		--assert i and j = 0
	--test-- "integer-and23"
		--assert 1 and 1 = 1
		i: 1
		j: 1
		--assert i and j = 1
	--test-- "integer-and24"
		--assert 1 and 255 = 1
		i: 1
		j: 255
		--assert i and j = 1
	--test-- "integer-and25"
		--assert 1 and 256 = 0
		i: 1
		j: 256
		--assert i and j = 0
	--test-- "integer-and26"
		--assert 1 and 65535 = 1
		i: 1
		j: 65535
		--assert i and j = 1
	--test-- "integer-and27"
		--assert 1 and 65536 = 0
		i: 1
		j: 65536
		--assert i and j = 0
	--test-- "integer-and28"
		--assert 1 and 2147483647 = 1
		i: 1
		j: 2147483647
		--assert i and j = 1
	--test-- "integer-and29"
		--assert 1 and -2147483647 = 1
		i: 1
		j: -2147483647
		--assert i and j = 1
	--test-- "integer-and30"
		--assert 1 and -2147483648 = 0
		i: 1
		j: -2147483648
		--assert i and j = 0
	--test-- "integer-and31"
		--assert 255 and -1 = 255
		i: 255
		j: -1
		--assert i and j = 255
	--test-- "integer-and32"
		--assert 255 and 0 = 0
		i: 255
		j: 0
		--assert i and j = 0
	--test-- "integer-and33"
		--assert 255 and 1 = 1
		i: 255
		j: 1
		--assert i and j = 1
	--test-- "integer-and34"
		--assert 255 and 255 = 255
		i: 255
		j: 255
		--assert i and j = 255
	--test-- "integer-and35"
		--assert 255 and 256 = 0
		i: 255
		j: 256
		--assert i and j = 0
	--test-- "integer-and36"
		--assert 255 and 65535 = 255
		i: 255
		j: 65535
		--assert i and j = 255
	--test-- "integer-and37"
		--assert 255 and 65536 = 0
		i: 255
		j: 65536
		--assert i and j = 0
	--test-- "integer-and38"
		--assert 255 and 2147483647 = 255
		i: 255
		j: 2147483647
		--assert i and j = 255
	--test-- "integer-and39"
		--assert 255 and -2147483647 = 1
		i: 255
		j: -2147483647
		--assert i and j = 1
	--test-- "integer-and40"
		--assert 255 and -2147483648 = 0
		i: 255
		j: -2147483648
		--assert i and j = 0
	--test-- "integer-and41"
		--assert 256 and -1 = 256
		i: 256
		j: -1
		--assert i and j = 256
	--test-- "integer-and42"
		--assert 256 and 0 = 0
		i: 256
		j: 0
		--assert i and j = 0
	--test-- "integer-and43"
		--assert 256 and 1 = 0
		i: 256
		j: 1
		--assert i and j = 0
	--test-- "integer-and44"
		--assert 256 and 255 = 0
		i: 256
		j: 255
		--assert i and j = 0
	--test-- "integer-and45"
		--assert 256 and 256 = 256
		i: 256
		j: 256
		--assert i and j = 256
	--test-- "integer-and46"
		--assert 256 and 65535 = 256
		i: 256
		j: 65535
		--assert i and j = 256
	--test-- "integer-and47"
		--assert 256 and 65536 = 0
		i: 256
		j: 65536
		--assert i and j = 0
	--test-- "integer-and48"
		--assert 256 and 2147483647 = 256
		i: 256
		j: 2147483647
		--assert i and j = 256
	--test-- "integer-and49"
		--assert 256 and -2147483647 = 0
		i: 256
		j: -2147483647
		--assert i and j = 0
	--test-- "integer-and50"
		--assert 256 and -2147483648 = 0
		i: 256
		j: -2147483648
		--assert i and j = 0
	--test-- "integer-and51"
		--assert 65535 and -1 = 65535
		i: 65535
		j: -1
		--assert i and j = 65535
	--test-- "integer-and52"
		--assert 65535 and 0 = 0
		i: 65535
		j: 0
		--assert i and j = 0
	--test-- "integer-and53"
		--assert 65535 and 1 = 1
		i: 65535
		j: 1
		--assert i and j = 1
	--test-- "integer-and54"
		--assert 65535 and 255 = 255
		i: 65535
		j: 255
		--assert i and j = 255
	--test-- "integer-and55"
		--assert 65535 and 256 = 256
		i: 65535
		j: 256
		--assert i and j = 256
	--test-- "integer-and56"
		--assert 65535 and 65535 = 65535
		i: 65535
		j: 65535
		--assert i and j = 65535
	--test-- "integer-and57"
		--assert 65535 and 65536 = 0
		i: 65535
		j: 65536
		--assert i and j = 0
	--test-- "integer-and58"
		--assert 65535 and 2147483647 = 65535
		i: 65535
		j: 2147483647
		--assert i and j = 65535
	--test-- "integer-and59"
		--assert 65535 and -2147483647 = 1
		i: 65535
		j: -2147483647
		--assert i and j = 1
	--test-- "integer-and60"
		--assert 65535 and -2147483648 = 0
		i: 65535
		j: -2147483648
		--assert i and j = 0
	--test-- "integer-and61"
		--assert 65536 and -1 = 65536
		i: 65536
		j: -1
		--assert i and j = 65536
	--test-- "integer-and62"
		--assert 65536 and 0 = 0
		i: 65536
		j: 0
		--assert i and j = 0
	--test-- "integer-and63"
		--assert 65536 and 1 = 0
		i: 65536
		j: 1
		--assert i and j = 0
	--test-- "integer-and64"
		--assert 65536 and 255 = 0
		i: 65536
		j: 255
		--assert i and j = 0
	--test-- "integer-and65"
		--assert 65536 and 256 = 0
		i: 65536
		j: 256
		--assert i and j = 0
	--test-- "integer-and66"
		--assert 65536 and 65535 = 0
		i: 65536
		j: 65535
		--assert i and j = 0
	--test-- "integer-and67"
		--assert 65536 and 65536 = 65536
		i: 65536
		j: 65536
		--assert i and j = 65536
	--test-- "integer-and68"
		--assert 65536 and 2147483647 = 65536
		i: 65536
		j: 2147483647
		--assert i and j = 65536
	--test-- "integer-and69"
		--assert 65536 and -2147483647 = 0
		i: 65536
		j: -2147483647
		--assert i and j = 0
	--test-- "integer-and70"
		--assert 65536 and -2147483648 = 0
		i: 65536
		j: -2147483648
		--assert i and j = 0
	--test-- "integer-and71"
		--assert 2147483647 and -1 = 2147483647
		i: 2147483647
		j: -1
		--assert i and j = 2147483647
	--test-- "integer-and72"
		--assert 2147483647 and 0 = 0
		i: 2147483647
		j: 0
		--assert i and j = 0
	--test-- "integer-and73"
		--assert 2147483647 and 1 = 1
		i: 2147483647
		j: 1
		--assert i and j = 1
	--test-- "integer-and74"
		--assert 2147483647 and 255 = 255
		i: 2147483647
		j: 255
		--assert i and j = 255
	--test-- "integer-and75"
		--assert 2147483647 and 256 = 256
		i: 2147483647
		j: 256
		--assert i and j = 256
	--test-- "integer-and76"
		--assert 2147483647 and 65535 = 65535
		i: 2147483647
		j: 65535
		--assert i and j = 65535
	--test-- "integer-and77"
		--assert 2147483647 and 65536 = 65536
		i: 2147483647
		j: 65536
		--assert i and j = 65536
	--test-- "integer-and78"
		--assert 2147483647 and 2147483647 = 2147483647
		i: 2147483647
		j: 2147483647
		--assert i and j = 2147483647
	--test-- "integer-and79"
		--assert 2147483647 and -2147483647 = 1
		i: 2147483647
		j: -2147483647
		--assert i and j = 1
	--test-- "integer-and80"
		--assert 2147483647 and -2147483648 = 0
		i: 2147483647
		j: -2147483648
		--assert i and j = 0
	--test-- "integer-and81"
		--assert -2147483647 and -1 = -2147483647
		i: -2147483647
		j: -1
		--assert i and j = -2147483647
	--test-- "integer-and82"
		--assert -2147483647 and 0 = 0
		i: -2147483647
		j: 0
		--assert i and j = 0
	--test-- "integer-and83"
		--assert -2147483647 and 1 = 1
		i: -2147483647
		j: 1
		--assert i and j = 1
	--test-- "integer-and84"
		--assert -2147483647 and 255 = 1
		i: -2147483647
		j: 255
		--assert i and j = 1
	--test-- "integer-and85"
		--assert -2147483647 and 256 = 0
		i: -2147483647
		j: 256
		--assert i and j = 0
	--test-- "integer-and86"
		--assert -2147483647 and 65535 = 1
		i: -2147483647
		j: 65535
		--assert i and j = 1
	--test-- "integer-and87"
		--assert -2147483647 and 65536 = 0
		i: -2147483647
		j: 65536
		--assert i and j = 0
	--test-- "integer-and88"
		--assert -2147483647 and 2147483647 = 1
		i: -2147483647
		j: 2147483647
		--assert i and j = 1
	--test-- "integer-and89"
		--assert -2147483647 and -2147483647 = -2147483647
		i: -2147483647
		j: -2147483647
		--assert i and j = -2147483647
	--test-- "integer-and90"
		--assert -2147483647 and -2147483648 = -2147483648
		i: -2147483647
		j: -2147483648
		--assert i and j = -2147483648
	--test-- "integer-and91"
		--assert -2147483648 and -1 = -2147483648
		i: -2147483648
		j: -1
		--assert i and j = -2147483648
	--test-- "integer-and92"
		--assert -2147483648 and 0 = 0
		i: -2147483648
		j: 0
		--assert i and j = 0
	--test-- "integer-and93"
		--assert -2147483648 and 1 = 0
		i: -2147483648
		j: 1
		--assert i and j = 0
	--test-- "integer-and94"
		--assert -2147483648 and 255 = 0
		i: -2147483648
		j: 255
		--assert i and j = 0
	--test-- "integer-and95"
		--assert -2147483648 and 256 = 0
		i: -2147483648
		j: 256
		--assert i and j = 0
	--test-- "integer-and96"
		--assert -2147483648 and 65535 = 0
		i: -2147483648
		j: 65535
		--assert i and j = 0
	--test-- "integer-and97"
		--assert -2147483648 and 65536 = 0
		i: -2147483648
		j: 65536
		--assert i and j = 0
	--test-- "integer-and98"
		--assert -2147483648 and 2147483647 = 0
		i: -2147483648
		j: 2147483647
		--assert i and j = 0
	--test-- "integer-and99"
		--assert -2147483648 and -2147483647 = -2147483648
		i: -2147483648
		j: -2147483647
		--assert i and j = -2147483648
	--test-- "integer-and100"
		--assert -2147483648 and -2147483648 = -2147483648
		i: -2147483648
		j: -2147483648
		--assert i and j = -2147483648
	--test-- "integer-and101"
		--assert -1 and -1 = -1
		i: -1
		j: -1
		--assert i and j = -1
	--test-- "integer-and102"
		--assert 0 and 0 = 0
		i: 0
		j: 0
		--assert i and j = 0
	--test-- "integer-and103"
		--assert 1 and 1 = 1
		i: 1
		j: 1
		--assert i and j = 1
	--test-- "integer-and104"
		--assert 255 and 255 = 255
		i: 255
		j: 255
		--assert i and j = 255
	--test-- "integer-and105"
		--assert 256 and 256 = 256
		i: 256
		j: 256
		--assert i and j = 256
	--test-- "integer-and106"
		--assert 65535 and 65535 = 65535
		i: 65535
		j: 65535
		--assert i and j = 65535
	--test-- "integer-and107"
		--assert 65536 and 65536 = 65536
		i: 65536
		j: 65536
		--assert i and j = 65536
	--test-- "integer-and108"
		--assert 2147483647 and 2147483647 = 2147483647
		i: 2147483647
		j: 2147483647
		--assert i and j = 2147483647
	--test-- "integer-and109"
		--assert -2147483647 and -2147483647 = -2147483647
		i: -2147483647
		j: -2147483647
		--assert i and j = -2147483647
	--test-- "integer-and110"
		--assert -2147483648 and -2147483648 = -2147483648
		i: -2147483648
		j: -2147483648
		--assert i and j = -2147483648

===end-group===

===start-group=== "integer-or"

	--test-- "integer-or1"
		--assert -1 or -1 = -1
		i: -1
		j: -1
		--assert i or j = -1
	--test-- "integer-or2"
		--assert -1 or 0 = -1
		i: -1
		j: 0
		--assert i or j = -1
	--test-- "integer-or3"
		--assert -1 or 1 = -1
		i: -1
		j: 1
		--assert i or j = -1
	--test-- "integer-or4"
		--assert -1 or 255 = -1
		i: -1
		j: 255
		--assert i or j = -1
	--test-- "integer-or5"
		--assert -1 or 256 = -1
		i: -1
		j: 256
		--assert i or j = -1
	--test-- "integer-or6"
		--assert -1 or 65535 = -1
		i: -1
		j: 65535
		--assert i or j = -1
	--test-- "integer-or7"
		--assert -1 or 65536 = -1
		i: -1
		j: 65536
		--assert i or j = -1
	--test-- "integer-or8"
		--assert -1 or 2147483647 = -1
		i: -1
		j: 2147483647
		--assert i or j = -1
	--test-- "integer-or9"
		--assert -1 or -2147483647 = -1
		i: -1
		j: -2147483647
		--assert i or j = -1
	--test-- "integer-or10"
		--assert -1 or -2147483648 = -1
		i: -1
		j: -2147483648
		--assert i or j = -1
	--test-- "integer-or11"
		--assert 0 or -1 = -1
		i: 0
		j: -1
		--assert i or j = -1
	--test-- "integer-or12"
		--assert 0 or 0 = 0
		i: 0
		j: 0
		--assert i or j = 0
	--test-- "integer-or13"
		--assert 0 or 1 = 1
		i: 0
		j: 1
		--assert i or j = 1
	--test-- "integer-or14"
		--assert 0 or 255 = 255
		i: 0
		j: 255
		--assert i or j = 255
	--test-- "integer-or15"
		--assert 0 or 256 = 256
		i: 0
		j: 256
		--assert i or j = 256
	--test-- "integer-or16"
		--assert 0 or 65535 = 65535
		i: 0
		j: 65535
		--assert i or j = 65535
	--test-- "integer-or17"
		--assert 0 or 65536 = 65536
		i: 0
		j: 65536
		--assert i or j = 65536
	--test-- "integer-or18"
		--assert 0 or 2147483647 = 2147483647
		i: 0
		j: 2147483647
		--assert i or j = 2147483647
	--test-- "integer-or19"
		--assert 0 or -2147483647 = -2147483647
		i: 0
		j: -2147483647
		--assert i or j = -2147483647
	--test-- "integer-or20"
		--assert 0 or -2147483648 = -2147483648
		i: 0
		j: -2147483648
		--assert i or j = -2147483648
	--test-- "integer-or21"
		--assert 1 or -1 = -1
		i: 1
		j: -1
		--assert i or j = -1
	--test-- "integer-or22"
		--assert 1 or 0 = 1
		i: 1
		j: 0
		--assert i or j = 1
	--test-- "integer-or23"
		--assert 1 or 1 = 1
		i: 1
		j: 1
		--assert i or j = 1
	--test-- "integer-or24"
		--assert 1 or 255 = 255
		i: 1
		j: 255
		--assert i or j = 255
	--test-- "integer-or25"
		--assert 1 or 256 = 257
		i: 1
		j: 256
		--assert i or j = 257
	--test-- "integer-or26"
		--assert 1 or 65535 = 65535
		i: 1
		j: 65535
		--assert i or j = 65535
	--test-- "integer-or27"
		--assert 1 or 65536 = 65537
		i: 1
		j: 65536
		--assert i or j = 65537
	--test-- "integer-or28"
		--assert 1 or 2147483647 = 2147483647
		i: 1
		j: 2147483647
		--assert i or j = 2147483647
	--test-- "integer-or29"
		--assert 1 or -2147483647 = -2147483647
		i: 1
		j: -2147483647
		--assert i or j = -2147483647
	--test-- "integer-or30"
		--assert 1 or -2147483648 = -2147483647
		i: 1
		j: -2147483648
		--assert i or j = -2147483647
	--test-- "integer-or31"
		--assert 255 or -1 = -1
		i: 255
		j: -1
		--assert i or j = -1
	--test-- "integer-or32"
		--assert 255 or 0 = 255
		i: 255
		j: 0
		--assert i or j = 255
	--test-- "integer-or33"
		--assert 255 or 1 = 255
		i: 255
		j: 1
		--assert i or j = 255
	--test-- "integer-or34"
		--assert 255 or 255 = 255
		i: 255
		j: 255
		--assert i or j = 255
	--test-- "integer-or35"
		--assert 255 or 256 = 511
		i: 255
		j: 256
		--assert i or j = 511
	--test-- "integer-or36"
		--assert 255 or 65535 = 65535
		i: 255
		j: 65535
		--assert i or j = 65535
	--test-- "integer-or37"
		--assert 255 or 65536 = 65791
		i: 255
		j: 65536
		--assert i or j = 65791
	--test-- "integer-or38"
		--assert 255 or 2147483647 = 2147483647
		i: 255
		j: 2147483647
		--assert i or j = 2147483647
	--test-- "integer-or39"
		--assert 255 or -2147483647 = -2147483393
		i: 255
		j: -2147483647
		--assert i or j = -2147483393
	--test-- "integer-or40"
		--assert 255 or -2147483648 = -2147483393
		i: 255
		j: -2147483648
		--assert i or j = -2147483393
	--test-- "integer-or41"
		--assert 256 or -1 = -1
		i: 256
		j: -1
		--assert i or j = -1
	--test-- "integer-or42"
		--assert 256 or 0 = 256
		i: 256
		j: 0
		--assert i or j = 256
	--test-- "integer-or43"
		--assert 256 or 1 = 257
		i: 256
		j: 1
		--assert i or j = 257
	--test-- "integer-or44"
		--assert 256 or 255 = 511
		i: 256
		j: 255
		--assert i or j = 511
	--test-- "integer-or45"
		--assert 256 or 256 = 256
		i: 256
		j: 256
		--assert i or j = 256
	--test-- "integer-or46"
		--assert 256 or 65535 = 65535
		i: 256
		j: 65535
		--assert i or j = 65535
	--test-- "integer-or47"
		--assert 256 or 65536 = 65792
		i: 256
		j: 65536
		--assert i or j = 65792
	--test-- "integer-or48"
		--assert 256 or 2147483647 = 2147483647
		i: 256
		j: 2147483647
		--assert i or j = 2147483647
	--test-- "integer-or49"
		--assert 256 or -2147483647 = -2147483391
		i: 256
		j: -2147483647
		--assert i or j = -2147483391
	--test-- "integer-or50"
		--assert 256 or -2147483648 = -2147483392
		i: 256
		j: -2147483648
		--assert i or j = -2147483392
	--test-- "integer-or51"
		--assert 65535 or -1 = -1
		i: 65535
		j: -1
		--assert i or j = -1
	--test-- "integer-or52"
		--assert 65535 or 0 = 65535
		i: 65535
		j: 0
		--assert i or j = 65535
	--test-- "integer-or53"
		--assert 65535 or 1 = 65535
		i: 65535
		j: 1
		--assert i or j = 65535
	--test-- "integer-or54"
		--assert 65535 or 255 = 65535
		i: 65535
		j: 255
		--assert i or j = 65535
	--test-- "integer-or55"
		--assert 65535 or 256 = 65535
		i: 65535
		j: 256
		--assert i or j = 65535
	--test-- "integer-or56"
		--assert 65535 or 65535 = 65535
		i: 65535
		j: 65535
		--assert i or j = 65535
	--test-- "integer-or57"
		--assert 65535 or 65536 = 131071
		i: 65535
		j: 65536
		--assert i or j = 131071
	--test-- "integer-or58"
		--assert 65535 or 2147483647 = 2147483647
		i: 65535
		j: 2147483647
		--assert i or j = 2147483647
	--test-- "integer-or59"
		--assert 65535 or -2147483647 = -2147418113
		i: 65535
		j: -2147483647
		--assert i or j = -2147418113
	--test-- "integer-or60"
		--assert 65535 or -2147483648 = -2147418113
		i: 65535
		j: -2147483648
		--assert i or j = -2147418113
	--test-- "integer-or61"
		--assert 65536 or -1 = -1
		i: 65536
		j: -1
		--assert i or j = -1
	--test-- "integer-or62"
		--assert 65536 or 0 = 65536
		i: 65536
		j: 0
		--assert i or j = 65536
	--test-- "integer-or63"
		--assert 65536 or 1 = 65537
		i: 65536
		j: 1
		--assert i or j = 65537
	--test-- "integer-or64"
		--assert 65536 or 255 = 65791
		i: 65536
		j: 255
		--assert i or j = 65791
	--test-- "integer-or65"
		--assert 65536 or 256 = 65792
		i: 65536
		j: 256
		--assert i or j = 65792
	--test-- "integer-or66"
		--assert 65536 or 65535 = 131071
		i: 65536
		j: 65535
		--assert i or j = 131071
	--test-- "integer-or67"
		--assert 65536 or 65536 = 65536
		i: 65536
		j: 65536
		--assert i or j = 65536
	--test-- "integer-or68"
		--assert 65536 or 2147483647 = 2147483647
		i: 65536
		j: 2147483647
		--assert i or j = 2147483647
	--test-- "integer-or69"
		--assert 65536 or -2147483647 = -2147418111
		i: 65536
		j: -2147483647
		--assert i or j = -2147418111
	--test-- "integer-or70"
		--assert 65536 or -2147483648 = -2147418112
		i: 65536
		j: -2147483648
		--assert i or j = -2147418112
	--test-- "integer-or71"
		--assert 2147483647 or -1 = -1
		i: 2147483647
		j: -1
		--assert i or j = -1
	--test-- "integer-or72"
		--assert 2147483647 or 0 = 2147483647
		i: 2147483647
		j: 0
		--assert i or j = 2147483647
	--test-- "integer-or73"
		--assert 2147483647 or 1 = 2147483647
		i: 2147483647
		j: 1
		--assert i or j = 2147483647
	--test-- "integer-or74"
		--assert 2147483647 or 255 = 2147483647
		i: 2147483647
		j: 255
		--assert i or j = 2147483647
	--test-- "integer-or75"
		--assert 2147483647 or 256 = 2147483647
		i: 2147483647
		j: 256
		--assert i or j = 2147483647
	--test-- "integer-or76"
		--assert 2147483647 or 65535 = 2147483647
		i: 2147483647
		j: 65535
		--assert i or j = 2147483647
	--test-- "integer-or77"
		--assert 2147483647 or 65536 = 2147483647
		i: 2147483647
		j: 65536
		--assert i or j = 2147483647
	--test-- "integer-or78"
		--assert 2147483647 or 2147483647 = 2147483647
		i: 2147483647
		j: 2147483647
		--assert i or j = 2147483647
	--test-- "integer-or79"
		--assert 2147483647 or -2147483647 = -1
		i: 2147483647
		j: -2147483647
		--assert i or j = -1
	--test-- "integer-or80"
		--assert 2147483647 or -2147483648 = -1
		i: 2147483647
		j: -2147483648
		--assert i or j = -1
	--test-- "integer-or81"
		--assert -2147483647 or -1 = -1
		i: -2147483647
		j: -1
		--assert i or j = -1
	--test-- "integer-or82"
		--assert -2147483647 or 0 = -2147483647
		i: -2147483647
		j: 0
		--assert i or j = -2147483647
	--test-- "integer-or83"
		--assert -2147483647 or 1 = -2147483647
		i: -2147483647
		j: 1
		--assert i or j = -2147483647
	--test-- "integer-or84"
		--assert -2147483647 or 255 = -2147483393
		i: -2147483647
		j: 255
		--assert i or j = -2147483393
	--test-- "integer-or85"
		--assert -2147483647 or 256 = -2147483391
		i: -2147483647
		j: 256
		--assert i or j = -2147483391
	--test-- "integer-or86"
		--assert -2147483647 or 65535 = -2147418113
		i: -2147483647
		j: 65535
		--assert i or j = -2147418113
	--test-- "integer-or87"
		--assert -2147483647 or 65536 = -2147418111
		i: -2147483647
		j: 65536
		--assert i or j = -2147418111
	--test-- "integer-or88"
		--assert -2147483647 or 2147483647 = -1
		i: -2147483647
		j: 2147483647
		--assert i or j = -1
	--test-- "integer-or89"
		--assert -2147483647 or -2147483647 = -2147483647
		i: -2147483647
		j: -2147483647
		--assert i or j = -2147483647
	--test-- "integer-or90"
		--assert -2147483647 or -2147483648 = -2147483647
		i: -2147483647
		j: -2147483648
		--assert i or j = -2147483647
	--test-- "integer-or91"
		--assert -2147483648 or -1 = -1
		i: -2147483648
		j: -1
		--assert i or j = -1
	--test-- "integer-or92"
		--assert -2147483648 or 0 = -2147483648
		i: -2147483648
		j: 0
		--assert i or j = -2147483648
	--test-- "integer-or93"
		--assert -2147483648 or 1 = -2147483647
		i: -2147483648
		j: 1
		--assert i or j = -2147483647
	--test-- "integer-or94"
		--assert -2147483648 or 255 = -2147483393
		i: -2147483648
		j: 255
		--assert i or j = -2147483393
	--test-- "integer-or95"
		--assert -2147483648 or 256 = -2147483392
		i: -2147483648
		j: 256
		--assert i or j = -2147483392
	--test-- "integer-or96"
		--assert -2147483648 or 65535 = -2147418113
		i: -2147483648
		j: 65535
		--assert i or j = -2147418113
	--test-- "integer-or97"
		--assert -2147483648 or 65536 = -2147418112
		i: -2147483648
		j: 65536
		--assert i or j = -2147418112
	--test-- "integer-or98"
		--assert -2147483648 or 2147483647 = -1
		i: -2147483648
		j: 2147483647
		--assert i or j = -1
	--test-- "integer-or99"
		--assert -2147483648 or -2147483647 = -2147483647
		i: -2147483648
		j: -2147483647
		--assert i or j = -2147483647
	--test-- "integer-or100"
		--assert -2147483648 or -2147483648 = -2147483648
		i: -2147483648
		j: -2147483648
		--assert i or j = -2147483648
	--test-- "integer-or101"
		--assert -1 or -1 = -1
		i: -1
		j: -1
		--assert i or j = -1
	--test-- "integer-or102"
		--assert 0 or 0 = 0
		i: 0
		j: 0
		--assert i or j = 0
	--test-- "integer-or103"
		--assert 1 or 1 = 1
		i: 1
		j: 1
		--assert i or j = 1
	--test-- "integer-or104"
		--assert 255 or 255 = 255
		i: 255
		j: 255
		--assert i or j = 255
	--test-- "integer-or105"
		--assert 256 or 256 = 256
		i: 256
		j: 256
		--assert i or j = 256
	--test-- "integer-or106"
		--assert 65535 or 65535 = 65535
		i: 65535
		j: 65535
		--assert i or j = 65535
	--test-- "integer-or107"
		--assert 65536 or 65536 = 65536
		i: 65536
		j: 65536
		--assert i or j = 65536
	--test-- "integer-or108"
		--assert 2147483647 or 2147483647 = 2147483647
		i: 2147483647
		j: 2147483647
		--assert i or j = 2147483647
	--test-- "integer-or109"
		--assert -2147483647 or -2147483647 = -2147483647
		i: -2147483647
		j: -2147483647
		--assert i or j = -2147483647
	--test-- "integer-or110"
		--assert -2147483648 or -2147483648 = -2147483648
		i: -2147483648
		j: -2147483648
		--assert i or j = -2147483648

===end-group===

===start-group=== "integer-xor"

	--test-- "integer-xor1"
		--assert -1 xor -1 = 0
		i: -1
		j: -1
		--assert i xor j = 0
	--test-- "integer-xor2"
		--assert -1 xor 0 = -1
		i: -1
		j: 0
		--assert i xor j = -1
	--test-- "integer-xor3"
		--assert -1 xor 1 = -2
		i: -1
		j: 1
		--assert i xor j = -2
	--test-- "integer-xor4"
		--assert -1 xor 255 = -256
		i: -1
		j: 255
		--assert i xor j = -256
	--test-- "integer-xor5"
		--assert -1 xor 256 = -257
		i: -1
		j: 256
		--assert i xor j = -257
	--test-- "integer-xor6"
		--assert -1 xor 65535 = -65536
		i: -1
		j: 65535
		--assert i xor j = -65536
	--test-- "integer-xor7"
		--assert -1 xor 65536 = -65537
		i: -1
		j: 65536
		--assert i xor j = -65537
	--test-- "integer-xor8"
		--assert -1 xor 2147483647 = -2147483648
		i: -1
		j: 2147483647
		--assert i xor j = -2147483648
	--test-- "integer-xor9"
		--assert -1 xor -2147483647 = 2147483646
		i: -1
		j: -2147483647
		--assert i xor j = 2147483646
	--test-- "integer-xor10"
		--assert -1 xor -2147483648 = 2147483647
		i: -1
		j: -2147483648
		--assert i xor j = 2147483647
	--test-- "integer-xor11"
		--assert 0 xor -1 = -1
		i: 0
		j: -1
		--assert i xor j = -1
	--test-- "integer-xor12"
		--assert 0 xor 0 = 0
		i: 0
		j: 0
		--assert i xor j = 0
	--test-- "integer-xor13"
		--assert 0 xor 1 = 1
		i: 0
		j: 1
		--assert i xor j = 1
	--test-- "integer-xor14"
		--assert 0 xor 255 = 255
		i: 0
		j: 255
		--assert i xor j = 255
	--test-- "integer-xor15"
		--assert 0 xor 256 = 256
		i: 0
		j: 256
		--assert i xor j = 256
	--test-- "integer-xor16"
		--assert 0 xor 65535 = 65535
		i: 0
		j: 65535
		--assert i xor j = 65535
	--test-- "integer-xor17"
		--assert 0 xor 65536 = 65536
		i: 0
		j: 65536
		--assert i xor j = 65536
	--test-- "integer-xor18"
		--assert 0 xor 2147483647 = 2147483647
		i: 0
		j: 2147483647
		--assert i xor j = 2147483647
	--test-- "integer-xor19"
		--assert 0 xor -2147483647 = -2147483647
		i: 0
		j: -2147483647
		--assert i xor j = -2147483647
	--test-- "integer-xor20"
		--assert 0 xor -2147483648 = -2147483648
		i: 0
		j: -2147483648
		--assert i xor j = -2147483648
	--test-- "integer-xor21"
		--assert 1 xor -1 = -2
		i: 1
		j: -1
		--assert i xor j = -2
	--test-- "integer-xor22"
		--assert 1 xor 0 = 1
		i: 1
		j: 0
		--assert i xor j = 1
	--test-- "integer-xor23"
		--assert 1 xor 1 = 0
		i: 1
		j: 1
		--assert i xor j = 0
	--test-- "integer-xor24"
		--assert 1 xor 255 = 254
		i: 1
		j: 255
		--assert i xor j = 254
	--test-- "integer-xor25"
		--assert 1 xor 256 = 257
		i: 1
		j: 256
		--assert i xor j = 257
	--test-- "integer-xor26"
		--assert 1 xor 65535 = 65534
		i: 1
		j: 65535
		--assert i xor j = 65534
	--test-- "integer-xor27"
		--assert 1 xor 65536 = 65537
		i: 1
		j: 65536
		--assert i xor j = 65537
	--test-- "integer-xor28"
		--assert 1 xor 2147483647 = 2147483646
		i: 1
		j: 2147483647
		--assert i xor j = 2147483646
	--test-- "integer-xor29"
		--assert 1 xor -2147483647 = -2147483648
		i: 1
		j: -2147483647
		--assert i xor j = -2147483648
	--test-- "integer-xor30"
		--assert 1 xor -2147483648 = -2147483647
		i: 1
		j: -2147483648
		--assert i xor j = -2147483647
	--test-- "integer-xor31"
		--assert 255 xor -1 = -256
		i: 255
		j: -1
		--assert i xor j = -256
	--test-- "integer-xor32"
		--assert 255 xor 0 = 255
		i: 255
		j: 0
		--assert i xor j = 255
	--test-- "integer-xor33"
		--assert 255 xor 1 = 254
		i: 255
		j: 1
		--assert i xor j = 254
	--test-- "integer-xor34"
		--assert 255 xor 255 = 0
		i: 255
		j: 255
		--assert i xor j = 0
	--test-- "integer-xor35"
		--assert 255 xor 256 = 511
		i: 255
		j: 256
		--assert i xor j = 511
	--test-- "integer-xor36"
		--assert 255 xor 65535 = 65280
		i: 255
		j: 65535
		--assert i xor j = 65280
	--test-- "integer-xor37"
		--assert 255 xor 65536 = 65791
		i: 255
		j: 65536
		--assert i xor j = 65791
	--test-- "integer-xor38"
		--assert 255 xor 2147483647 = 2147483392
		i: 255
		j: 2147483647
		--assert i xor j = 2147483392
	--test-- "integer-xor39"
		--assert 255 xor -2147483647 = -2147483394
		i: 255
		j: -2147483647
		--assert i xor j = -2147483394
	--test-- "integer-xor40"
		--assert 255 xor -2147483648 = -2147483393
		i: 255
		j: -2147483648
		--assert i xor j = -2147483393
	--test-- "integer-xor41"
		--assert 256 xor -1 = -257
		i: 256
		j: -1
		--assert i xor j = -257
	--test-- "integer-xor42"
		--assert 256 xor 0 = 256
		i: 256
		j: 0
		--assert i xor j = 256
	--test-- "integer-xor43"
		--assert 256 xor 1 = 257
		i: 256
		j: 1
		--assert i xor j = 257
	--test-- "integer-xor44"
		--assert 256 xor 255 = 511
		i: 256
		j: 255
		--assert i xor j = 511
	--test-- "integer-xor45"
		--assert 256 xor 256 = 0
		i: 256
		j: 256
		--assert i xor j = 0
	--test-- "integer-xor46"
		--assert 256 xor 65535 = 65279
		i: 256
		j: 65535
		--assert i xor j = 65279
	--test-- "integer-xor47"
		--assert 256 xor 65536 = 65792
		i: 256
		j: 65536
		--assert i xor j = 65792
	--test-- "integer-xor48"
		--assert 256 xor 2147483647 = 2147483391
		i: 256
		j: 2147483647
		--assert i xor j = 2147483391
	--test-- "integer-xor49"
		--assert 256 xor -2147483647 = -2147483391
		i: 256
		j: -2147483647
		--assert i xor j = -2147483391
	--test-- "integer-xor50"
		--assert 256 xor -2147483648 = -2147483392
		i: 256
		j: -2147483648
		--assert i xor j = -2147483392
	--test-- "integer-xor51"
		--assert 65535 xor -1 = -65536
		i: 65535
		j: -1
		--assert i xor j = -65536
	--test-- "integer-xor52"
		--assert 65535 xor 0 = 65535
		i: 65535
		j: 0
		--assert i xor j = 65535
	--test-- "integer-xor53"
		--assert 65535 xor 1 = 65534
		i: 65535
		j: 1
		--assert i xor j = 65534
	--test-- "integer-xor54"
		--assert 65535 xor 255 = 65280
		i: 65535
		j: 255
		--assert i xor j = 65280
	--test-- "integer-xor55"
		--assert 65535 xor 256 = 65279
		i: 65535
		j: 256
		--assert i xor j = 65279
	--test-- "integer-xor56"
		--assert 65535 xor 65535 = 0
		i: 65535
		j: 65535
		--assert i xor j = 0
	--test-- "integer-xor57"
		--assert 65535 xor 65536 = 131071
		i: 65535
		j: 65536
		--assert i xor j = 131071
	--test-- "integer-xor58"
		--assert 65535 xor 2147483647 = 2147418112
		i: 65535
		j: 2147483647
		--assert i xor j = 2147418112
	--test-- "integer-xor59"
		--assert 65535 xor -2147483647 = -2147418114
		i: 65535
		j: -2147483647
		--assert i xor j = -2147418114
	--test-- "integer-xor60"
		--assert 65535 xor -2147483648 = -2147418113
		i: 65535
		j: -2147483648
		--assert i xor j = -2147418113
	--test-- "integer-xor61"
		--assert 65536 xor -1 = -65537
		i: 65536
		j: -1
		--assert i xor j = -65537
	--test-- "integer-xor62"
		--assert 65536 xor 0 = 65536
		i: 65536
		j: 0
		--assert i xor j = 65536
	--test-- "integer-xor63"
		--assert 65536 xor 1 = 65537
		i: 65536
		j: 1
		--assert i xor j = 65537
	--test-- "integer-xor64"
		--assert 65536 xor 255 = 65791
		i: 65536
		j: 255
		--assert i xor j = 65791
	--test-- "integer-xor65"
		--assert 65536 xor 256 = 65792
		i: 65536
		j: 256
		--assert i xor j = 65792
	--test-- "integer-xor66"
		--assert 65536 xor 65535 = 131071
		i: 65536
		j: 65535
		--assert i xor j = 131071
	--test-- "integer-xor67"
		--assert 65536 xor 65536 = 0
		i: 65536
		j: 65536
		--assert i xor j = 0
	--test-- "integer-xor68"
		--assert 65536 xor 2147483647 = 2147418111
		i: 65536
		j: 2147483647
		--assert i xor j = 2147418111
	--test-- "integer-xor69"
		--assert 65536 xor -2147483647 = -2147418111
		i: 65536
		j: -2147483647
		--assert i xor j = -2147418111
	--test-- "integer-xor70"
		--assert 65536 xor -2147483648 = -2147418112
		i: 65536
		j: -2147483648
		--assert i xor j = -2147418112
	--test-- "integer-xor71"
		--assert 2147483647 xor -1 = -2147483648
		i: 2147483647
		j: -1
		--assert i xor j = -2147483648
	--test-- "integer-xor72"
		--assert 2147483647 xor 0 = 2147483647
		i: 2147483647
		j: 0
		--assert i xor j = 2147483647
	--test-- "integer-xor73"
		--assert 2147483647 xor 1 = 2147483646
		i: 2147483647
		j: 1
		--assert i xor j = 2147483646
	--test-- "integer-xor74"
		--assert 2147483647 xor 255 = 2147483392
		i: 2147483647
		j: 255
		--assert i xor j = 2147483392
	--test-- "integer-xor75"
		--assert 2147483647 xor 256 = 2147483391
		i: 2147483647
		j: 256
		--assert i xor j = 2147483391
	--test-- "integer-xor76"
		--assert 2147483647 xor 65535 = 2147418112
		i: 2147483647
		j: 65535
		--assert i xor j = 2147418112
	--test-- "integer-xor77"
		--assert 2147483647 xor 65536 = 2147418111
		i: 2147483647
		j: 65536
		--assert i xor j = 2147418111
	--test-- "integer-xor78"
		--assert 2147483647 xor 2147483647 = 0
		i: 2147483647
		j: 2147483647
		--assert i xor j = 0
	--test-- "integer-xor79"
		--assert 2147483647 xor -2147483647 = -2
		i: 2147483647
		j: -2147483647
		--assert i xor j = -2
	--test-- "integer-xor80"
		--assert 2147483647 xor -2147483648 = -1
		i: 2147483647
		j: -2147483648
		--assert i xor j = -1
	--test-- "integer-xor81"
		--assert -2147483647 xor -1 = 2147483646
		i: -2147483647
		j: -1
		--assert i xor j = 2147483646
	--test-- "integer-xor82"
		--assert -2147483647 xor 0 = -2147483647
		i: -2147483647
		j: 0
		--assert i xor j = -2147483647
	--test-- "integer-xor83"
		--assert -2147483647 xor 1 = -2147483648
		i: -2147483647
		j: 1
		--assert i xor j = -2147483648
	--test-- "integer-xor84"
		--assert -2147483647 xor 255 = -2147483394
		i: -2147483647
		j: 255
		--assert i xor j = -2147483394
	--test-- "integer-xor85"
		--assert -2147483647 xor 256 = -2147483391
		i: -2147483647
		j: 256
		--assert i xor j = -2147483391
	--test-- "integer-xor86"
		--assert -2147483647 xor 65535 = -2147418114
		i: -2147483647
		j: 65535
		--assert i xor j = -2147418114
	--test-- "integer-xor87"
		--assert -2147483647 xor 65536 = -2147418111
		i: -2147483647
		j: 65536
		--assert i xor j = -2147418111
	--test-- "integer-xor88"
		--assert -2147483647 xor 2147483647 = -2
		i: -2147483647
		j: 2147483647
		--assert i xor j = -2
	--test-- "integer-xor89"
		--assert -2147483647 xor -2147483647 = 0
		i: -2147483647
		j: -2147483647
		--assert i xor j = 0
	--test-- "integer-xor90"
		--assert -2147483647 xor -2147483648 = 1
		i: -2147483647
		j: -2147483648
		--assert i xor j = 1
	--test-- "integer-xor91"
		--assert -2147483648 xor -1 = 2147483647
		i: -2147483648
		j: -1
		--assert i xor j = 2147483647
	--test-- "integer-xor92"
		--assert -2147483648 xor 0 = -2147483648
		i: -2147483648
		j: 0
		--assert i xor j = -2147483648
	--test-- "integer-xor93"
		--assert -2147483648 xor 1 = -2147483647
		i: -2147483648
		j: 1
		--assert i xor j = -2147483647
	--test-- "integer-xor94"
		--assert -2147483648 xor 255 = -2147483393
		i: -2147483648
		j: 255
		--assert i xor j = -2147483393
	--test-- "integer-xor95"
		--assert -2147483648 xor 256 = -2147483392
		i: -2147483648
		j: 256
		--assert i xor j = -2147483392
	--test-- "integer-xor96"
		--assert -2147483648 xor 65535 = -2147418113
		i: -2147483648
		j: 65535
		--assert i xor j = -2147418113
	--test-- "integer-xor97"
		--assert -2147483648 xor 65536 = -2147418112
		i: -2147483648
		j: 65536
		--assert i xor j = -2147418112
	--test-- "integer-xor98"
		--assert -2147483648 xor 2147483647 = -1
		i: -2147483648
		j: 2147483647
		--assert i xor j = -1
	--test-- "integer-xor99"
		--assert -2147483648 xor -2147483647 = 1
		i: -2147483648
		j: -2147483647
		--assert i xor j = 1
	--test-- "integer-xor100"
		--assert -2147483648 xor -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i xor j = 0
	--test-- "integer-xor101"
		--assert -1 xor -1 = 0
		i: -1
		j: -1
		--assert i xor j = 0
	--test-- "integer-xor102"
		--assert 0 xor 0 = 0
		i: 0
		j: 0
		--assert i xor j = 0
	--test-- "integer-xor103"
		--assert 1 xor 1 = 0
		i: 1
		j: 1
		--assert i xor j = 0
	--test-- "integer-xor104"
		--assert 255 xor 255 = 0
		i: 255
		j: 255
		--assert i xor j = 0
	--test-- "integer-xor105"
		--assert 256 xor 256 = 0
		i: 256
		j: 256
		--assert i xor j = 0
	--test-- "integer-xor106"
		--assert 65535 xor 65535 = 0
		i: 65535
		j: 65535
		--assert i xor j = 0
	--test-- "integer-xor107"
		--assert 65536 xor 65536 = 0
		i: 65536
		j: 65536
		--assert i xor j = 0
	--test-- "integer-xor108"
		--assert 2147483647 xor 2147483647 = 0
		i: 2147483647
		j: 2147483647
		--assert i xor j = 0
	--test-- "integer-xor109"
		--assert -2147483647 xor -2147483647 = 0
		i: -2147483647
		j: -2147483647
		--assert i xor j = 0
	--test-- "integer-xor110"
		--assert -2147483648 xor -2147483648 = 0
		i: -2147483648
		j: -2147483648
		--assert i xor j = 0

===end-group===

===start-group=== "integer-compare"
 
 	--test-- "integer-compare1"			--assert 0 = 0
	--test-- "integer-compare2"			--assert 1 = 1
	--test-- "integer-compare3"			--assert not (1 = 0)
	--test-- "integer-compare4"			--assert not (2147483647 = -2147483648) 
	--test-- "integer-compare5"			--assert 0 <> 1
	--test-- "integer-compare6"			--assert 0 < 1
	--test-- "integer-compare7"			--assert -2147483648 < 2147483647
	--test-- "integer-compare8"			--assert not (0 < 0)
	--test-- "integer-compare9"			--assert 1 > 0
	--test-- "integer-compare10"		--assert not (-1 > 1)	
	--test-- "integer-compare11"		--assert 1 >= 0
	--test-- "integer-compare12"		--assert 1 >= 1
	--test-- "integer-compare13"		--assert not (1 >= 2)
	--test-- "integer-compare14"		--assert 0 <= 1
	--test-- "integer-compare15"		--assert 0 <= 0
	--test-- "integer-compare16"		--assert not (0 <= -1)
  
===end-group===

~~~end-file~~~

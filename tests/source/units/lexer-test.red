Red [
	Title:   "Red lexer test script"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "lexer"

===start-group=== "transcode"

	--test-- "tr-1"   --assert [123 456 789] == transcode "123 456 789"
	--test-- "tr-2"   --assert ["world" 111] == transcode {"world" 111}
	--test-- "tr-3"   --assert [132 [111] ["world" [456 ["hi"]]] 222] == transcode { 132 [111] ["world" [456 ["hi"]]] 222}
	--test-- "tr-4"   --assert do {[12.34.210.5.66.88 192.168.0.1 [1.0.0 0.0.255]] == transcode "12.34.210.5.66.88 192.168.0.1 [1.0.0 0.0.255]"}
	--test-- "tr-5"   --assert [#"r" #"a" #"^/" #"^/" #"f"] == transcode #{2322722220232261222023225E2F222023225E286C696E6529222023225E2836362922}
	--test-- "tr-6"   --assert [#"r" #"a" #"^/" #"^/" #"f"] == transcode {#"r" #"a" #"^^/" #"^^(line)" #"^^(66)"}
	--test-- "tr-7"   --assert [#r #abcdc /z /abcdef] == transcode {#r #abcdc /z /abcdef}
	--test-- "tr-8"   --assert [[/a] [#a]] == transcode "[/a] [#a]"
	--test-- "tr-9"   --assert [123 456 789 82] == transcode "123 456 789 ;hello^/  82"
	--test-- "tr-10"  --assert [8x5 10x234] == transcode "8x5 10x234 "
	--test-- "tr-11"  --assert [123 2% 34% 98.765% [456] [789 [8]] 34] == transcode "123 2% 34% 98.765% [456] [789 [;hello^/  8]] 34"
	--test-- "tr-12"  --assert [123 (456) (789 (8)) 34] == transcode "123 (456) (789 (;hello^/  8)) 34"
	--test-- "tr-13"  --assert [#"q" #"A"] == transcode { #"q" #"A" }
	--test-- "tr-14"
		out: transcode {a: abc: :a :abc 'a 'abc
			#hello
			#1abc
			[#define]
		}
		--assert out = [a: abc: :a :abc 'a 'abc
			#hello
			#1abc
			[#define]
		]
		nl: reduce [no no no no no no yes yes yes]
		forall out [--assert nl/1 = new-line? out nl: next nl]

	--test-- "tr-15" --assert [#"@" #" " #"^/"] == transcode {#"^^@" #"^^(20)" #"^^(line)" }
	--test-- "tr-16"
		out: transcode {
			#{33AA}
			#{eaFF}
			2#{01100101}
			2#{0110010100001111}
			2#{
				01100101
				00001110
			}
			2#{ ;comment
				01100101 ;ok
				00001111    ;another
			}
		}
		--assert out == [#{33AA} #{EAFF} #{65} #{650F} #{650E} #{650F}]
		forall out [--assert new-line? out --assert binary? out/1]

	--test-- "tr-17"
		out: transcode {
			<img src="my>pic.jpg">
			<a href="index.html">
			<img src="mypic.jpg" width="150" height="200">
			<title>
			<a href="http://www.rebol.com/">
			;<img src='mypi>c.jpg'>
		}
		--assert out == [
		    <img src="my>pic.jpg"> 
		    <a href="index.html"> 
		    <img src="mypic.jpg" width="150" height="200"> 
		    <title> 
		    <a href="http://www.rebol.com/"> 
		    ;<img src='mypi> c.jpg'>
		]
		forall out [--assert tag? out/1]

	--test-- "tr-18"
		out: transcode {
			http://host.dom/path/file
			ftp://host.dom/path/file
			nntp://news.some-isp.net/some.news.group
			mailto:name@domain
			file://host/path/file
			finger://user@host.dom
			whois://rebol@rs.internic.net
			daytime://everest.cclabs.missouri.edu
			pop://user:passwd@host.dom/
			tcp://host.dom:21
			dns://host.dom
		}
		--assert out == [
			http://host.dom/path/file 
			ftp://host.dom/path/file 
			nntp://news.some-isp.net/some.news.group 
			mailto:name@domain 
			file://host/path/file 
			finger://user@host.dom 
			whois://rebol@rs.internic.net 
			daytime://everest.cclabs.missouri.edu 
			pop://user:passwd@host.dom/ 
			tcp://host.dom:21 
			dns://host.dom
		]
		forall out [--assert url? out/1]

	--test-- "tr-18.1"
		out: transcode {
		    john@keats.dom
		    lord@byron.dom
		    edger@guest.dom
		    alfred@tennyson.dom
			info@rebol.com
			123@number-mail.org
			my-name.here@an.example-domain.com
		}
		--assert out == [
		    john@keats.dom 
		    lord@byron.dom 
		    edger@guest.dom 
		    alfred@tennyson.dom 
		    info@rebol.com 
		    123@number-mail.org 
		    my-name.here@an.example-domain.com
		]
		forall out [--assert email? out/1]

	--test-- "tr-19"
		out: transcode {
			%examples.r
			%big-image.jpg
			%graphics/amiga.jpg
			%/c/plug-in/video.r
			%//sound/goldfinger.mp3
			%"this file.txt"
			%"cool movie clip.mpg"
			%this%20file.txt
			%cool%20movie%20clip.mpg
			%dir/file.txt
			%docs/intro.txt
			%docs/new/notes.txt
			%"new mail/inbox.mbx"
			%.
			%./
			%./file.txt
			%..
			%../
			%../script.r
			%../../plans/schedule.r
			%/C/docs/file.txt
			%"/c/program files/qualcomm/eudora mail/out.mbx"
			%//docs/notes
		}
		--assert out == [
		    %examples.r 
		    %big-image.jpg 
		    %graphics/amiga.jpg 
		    %/c/plug-in/video.r 
		    %//sound/goldfinger.mp3 
		    %this%20file.txt 
		    %cool%20movie%20clip.mpg 
		    %this%20file.txt 
		    %cool%20movie%20clip.mpg 
		    %dir/file.txt 
		    %docs/intro.txt 
		    %docs/new/notes.txt 
		    %new%20mail/inbox.mbx 
		    %. 
		    %./ 
		    %./file.txt 
		    %.. 
		    %../ 
		    %../script.r 
		    %../../plans/schedule.r 
		    %/C/docs/file.txt 
		    %/c/program%20files/qualcomm/eudora%20mail/out.mbx 
		    %//docs/notes
		]
		forall out [--assert file? out/1]

	--test-- "tr-20"
		--assert (reduce [true false none none]) == transcode {#[true] #[false] #[none] #[none!]}

	--test-- "tr-21"
		out: transcode {
			26-jan-2019
			26-feb-2019
			26-mar-2019
			26-apr-2019
			26-may-2019
			26-jun-2019
			26-jul-2019
			26-aug-2019
			26-sep-2019
			26-oct-2019
			26-nov-2019
			26-dec-2019
			26-january-2019
			26-february-2019
			26-march-2019
			26-april-2019
			26-may-2019
			26-june-2019
			26-july-2019
			26-august-2019
			26-september-2019
			26-october-2019
			26-november-2019
			26-december-2019
		}
		--assert out == [
		    26-Jan-2019 
		    26-Feb-2019 
		    26-Mar-2019 
		    26-Apr-2019 
		    26-May-2019 
		    26-Jun-2019 
		    26-Jul-2019 
		    26-Aug-2019 
		    26-Sep-2019 
		    26-Oct-2019 
		    26-Nov-2019 
		    26-Dec-2019 
		    26-Jan-2019 
		    26-Feb-2019 
		    26-Mar-2019 
		    26-Apr-2019 
		    26-May-2019 
		    26-Jun-2019 
		    26-Jul-2019 
		    26-Aug-2019 
		    26-Sep-2019 
		    26-Oct-2019 
		    26-Nov-2019 
		    26-Dec-2019
		]
		forall out [--assert date? out/1]

	--test-- "tr-22"
		out: transcode {
			1999-10-5
			1999/10/5
			5-10-1999
			5/10/1999
			5-October-1999
			1999-9-11
			11-9-1999
			5/sep/2012
			5-SEPTEMBER-2012

			02/03/04
			02/03/71

			5/9/2012/6:0
			5/9/2012/6:00
			5/9/2012/6:00+8
			5/9/2012/6:0+0430
			4/Apr/2000/6:00+8:00
			1999-10-2/2:00-4:30
			1/1/1990/12:20:25-6

			2017-07-07T08:22:23+00:00
			2017-07-07T08:22:23Z
			20170707T082223Z
			20170707T0822Z
			20170707T082223+0530

			2017-W01
			2017-W23-5
			2017-W23-5T10:50Z
			2017-001
			2017-153T10:50:00-4:00
		}
		--assert out == [
		    5-Oct-1999 
		    5-Oct-1999 
		    5-Oct-1999 
		    5-Oct-1999 
		    5-Oct-1999 
		    11-Sep-1999 
		    11-Sep-1999 
		    5-Sep-2012 
		    5-Sep-2012 
		    2-Mar-2004 
		    2-Mar-1971 
		    5-Sep-2012/6:00:00 
		    5-Sep-2012/6:00:00 
		    5-Sep-2012/6:00:00+08:00 
		    5-Sep-2012/6:00:00+04:30 
		    4-Apr-2000/6:00:00+08:00 
		    2-Oct-1999/2:00:00-04:30 
		    1-Jan-1990/12:20:25-06:00 
		    7-Jul-2017/8:22:23 
		    7-Jul-2017/8:22:23 
		    7-Jul-2017/8:22:23 
		    7-Jul-2017/8:22:00 
		    7-Jul-2017/8:22:23+05:30 
		    2-Jan-2017 
		    9-Jun-2017 
		    9-Jun-2017/10:50:00 
		    1-Jan-2017 
		    2-Jun-2017/10:50:00-04:00
		]
		forall out [--assert date? out/1]

	--test-- "tr-23"
		out: transcode {
			0:0:3
			0:0:3.12346
			insert
		}
		--assert out = [
		    0:00:03 
		    0:00:03.12346 
		    insert
		]
		--assert time? out/1
		--assert time? out/2
		--assert word? out/3
		forall out [--assert new-line? out]

	--test-- "tr-24" --assert error? try [transcode "#"]
	--test-- "tr-25" --assert error? try [transcode {a: func [][set 'b: 1]}]
	--test-- "tr-26" --assert error? try [transcode "1.2..4"]

	--test-- "tr-27" 
		out: transcode {
			--assert 0:00:15.0 == (10:00.0 % 0:45.0)
		}
		--assert out == [--assert 0:00:15.0 == (10:00.0 % 0:45.0)]

	--test-- "tr-28" --assert error? try [transcode "2hello"]

===end-group===
===start-group=== "transcode/one"
	--test-- "tro-1"  --assert 8		== transcode/one "8"
	--test-- "tro-1.1"  --assert 8		== transcode/one "8 "
	--test-- "tro-2"  --assert 123 		== transcode/one "123"
	--test-- "tro-3"  --assert 123 		== transcode/one " 123 "
	--test-- "tro-4"  --assert 8		== transcode/one " ;hello^/ 8"
	--test-- "tro-5"  --assert 'Hello 	== transcode/one "Hello"
	--test-- "tro-6"  --assert 'Hel我lo	== transcode/one "Hel我lo"
	--test-- "tro-7"  --assert "world"	== transcode/one {"world"}
	--test-- "tro-8"  --assert 1.2.3 	== transcode/one "1.2.3"
	--test-- "tro-10" --assert [1.2.3]	== transcode/one " [1.2.3]"
	--test-- "tro-11" --assert #"z"		== transcode/one {#"z"}
	--test-- "tro-12" --assert #"r"		== transcode/one {#"r"}
	--test-- "tro-13" --assert [#abcde]	== transcode/one "[#abcde]"
	--test-- "tro-14" --assert "ra^/^(line)^(66)^(10123)" == transcode/one #{2272615E2F5E286C696E65295E283636295E2831303132332922}
	--test-- "tro-15" --assert "ra^/^(line)^(66)^(10123)" == transcode/one {"ra^^/^^(line)^^(66)^^(10123)"}
	--test-- "tro-16" --assert "ra^/^(line)^(66)^(12)" == transcode/one {"ra^^/^^(line)^^(66)^^(12)"}
	--test-- "tro-17" --assert "ra^/^(line)^(66)^(1A3)" == transcode/one {"ra^^/^^(line)^^(66)^^(1A3)"}
	--test-- "tro-18" --assert "q^-" == transcode/one {"q^(tab)" }
	--test-- "tro-19" --assert "abc {hfdjhjdh" == transcode/one "{abc ^^{hfdjhjdh}"
	--test-- "tro-20" --assert #"q" == transcode/one {#"q" }
	--test-- "tro-21" --assert 10x234	== transcode/one "10x234"
	--test-- "tro-22" --assert (quote a:) == transcode/one {a: }
	--test-- "tro-23" --assert #{000041} == transcode/one {64#{AABB}}
	--test-- "tro-24" --assert "Hello World!" == to-string transcode/one {64#{SGVsbG8gV29ybGQh}}
	--test-- "tro-25" --assert %hello.red == transcode/one {%hello.red}
	--test-- "tro-26" --assert %hello%20world.red == transcode/one {%"hello world.red"}
	--test-- "tro-27" --assert %hello%20world.red == transcode/one {%hello%20world.red}
	--test-- "tro-28" --assert <img src="mypic.jpg"> == transcode/one {<img src="mypic.jpg">}

	--test-- "tro-29" --assert #{00} == transcode/one "#{00} "
	--test-- "tro-30" --assert #{1234} == transcode/one "#{1234} "
	--test-- "tro-31" --assert #{FFABCD}== transcode/one "#{FFABCD}"
	--test-- "tro-32" --assert #{00112233445566778899AABBCCDDEEFFF01A} == transcode/one "#{00112233445566778899AABBCCDDEEFFF01A}"
	--test-- "tro-33" --assert #{CD} == transcode/one "2#{11001101}"
	--test-- "tro-34" --assert #{CAFEBABE} == transcode/one "16#{CAFEBABE}"
	--test-- "tro-35" --assert #{00004108} == transcode/one "64#{AAB  ^/^-^-BCC==}"
	--test-- "tro-36" --assert "Hello Nice World!" == to-string transcode/one "64#{SGVsbG8gTmljZSBXb3JsZCE=}"

	--test-- "tro-37"
		p: [
			a/b aa/b a/1 a/123 a/123/b a/b/1/d/3 a/(b + 2) a/(b + 2)/c a/(b + 2)/456 
			a/"hi" a/"hi"/456 a/2x3 a/2x3/456 a/2x3/c a/1.234 a/1.234/c
			a/#"b" a/#"b"/c
		]		
		forall p [	
			--assert p/1 == transcode/one mold p/1
			--assert (to set-path! p/1) == transcode/one mold to set-path! p/1
			--assert (to get-path! p/1) == transcode/one mold to get-path! p/1
			--assert (to lit-path! p/1) == transcode/one mold to lit-path! p/1
		]

	--test-- "tro-38" --assert 'a/:b/c == transcode/one {a/:b/c}
	--test-- "tro-39" --assert 26-Oct-2019 == transcode/one "26/10/2019"
	--test-- "tro-40" --assert 26-Oct-2019 == transcode/one "26-10-2019"
	--test-- "tro-41" --assert 26-Oct-2019 == transcode/one "2019/10/26"
	--test-- "tro-42" --assert 26-Oct-2019 == transcode/one "2019-10-26"
	--test-- "tro-43" --assert error? try [transcode/one "2019-10/26"]
	--test-- "tro-44" --assert error? try [transcode/one "2019/10-26"]
	--test-- "tro-45" --assert error? try [transcode/one "26/10-2019"]
	--test-- "tro-46" --assert error? try [transcode/one "26-10/2019"]

	--test-- "tro-47" --assert 26-Oct-2019/13:28:15 == transcode/one "26-October-2019/13:28:15"
	--test-- "tro-48" --assert 26-Oct-2019/13:28:15 == transcode/one "2019/10/26/13:28:15"
	--test-- "tro-49" --assert 13:28 == transcode/one "13:28"
	--test-- "tro-50" --assert 13:28:15 == transcode/one "13:28:15"
	--test-- "tro-5A" 
		out: transcode/one "10:3:01.456"
		--assert out/hour = 10
		--assert out/minute = 3
		--assertf~= out/second 1.456 1E-3

	--test-- "tro-51" --assert 26-Jan-2019 == transcode/one "26-jan-2019"
	--test-- "tro-52" --assert 26-Feb-2019 == transcode/one "26-FEB-2019"
	--test-- "tro-53" --assert 26-Dec-2019 == transcode/one "26/December/2019"
	--test-- "tro-54" --assert 26-Sep-2019 == transcode/one "2019/Sep/26"
	--test-- "tro-55" --assert 2-Oct-1999/2:00:00-04:30 == transcode/one "1999-10-2/2:00-4:30"

	--test-- "tro-56" --assert error? try [transcode/one "#"]
	--test-- "tro-57" --assert error? try [transcode/one "1.2..4"]

	--test-- "tro-58" --assert (quote (b + 2)) == transcode/one"(b + 2)"
	--test-- "tro-59" --assert #() == transcode/one {#()}
	--test-- "tro-60" --assert #(a: 2) == transcode/one {#(a: 2)}
	--test-- "tro-61" --assert #("b" 2.345) == transcode/one {#("b" 2.345)}
	--test-- "tro-62" --assert "hel^/lo" == transcode/one {"hel^^/lo"}
	--test-- "tro-63" --assert "{^/}" == transcode/one {{{^/}}}
	--test-- "tro-64" --assert 1 == transcode/one "01h"
	--test-- "tro-65" --assert 2147483647 == transcode/one "7FFFFFFFh"
	--test-- "tro-66" --assert -1 == transcode/one "FFFFFFFFh"
	


===end-group===
===start-group=== "transcode/next"

	--test-- "tn-1"
		--assert [123 " []hello"] == transcode/next "123 []hello"
		--assert [[] "hello"]     == transcode/next " []hello"
		--assert [hello ""]       == transcode/next "hello"

	--test-- "tn-2"
		--assert [[a] " 123"] == transcode/next "[a] 123"


===end-group===
===start-group=== "transcode/trace"

	logs: make block! 100

	lex-logger: function [
	  event  [word!]
	  input  [string! binary!]
	  type   [datatype! word! none!]
	  line   [integer!]
	  token
	  return:  [logic!]
	][
		t: tail logs
		reduce/into [event to-word type to-word type? type line token] tail logs
		new-line t yes
		any [event <> 'error all [input: next input false]]
	]

	--test-- "tt-1"
		clear logs
		--assert (compose [a: 1 (to-path 'b) []]) == transcode/trace "a: 1 b/ []" :lex-logger
		--assert logs = [
		    scan  set-word! word!     1 1x3
		    load  set-word! datatype! 1 a:
		    scan  integer!  word!     1 4x5
		    load  integer!  datatype! 1 1
		    open  path!     datatype! 1 6x6
		    load  word!     datatype! 1 b
		    close path!     datatype! 1 8x8
		    error error!    datatype! 1 8x8
		    open  block!    datatype! 1 9x9
		    close block!    datatype! 1 10x10
		]

	--test-- "tt-2"
		clear logs
		--assert (compose [a: 1 (to-path 'b) x]) == transcode/trace "a: 1 b/ x" :lex-logger
		--assert logs = [
		    scan  set-word! word!     1 1x3
		    load  set-word! datatype! 1 a:
		    scan  integer!  word!     1 4x5
		    load  integer!  datatype! 1 1
		    open  path!     datatype! 1 6x6
		    load  word!     datatype! 1 b
		    close path!     datatype! 1 8x8
		    error error!    datatype! 1 8x8
		    scan  word!     word!     1 9x10
		    load  word!     datatype! 1 x
		]

	--test-- "tt-3"
		clear logs
		--assert none == transcode/trace "a: 1 #(r: 2) [ x" :lex-logger
		--assert logs = [
		    scan set-word! word! 1 1x3
		    load set-word! datatype! 1 a:
		    scan integer! word! 1 4x5
		    load integer! datatype! 1 1
		    open map! datatype! 1 7x7
		    scan set-word! word! 1 8x10
		    load set-word! datatype! 1 r:
		    scan integer! word! 1 11x12
		    load integer! datatype! 1 2
		    close map! datatype! 1 12x12
		    open block! datatype! 1 14x14
		    scan word! word! 1 16x17
		    load word! datatype! 1 x
		    error error! datatype! 1 14x17
		]

	--test-- "tt-4"
		clear logs
		--assert [a: 1 x] == transcode/trace "a: 1 ) x" :lex-logger
		--assert logs = [
		    scan set-word! word! 1 1x3
		    load set-word! datatype! 1 a:
		    scan integer! word! 1 4x5
		    load integer! datatype! 1 1
		    close paren! datatype! 1 6x6
		    error error! datatype! 1 6x6
		    scan word! word! 1 8x9
		    load word! datatype! 1 x
		]

	--test-- "tt-5"
		clear logs
		--assert [hello 3.14 pi world] == transcode/trace "hello ^/\ 3.14 pi world" :lex-logger
		--assert logs = [
		    scan word! word! 1 1x6
		    load word! datatype! 1 hello
		    error error! datatype! 2 8x8
		    scan float! word! 2 10x14
		    load float! datatype! 2 3.14
		    scan word! word! 2 15x17
		    load word! datatype! 2 pi
		    scan word! word! 2 18x23
		    load word! datatype! 2 world
		]

	--test-- "tt-6"
		clear logs
		--assert [123 "abc" 123456789123.0 test] == transcode/trace "123 {abc} 123456789123 test" :lex-logger
		--assert logs = [
		    scan integer! word! 1 1x4
		    load integer! datatype! 1 123
		    open string! datatype! 1 5x5
		    close string! datatype! 1 6x9
		    scan float! word! 1 11x23
		    load float! datatype! 1 123456789123.0
		    scan word! word! 1 24x28
		    load word! datatype! 1 test
		]

	--test-- "tt-7"
		clear logs
		--assert [a: 1] == transcode/trace "a: 1 ]" :lex-logger
		--assert logs = [
			scan set-word! word! 1 1x3
		    load set-word! datatype! 1 a:
		    scan integer! word! 1 4x5
		    load integer! datatype! 1 1
		    close block! datatype! 1 6x6
		    error error! datatype! 1 6x6
		]

	--test-- "tt-8"	
		lex-filter: function [
			event  [word!]
			input  [string! binary!]
			type   [datatype! word! none!]
			line   [integer!]
			token
			return:  [logic!]
		][
			t: tail logs
			reduce/into [event to-word type to-word type? type line token] tail logs
			new-line t yes
			switch event [
				scan  [yes]
				load  [to-logic find [integer! float! pair!] type]
				open  [no]
				close [no]
			]
		]

		clear logs
		--assert [hello "test" pi world] = transcode/trace "hello ^/123 ^/[^/3x4 {test} 3.14 pi]^/ world" :lex-filter
		--assert logs = [
		    scan word! word! 1 1x6
		    load word! datatype! 1 hello
		    scan integer! word! 2 8x11
		    load integer! datatype! 2 123
		    open block! datatype! 3 13x13
		    scan pair! word! 4 15x18
		    load pair! datatype! 4 3x4
		    open string! datatype! 4 19x19
		    close string! datatype! 4 20x24
		    scan float! word! 4 26x30
		    load float! datatype! 4 3.14
		    scan word! word! 4 31x33
		    load word! datatype! 4 pi
		    close block! datatype! 4 33x33
		    scan word! word! 5 36x41
		    load word! datatype! 5 world
		]


===end-group===

~~~end-file~~~
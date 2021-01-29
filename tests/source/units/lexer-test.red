Red [
	Title:   "Red lexer test script"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer-test.red
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

	--test-- "tr-15" --assert [#"^@" #" " #"^/" #"^@"] == transcode {#"^^@" #"^^(20)" #"^^(line)" #""}
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
		    %"this file.txt"
		    %"cool movie clip.mpg"
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
		]
		forall out [--assert file? out/1]
	
	--test-- "tr-19.1"
		out: transcode {
			@
			@.
			@.:
			@.:;comment
			@/-&!|*~`
			@reference
			@23F323NC3
			@αναφορά
		}
		
		--assert out == [
			@
			@.
			@.:
			@.:
			@/-&!|*~`
			@reference
			@23F323NC3
			@αναφορά
		]
		forall out [--assert ref? out/1]
	
	--test-- "tr-20"
		--assert (reduce [true false none none!]) == transcode {#[true] #[false] #[none] #[none!]}

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

	--test-- "tr-29"
		out: transcode "word<tag>"
		--assert word? out/1
		--assert tag?  out/2

	--test-- "tr-30"
		out: transcode "word</tag>"
		--assert word? out/1
		--assert tag?  out/2

	--test-- "tr-31"
		out: transcode "1 / 3"
		--assert out == [1 / 3]
		--assert word? out/2

	--test-- "tr-32"
		--assert [a] == transcode #{610062}				; a^(NUL)b

	--test-- "tr-33"
		--assert [aa <title> </title>] == out: transcode "aa<title></title>"
		--assert word? out/1
		--assert tag?  out/2
		--assert tag?  out/3

	--test-- "tr-34"
		--assert [<a > 3] == out: transcode "<a > 3"
		--assert tag? out/1
		--assert integer? out/2

	--test-- "tr-35"
		--assert [<a /> 3] == out: transcode "<a /> 3"
		--assert tag? out/1
		--assert integer? out/2

	--test-- "tr-36"
		--assert (compose [3 < (to-word "a>")]) == out: transcode "3 < a>"
		--assert integer? out/1
		--assert word? out/2
		--assert word? out/3

	--test-- "tr-37" --assert [""] == transcode "%{}%"
	--test-- "tr-38" --assert [""] == transcode "%%{}%%"
	--test-- "tr-39" --assert ["a^^b"] == transcode "%{a^^b}%"
	--test-- "tr-40" --assert ["}"] == transcode "%{}}%"
	--test-- "tr-41" --assert ["Nice^^World}% rawstring! "] == transcode "%%{Nice^^World}% rawstring! }%%"
	--test-- "tr-42" --assert [a /c^d /e^] == transcode "a^b/c^^d/e^^^f"
	--test-- "tr-43" --assert [/a /b] == transcode "/a/b"
	--test-- "tr-44" --assert error? try [transcode "[12#(a: 3)]"]
	--test-- "tr-45" --assert [#"a" - #"z"] == transcode {#"a"-#"z"}
	--test-- "tr-46" --assert [/ #a // #a /// #a hello #a + #a - #a] == transcode {/#a //#a ///#a hello#a +#a -#a}
	--test-- "tr-47" --assert error? try [transcode "(#abc:)"]

	--test-- "tr-48" --assert [4294967296.0 6442450943.0 8589934592.0 9999999999] == transcode "4294967296 6442450943 8589934592 9999999999"

	--test-- "tr-49" --assert error? try [transcode #{8B}]

===end-group===
===start-group=== "transcode/one"
	--test-- "tro-1"  --assert 8		== transcode/one "8"
	--test-- "tro-1.1" --assert 8		== transcode/one "8 "
	--test-- "tro-2"  --assert 123 		== transcode/one "123"
	--test-- "tro-2.1" --assert -123 	== transcode/one "-123"
	--test-- "tro-2.2" --assert 123 	== transcode/one "+123"
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
	--test-- "tro-26" --assert {%"hello world.red"} == mold transcode/one {%"hello world.red"}
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

	--test-- "tro-67" --assert word? out: transcode/one "///" 				--assert "///" = mold out
	--test-- "tro-68" --assert word? out: transcode/one "////"				--assert "////" = mold out
	--test-- "tro-69" --assert set-word? out: transcode/one "//////////:"	--assert "//////////:" = mold out
	--test-- "tro-70" --assert lit-word? out: transcode/one "'//////////"	--assert "'//////////" = mold out
	--test-- "tro-71" --assert get-word? out: transcode/one "://////////"	--assert "://////////" = mold out

	--test-- "tro-72" --assert lit-word? out: transcode/one "'//"	--assert "'//" = mold out
	--test-- "tro-73" --assert get-word? out: transcode/one "://"	--assert "://" = mold out
	--test-- "tro-74" --assert set-word? out: transcode/one "//:"	--assert "//:" = mold out
	--test-- "tro-75" --assert word? out: transcode/one "//"		--assert "//"  = mold out
	--test-- "tro-76" --assert word? out: transcode/one "/"			--assert "/"  = mold out
	--test-- "tro-77" --assert lit-word? out: transcode/one "'/"	--assert "'/"  = mold out
	--test-- "tro-78" --assert get-word? out: transcode/one ":/"	--assert ":/"  = mold out
	--test-- "tro-79" --assert set-word? out: transcode/one "/:"	--assert "/:"  = mold out

	--test-- "tro-80" --assert error? try [transcode/one {#"ab"}]

	--test-- "tro-82" --assert 11.22.33 == transcode/one "11.22.33"
	--test-- "tro-83" --assert 255.255.255 == transcode/one "255.255.255"
	--test-- "tro-84" --assert error? try [transcode/one "256.255.255"]
	--test-- "tro-85" --assert error? try [transcode/one "255.255.256"]
	--test-- "tro-86" --assert error? try [transcode/one "255.255.256.0"]
	--test-- "tro-87" --assert error? try [transcode/one "1234.0.0"]
	--test-- "tro-88" --assert 1.2.3.4.5.6.7.8.9.10.11.12 == transcode/one "1.2.3.4.5.6.7.8.9.10.11.12"
	--test-- "tro-89" --assert error? try [transcode/one "1.2.3.4.5.6.7.8.9.10.11.12.13"]

	--test-- "tro-90" --assert error? try [transcode/one {#"^(80)abc"}]
	--test-- "tro-91" --assert error? try [transcode/one {#"^^(80)}]
	--test-- "tro-92" --assert error? try [transcode/one {#"^(80)}]

	--test-- "tro-93" --assert error? try [transcode/one #{3C6100623E}]		; <a^(NUL)b>
	--test-- "tro-94" --assert 'a == transcode/one #{610062}				; a^(NUL)b

	--test-- "tro-95" --assert 2999999999.0 == transcode/one "2999999999"

	--test-- "tro-96"
		--assert (to-word "<<") == out: transcode/one "<<"
		--assert word? :out

	--test-- "tro-97"
		--assert (to-word "<<<") == out: transcode/one "<<<"
		--assert word? :out

	--test-- "tro-98"
		--assert (to-word ">>") == out: transcode/one ">>"
		--assert word? :out

	--test-- "tro-99"
		--assert (to-word ">>>") == out: transcode/one ">>>"
		--assert word? :out

	--test-- "tro-100"
		--assert (to-word "<<<<") == out: transcode/one "<<<<"
		--assert word? :out

	--test-- "tro-101"
		--assert (to-word "<=") == out: transcode/one "<="
		--assert word? :out

	--test-- "tro-102"
		--assert (to-word ">=") == out: transcode/one ">="
		--assert word? :out

	--test-- "tro-103"
		--assert (to-word "<>") == out: transcode/one "<>"
		--assert word? :out

	--test-- "tro-104" --assert 1.0 	== transcode/one "1.0"
	--test-- "tro-105" --assert 123.0 	== transcode/one "123.0"
	--test-- "tro-106" --assert 1.0 	== transcode/one "+1.0"
	--test-- "tro-107" --assert -1.0 	== transcode/one "-1.0"
	--test-- "tro-108" --assert -123.0 	== transcode/one "-123.0"
	--test-- "tro-109" --assert 123.0 	== transcode/one "+123.0"
	--test-- "tro-110" --assert -123.0 	== transcode/one "-123."
	--test-- "tro-111" --assert 123.0 	== transcode/one "123."
	--test-- "tro-112" --assert 0.5 	== transcode/one ".5"

	--test-- "tro-113" --assert error? try [transcode/one "1'''''''''"]
	--test-- "tro-114" --assert error? try [transcode/one "1''''''''''"]
	--test-- "tro-115" --assert error? try [transcode/one "1'''''''''''"]
	--test-- "tro-116" --assert error? try [transcode/one "1'"]
	--test-- "tro-117" --assert error? try [transcode/one "1''2"]

	--test-- "tro-118" --assert error? try [transcode/one "+$.1"]
	--test-- "tro-119" --assert error? try [transcode/one "-10h"]
	--test-- "tro-120" --assert error? try [transcode/one "1'0000h"]
	--test-- "tro-121" --assert error? try [transcode/one "$1234.'56'7'8''9'"]
	--test-- "tro-122" --assert error? try [transcode/one "$10'000.'''0''0'"]

	--test-- "tro-123" --assert -123x456 = transcode/one "-123x456"
	--test-- "tro-124" --assert 123x-456 = transcode/one "123x-456"
	--test-- "tro-125" --assert  123x456 = transcode/one "+123x456"
	--test-- "tro-126" --assert  123x456 = transcode/one "123x+456"

	--test-- "tro-127" --assert #{BADFACE0} = transcode/one "#{BADFACE0}"
	--test-- "tro-128" --assert error? try [transcode/one "#{BADFACE}"]

	--test-- "tro-129" --assert 29/02/2020 = transcode/one "29/02/2020"
	--test-- "tro-130" --assert error? try [transcode/one "30/02/2020"]

	--test-- "tro-131"  --assert 100000000	== transcode/one "100'000'000"
	--test-- "tro-132"  --assert 100000000	== transcode/one "1'00'000'000"
	--test-- "tro-133"  --assert 1000000000	== transcode/one "1'000'000'000"
	--test-- "tro-134"  --assert 1000000000	== transcode/one "1000000000"

	--test-- "tro-135"  --assert 100000000	== transcode/one "+100'000'000"
	--test-- "tro-136"  --assert 100000000	== transcode/one "+1'00'000'000"
	--test-- "tro-137"  --assert 1000000000	== transcode/one "+1'000'000'000"
	--test-- "tro-138"  --assert 1000000000	== transcode/one "+1000000000"

	--test-- "tro-139"  --assert -100000000	== transcode/one "-100'000'000"
	--test-- "tro-140"  --assert -100000000	== transcode/one "-1'00'000'000"
	--test-- "tro-141"  --assert -1000000000 == transcode/one "-1'000'000'000"
	--test-- "tro-142"  --assert -1000000000 == transcode/one "-1000000000"

	--test-- "tro-143"  --assert #"^@" == transcode/one {#""}
	--test-- "tro-144"  --assert error? try [transcode/one {"hello^/world"}]
	--test-- "tro-145"  --assert "hello^Mworld" == transcode/one {"hello^Mworld"}
	--test-- "tro-146"  --assert "hello^-world" == transcode/one {"hello^-world"}

	--test-- "tro-147"  --assert -12:02:00 == transcode/one "-12:2"
	--test-- "tro-148"  --assert  12:02:00 == transcode/one "+12:2"

	--test-- "tro-149"  --assert error? try [transcode/one {12#""}]
	--test-- "tro-150"  --assert error? try [transcode/one {16#"1"}]
	--test-- "tro-151"  --assert error? try [transcode/one {16#"12"}]

	--test-- "tro-152"  --assert error? try [transcode/one "/v:"]
	--test-- "tro-153"  --assert error? try [transcode/one "/v:"]
	--test-- "tro-154"  --assert error? try [transcode/one "/value:"]
	--test-- "tro-155"  --assert error? try [type? transcode/one "/value:"]

	--test-- "tro-156"  --assert -00:01:00 == transcode/one "-0:1"
	--test-- "tro-157"  --assert -01:00:00 == transcode/one "-1:0"
	--test-- "tro-158"  --assert error? try [transcode/one "#abc:"]
	--test-- "tro-159"  --assert error? try [transcode/one ":x:"]
	--test-- "tro-160"  --assert error? try [transcode/one ":x::"]
	--test-- "tro-161"  --assert error? try [transcode/one "1:2:"]
	--test-- "tro-162"  --assert error? try [transcode/one "'a/b:"]
	--test-- "tro-163"  --assert error? try [transcode/one ":a/b:"]
	--test-- "tro-164"  --assert error? try [transcode/one "123#"]
	--test-- "tro-165"  --assert error? try [transcode/one "9h"]
	--test-- "tro-166"  --assert error? try [transcode/one "FACEFEEDDEADBEEFh"]

===end-group===
===start-group=== "transcode/next"

	--test-- "tn-1"
		--assert [123 " []hello"] == transcode/next "123 []hello"
		--assert [[] "hello"]     == transcode/next " []hello"
		--assert [hello ""]       == transcode/next "hello"

	--test-- "tn-2"
		--assert [[a] " 123"] == transcode/next "[a] 123"

	--test-- "tn-3"
		--assert [#(a: 4) " hello"] == out: transcode/next "#(a: 4) hello"
		--assert map? out/1

===end-group===
===start-group=== "transcode/into"

	--test-- "ti-1"
		out: make block! 1 
		--assert [123] == transcode/into "123" out
		--assert [123] == out

	--test-- "ti-2"
		out: [] 
		--assert [456] == transcode/into "456" out
		--assert [456] == out
		
	--test-- "ti-3"
		out: make block! 1
		--assert [789 456 123] == transcode/into "789 456 123" out
		--assert [789 456 123] == out

	--test-- "ti-4"
		out: tail [a b c]
		--assert [789 456 123] == transcode/into "789 456 123" out
		--assert [789 456 123] == out
		--assert [a b c 789 456 123] == head out

===end-group===

===start-group=== "scan"

	--test-- "scan-1"  --assert (reduce [integer! " hello"]) == scan/next "123 hello"
	--test-- "scan-2"  --assert (reduce [block!	  " hello"]) == scan/next "[test] hello"

	--test-- "scan-3"  --assert (reduce [percent! " hello"]) == scan/next "123% hello"
	--test-- "scan-4"  --assert (reduce [integer! " hello"]) == scan/next "123h hello"
	--test-- "scan-5"  --assert (reduce [tag!	  " hello"]) == scan/next "<p> hello"
	--test-- "scan-6"  --assert (reduce [char!	  " hello"]) == scan/next {#"p" hello}
	--test-- "scan-7"  --assert (reduce [binary!  " hello"]) == scan/next {#{23} hello}
	--test-- "scan-8"  --assert (reduce [string!  " hello"]) == scan/next {"world" hello}

	--test-- "scan-9"  --assert (reduce [set-word! " hello"]) == scan/next "a: hello"
	--test-- "scan-10" --assert (reduce [word! 	   " hello"]) == scan/next "a hello"
	--test-- "scan-11" --assert (reduce [lit-word! " hello"]) == scan/next "'a hello"
	--test-- "scan-12" --assert (reduce [get-word! " hello"]) == scan/next ":a hello"

	--test-- "scan-13" --assert (reduce [map!	   " hello"]) == scan/next "#(a: 4) hello"
	--test-- "scan-14" --assert (reduce [set-path! " hello"]) == scan/next "a/b: hello"
	--test-- "scan-15" --assert (reduce [path! 	   " hello"]) == scan/next "a/b hello"
	--test-- "scan-16" --assert (reduce [lit-path! " hello"]) == scan/next "'a/b hello"
	--test-- "scan-17" --assert (reduce [get-path! " hello"]) == scan/next ":a/b hello"

	--test-- "scan-18" --assert word! = scan "///"
	--test-- "scan-19" --assert word! =  scan "////"
	--test-- "scan-20" --assert set-word! =  scan "//////////:"
	--test-- "scan-21" --assert lit-word! =  scan "'//////////"
	--test-- "scan-22" --assert get-word! =  scan "://////////"

	--test-- "scan-23"
		allow: ["1.2" "123.456789" "123." "123." ".1" "1e2" "+1.0" "-1.0" "+1e2" "-1.0e2" "123.e1"]
		deny:  ["123.." "123.e" "123e" "123E" "1e" "1E" "1e." "-1e" "-1e."]
		foreach s allow [--test-- s --assert float! = scan s]
		foreach s deny  [--test-- s --assert error! = scan s]

	--test-- "scan-24" --assert error! = scan "1/2/12io23"
	--test-- "scan-25" --assert float! = scan "2999999999"

	--test-- "scan-26" --assert error! = scan "["
	--test-- "scan-27" --assert error! = scan "]"
	--test-- "scan-28" --assert error! = scan "("
	--test-- "scan-29" --assert error! = scan ")"
	--test-- "scan-30" --assert error! = scan "#("
	--test-- "scan-31" --assert error! = scan "{"
	--test-- "scan-32" --assert error! = scan "}"
	--test-- "scan-33" --assert block! = scan "[]"
	--test-- "scan-34" --assert paren! = scan "()"
	--test-- "scan-35" --assert map!   = scan "#()"
	--test-- "scan-36" --assert string! = scan "{}"
	--test-- "scan-37" --assert string! = scan {""}
	--test-- "scan-38" --assert word!   = scan "a"
	--test-- "scan-39" --assert error!   = scan "[a"
	--test-- "scan-40" --assert error!   = scan "(a"
	--test-- "scan-41" --assert block!   = scan "[a]"
	--test-- "scan-42" --assert paren!   = scan "(a)"
	--test-- "scan-43" --assert block!   = scan "[a 123]"
	--test-- "scan-44" --assert paren!   = scan "(a 123)"
	--test-- "scan-45" --assert integer! = scan "123"
	--test-- "scan-46" --assert integer! = scan "-123"
	--test-- "scan-47" --assert float! 	 = scan "1.0"
	--test-- "scan-48" --assert float! 	 = scan "123.0"
	--test-- "scan-49" --assert float! 	 = scan "+1.0"
	--test-- "scan-50" --assert float! 	 = scan "-1.0"
	--test-- "scan-51" --assert float! 	 = scan "-123.0"
	--test-- "scan-52" --assert float! 	 = scan "+123.0"
	--test-- "scan-53" --assert float! 	 = scan "-123."
	--test-- "scan-54" --assert float! 	 = scan "123."
	--test-- "scan-55" --assert float!	 = scan ".5"
	--test-- "scan-56" --assert binary!	 = scan "#{BADFACE0}"
	--test-- "scan-57" --assert error!	 = scan "#{BADFACE}"
	--test-- "scan-58" --assert date!	 = scan "29/02/2020"
	--test-- "scan-59" --assert error!	 = scan "30/02/2020"
	--test-- "scan-60" --assert none? 	   scan ""
	--test-- "scan-61" --assert char!	 = scan {#""}
	--test-- "scan-62" --assert error!	 = scan {"hello^/world"}
	--test-- "scan-63" --assert string!	 = scan {"hello^Mworld"}
	--test-- "scan-64" --assert string!	 = scan {"hello^-world"}
	--test-- "scan-65" --assert error!	 = scan "a/ "
	--test-- "scan-66" --assert logic!	 = scan "#[true]"
	--test-- "scan-67" --assert logic!	 = scan "#[false]"
	--test-- "scan-68" --assert none!	 = scan "#[none]"
	--test-- "scan-69" --assert integer! = scan "#[integer!]"
	--test-- "scan-70" --assert error!	 = scan "#[int!]"
	--test-- "scan-71" --assert error!   = scan "/v:"
	--test-- "scan-72" --assert error!   = scan "/value:"
	--test-- "scan-73" --assert error!   = scan "$non"
	--test-- "scan-74" --assert error!   = scan "\non"
	--test-- "scan-75" --assert error!   = scan ":x:"
	--test-- "scan-76" --assert error!   = scan ":x::"

	--test-- "scan-77" --assert [#[none] ""] == scan/next " "
	--test-- "scan-78" --assert none? scan/next ""
	--test-- "scan-79" --assert error!   = scan "1:2:"
	--test-- "scan-80" --assert error!   = scan "123#"
	--test-- "scan-81" --assert error!   = scan "9h"
	--test-- "scan-82" --assert error!   = scan "FACEFEEDDEADBEEFh"
	--test-- "scan-83" --assert error!   = scan ":a/b:"

===end-group===
===start-group=== "scan/fast"

	--test-- "scan-f1" --assert word!    = scan/fast "a"
	--test-- "scan-f2" --assert error!   = scan/fast "["
	--test-- "scan-f3" --assert error!   = scan/fast "]"
	--test-- "scan-f4" --assert error!   = scan/fast "("
	--test-- "scan-f5" --assert error!   = scan/fast ")"
	--test-- "scan-f6" --assert error!   = scan/fast "#("
	--test-- "scan-f7" --assert error!   = scan/fast "{"
	--test-- "scan-f8" --assert error!   = scan/fast "}"
	--test-- "scan-f9" --assert block!   = scan/fast "[]"
	--test-- "scan-f10" --assert paren!  = scan/fast "()"
	--test-- "scan-f11" --assert map!    = scan/fast "#()"
	--test-- "scan-f12" --assert string! = scan/fast "{}"
	--test-- "scan-f13" --assert string! = scan/fast {""}
	--test-- "scan-f14" --assert word!   = scan/fast "'a"
	--test-- "scan-f15" --assert word!   = scan/fast ":a"
	--test-- "scan-f16" --assert word!   = scan/fast "a:"

	--test-- "scan-f39" --assert error!   = scan/fast "[a"
	--test-- "scan-f40" --assert error!   = scan/fast "(a"
	--test-- "scan-f41" --assert block!   = scan/fast "[a]"
	--test-- "scan-f42" --assert paren!   = scan/fast "(a)"
	--test-- "scan-f43" --assert block!   = scan/fast "[a 123]"
	--test-- "scan-f44" --assert paren!   = scan/fast "(a 123)"
	--test-- "scan-f45" --assert integer! = scan/fast "123"
	--test-- "scan-f46" --assert integer! = scan/fast "-123"
	--test-- "scan-f47" --assert float!   = scan/fast "1.0"
	--test-- "scan-f48" --assert float!	  = scan/fast "123.0"
	--test-- "scan-f49" --assert float!	  = scan/fast "+1.0"
	--test-- "scan-f50" --assert float!   = scan/fast "-1.0"
	--test-- "scan-f51" --assert float!   = scan/fast "-123.0"
	--test-- "scan-f52" --assert float!   = scan/fast "+123.0"
	--test-- "scan-f53" --assert float!   = scan/fast "-123."
	--test-- "scan-f54" --assert float!   = scan/fast "123."
	--test-- "scan-f55" --assert float!	  = scan/fast ".5"
	--test-- "scan-f56" --assert none? 	    scan/fast ""
	--test-- "scan-f57" --assert error!	  = scan/fast "a/ "
	--test-- "scan-f58" --assert logic!	  = scan/fast "#[true]"
	--test-- "scan-f59" --assert logic!	  = scan/fast "#[false]"
	--test-- "scan-f60" --assert none!	  = scan/fast "#[none]"
	--test-- "scan-f61" --assert integer! = scan/fast "#[integer!]"
	--test-- "scan-f62" --assert error!	  = scan/fast "#[int!]"
	--test-- "scan-f63" --assert error!   = scan/fast "/v:"
	--test-- "scan-f64" --assert error!   = scan/fast "/value:"
	--test-- "scan-f65" --assert path!    = scan/fast "a/b"
	--test-- "scan-f66" --assert lit-path! = scan/fast "'a/b"
	--test-- "scan-f67" --assert set-path! = scan/fast "a/b:"
	--test-- "scan-f68" --assert get-path! = scan/fast ":a/b"

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

	lex-filtered-logger: function [
	  event  [word!]
	  input  [string! binary!]
	  type   [datatype! word! none!]
	  line   [integer!]
	  token
	  return:  [logic!]
	][
		[load error]
		t: tail logs
		reduce/into [event to-word type to-word type? type line token] tail logs
		new-line t yes
		any [event <> 'error all [input: next input false]]
	]

	--test-- "tt-1"
		clear logs
		--assert (compose [a: 1 (to-path 'b) []]) == transcode/trace "a: 1 b/ []" :lex-logger
		--assert logs = [
			prescan word! datatype! 1 1x3
			scan set-word! datatype! 1 1x3
			load set-word! datatype! 1 a:
			prescan integer! datatype! 1 4x5
			scan integer! datatype! 1 4x5
			load integer! datatype! 1 1
			prescan path! datatype! 1 6x7
			open path! datatype! 1 6x6
			scan word! datatype! 1 6x7
			load word! datatype! 1 b
			prescan error! datatype! 1 8x8
			error path! datatype! 1 6x8
			prescan block! datatype! 1 9x9
			open block! datatype! 1 9x9
			prescan block! datatype! 1 10x10
			close block! datatype! 1 10x10
		]

	--test-- "tt-2"
		clear logs
		--assert (compose [a: 1 (to-path 'b) x]) == transcode/trace "a: 1 b/ x" :lex-logger
		--assert logs = [
			prescan word! datatype! 1 1x3
			scan set-word! datatype! 1 1x3
			load set-word! datatype! 1 a:
			prescan integer! datatype! 1 4x5
			scan integer! datatype! 1 4x5
			load integer! datatype! 1 1
			prescan path! datatype! 1 6x7
			open path! datatype! 1 6x6
			scan word! datatype! 1 6x7
			load word! datatype! 1 b
			prescan error! datatype! 1 8x8
			error path! datatype! 1 6x8
			prescan word! datatype! 1 9x10
			scan word! datatype! 1 9x10
			load word! datatype! 1 x
		]

	--test-- "tt-3"
		clear logs
		--assert none == transcode/trace "a: 1 #(r: 2) [ x" :lex-logger
		--assert logs = [
		    prescan word! datatype! 1 1x3
			scan set-word! datatype! 1 1x3
			load set-word! datatype! 1 a:
			prescan integer! datatype! 1 4x5
			scan integer! datatype! 1 4x5
			load integer! datatype! 1 1
			prescan map! datatype! 1 6x7
			open map! datatype! 1 6x7
			prescan word! datatype! 1 8x10
			scan set-word! datatype! 1 8x10
			load set-word! datatype! 1 r:
			prescan integer! datatype! 1 11x12
			scan integer! datatype! 1 11x12
			load integer! datatype! 1 2
			prescan paren! datatype! 1 12x12
			close map! datatype! 1 12x12
			prescan block! datatype! 1 14x14
			open block! datatype! 1 14x14
			prescan word! datatype! 1 16x17
			scan word! datatype! 1 16x17
			load word! datatype! 1 x
			error block! datatype! 1 14x17
		]

	--test-- "tt-4"
		clear logs
		--assert [a: 1 x] == transcode/trace "a: 1 ) x" :lex-logger
		--assert logs = [
		    prescan word! datatype! 1 1x3
			scan set-word! datatype! 1 1x3
			load set-word! datatype! 1 a:
			prescan integer! datatype! 1 4x5
			scan integer! datatype! 1 4x5
			load integer! datatype! 1 1
			prescan paren! datatype! 1 6x6
			close paren! datatype! 1 6x6
			error paren! datatype! 1 6x6
			prescan word! datatype! 1 8x9
			scan word! datatype! 1 8x9
			load word! datatype! 1 x
		]

	--test-- "tt-5"
		clear logs
		--assert [hello 3.14 pi world] == transcode/trace "hello ^/\ 3.14 pi world" :lex-logger	
		--assert logs = [
		    prescan word! datatype! 1 1x6
			scan word! datatype! 1 1x6
			load word! datatype! 1 hello
			prescan error! datatype! 2 8x8
			error error! datatype! 2 8x8
			prescan float! datatype! 2 10x14
			scan float! datatype! 2 10x14
			load float! datatype! 2 3.14
			prescan word! datatype! 2 15x17
			scan word! datatype! 2 15x17
			load word! datatype! 2 pi
			prescan word! datatype! 2 18x23
			scan word! datatype! 2 18x23
			load word! datatype! 2 world
		]

	--test-- "tt-6"
		clear logs
		--assert [123 "abc" 123456789123.0 test] == transcode/trace "123 {abc} 123456789123 test" :lex-logger
		--assert logs = [
		    prescan integer! datatype! 1 1x4
			scan integer! datatype! 1 1x4
			load integer! datatype! 1 123
			prescan string! datatype! 1 5x5
			open string! datatype! 1 5x5
			close string! datatype! 1 5x9
			scan string! datatype! 1 5x9 
    		load string! datatype! 1 "abc" 
			prescan integer! datatype! 1 11x23
			scan float! datatype! 1 11x23
			load float! datatype! 1 123456789123.0
			prescan word! datatype! 1 24x28
			scan word! datatype! 1 24x28
			load word! datatype! 1 test
		]

	--test-- "tt-7"
		clear logs
		--assert [a: 1] == transcode/trace "a: 1 ]" :lex-logger
		--assert logs = [
			prescan word! datatype! 1 1x3
			scan set-word! datatype! 1 1x3
			load set-word! datatype! 1 a:
			prescan integer! datatype! 1 4x5
			scan integer! datatype! 1 4x5
			load integer! datatype! 1 1
			prescan block! datatype! 1 6x6
			close block! datatype! 1 6x6
			error block! datatype! 1 6x6
		]

	--test-- "tt-8"	
		lex-filter: function [
			event  [word!]
			input  [string! binary!]
			type   [datatype! word! none!]
			line   [integer!]
			token
			return: [logic!]
		][
			t: tail logs
			reduce/into [event to-word type to-word type? type line token] tail logs
			new-line t yes
			switch event [
				prescan
				scan  [yes]
				load  [to-logic find [integer! float! pair!] type]
				open
				close [no]
			]
		]

		clear logs
		--assert [hello "test" pi world] = transcode/trace "hello ^/123 ^/[^/3x4 {test} 3.14 pi]^/ world" :lex-filter
		--assert logs = [
			prescan word! datatype! 1 1x6
			scan word! datatype! 1 1x6
			load word! datatype! 1 hello
			prescan integer! datatype! 2 8x11
			scan integer! datatype! 2 8x11
			load integer! datatype! 2 123
			prescan block! datatype! 3 13x13
			open block! datatype! 3 13x13
			prescan pair! datatype! 4 15x18
			scan pair! datatype! 4 15x18
			load pair! datatype! 4 3x4
			prescan string! datatype! 4 19x19
			open string! datatype! 4 19x19
			close string! datatype! 4 19x24
			scan string! datatype! 4 19x24 
    		load string! datatype! 4 "test"
			prescan float! datatype! 4 26x30
			scan float! datatype! 4 26x30
			load float! datatype! 4 3.14
			prescan word! datatype! 4 31x33
			scan word! datatype! 4 31x33
			load word! datatype! 4 pi
			prescan block! datatype! 4 33x33
			close block! datatype! 4 33x33
			prescan word! datatype! 5 36x41
			scan word! datatype! 5 36x41
			load word! datatype! 5 world
		]

	--test-- "tt-9"	
		--assert error? try [transcode/trace "a: 3 t/" func [e i t l o][true]]

	--test-- "tt-10"
		lex-filter10: function [
			event  [word!]
			input  [string! binary!]
			type   [datatype! word! none!]
			line   [integer!]
			token
			return: [logic!]
		][
			t: tail logs
			reduce/into [event to-word type to-word type? type line token] tail logs
			new-line t yes
			--assert 456 == load "456"
			--assert [[456] world] == load "[456] world"
			yes
		]
		clear logs
		--assert [123 abc] == transcode/trace "123 abc" :lex-filter10
		--assert logs = [
			prescan integer! datatype! 1 1x4
			scan integer! datatype! 1 1x4
			load integer! datatype! 1 123
			prescan word! datatype! 1 5x8
			scan word! datatype! 1 5x8
			load word! datatype! 1 abc
		]

	--test-- "tt-11"
		lex-filter11B: function [
			event  [word!]
			input  [string! binary!]
			type   [datatype! word! none!]
			line   [integer!]
			token
			return: [logic!]
		][
			--assert 456 == load "456"
			--assert [[456] world] == load "[456] world"
			yes
		]
		lex-filter11A: function [
			event  [word!]
			input  [string! binary!]
			type   [datatype! word! none!]
			line   [integer!]
			token
			return: [logic!]
		][
			t: tail logs
			reduce/into [event to-word type to-word type? type line token] tail logs
			new-line t yes
			--assert 789 == load "789"
			--assert [[789] world] == load "[789] world"
			--assert [123 abc] == transcode/trace "123 abc" :lex-filter11B
			yes
		]
		clear logs
		--assert [123 abc] == transcode/trace "123 abc" :lex-filter11A
		--assert logs = [
			prescan integer! datatype! 1 1x4
			scan integer! datatype! 1 1x4
			load integer! datatype! 1 123
			prescan word! datatype! 1 5x8
			scan word! datatype! 1 5x8
			load word! datatype! 1 abc
		]

	--test-- "tt-12"
		clear logs
		--assert none == transcode/trace "a: 1 #(r: 2) [ x" :lex-filtered-logger
		--assert logs = [
			load set-word! datatype! 1 a:
			load integer! datatype! 1 1
			load set-word! datatype! 1 r:
			load integer! datatype! 1 2
			load word! datatype! 1 x
			error block! datatype! 1 14x17
		]

	--test-- "tt-13"
		lex-filter13: function [
			event  [word!]
			input  [string! binary!]
			type   [datatype! word! none!]
			line   [integer!]
			token
			return: [logic!]
		][
			[load open close]
			t: tail logs
			reduce/into [event to-word type to-word type? type line token] tail logs
			new-line t yes
			switch event [
				load  [to-logic find [integer! float! pair!] type]
				open
				close [no]
			]
		]

		clear logs
		--assert [hello "test" pi world] = transcode/trace "hello ^/123 ^/[^/3x4 {test} 3.14 pi]^/ world" :lex-filter13
		--assert logs = [
			load word! datatype! 1 hello
			load integer! datatype! 2 123
			open block! datatype! 3 13x13
			load pair! datatype! 4 3x4
			open string! datatype! 4 19x19
			close string! datatype! 4 19x24
			load string! datatype! 4 "test" 
			load float! datatype! 4 3.14
			load word! datatype! 4 pi
			close block! datatype! 4 33x33
			load word! datatype! 5 world
		]

	--test-- "tt-14"
		lex-filter14: function [
			event  [word!]
			input  [string! binary!]
			type   [datatype! word! none!]
			line   [integer!]
			token
			return: [logic!]
		][
			t: tail logs
			reduce/into [event to-word type to-word type? type line token] tail logs
			new-line t yes
			if event = 'error [input: next input return false]
			true
		]

		clear logs
		--assert none? transcode/trace "a: [b/c/ d/e" :lex-filter14
		--assert logs = [
		    prescan word! datatype! 1 1x3
		    scan set-word! datatype! 1 1x3
		    load set-word! datatype! 1 a:
		    prescan block! datatype! 1 4x4
		    open block! datatype! 1 4x4
		    prescan path! datatype! 1 5x6
		    open path! datatype! 1 5x5
		    scan word! datatype! 1 5x6
		    load word! datatype! 1 b
		    prescan word! datatype! 1 7x8
		    scan word! datatype! 1 7x8
		    load word! datatype! 1 c
		    prescan error! datatype! 1 9x9
		    error path! datatype! 1 5x9
		    prescan path! datatype! 1 10x11
		    open path! datatype! 1 10x10
		    scan word! datatype! 1 10x11
		    load word! datatype! 1 d
		    prescan word! datatype! 1 12x13
		    scan word! datatype! 1 12x13
		    load word! datatype! 1 e
		    close path! datatype! 1 12x13
		    error block! datatype! 1 4x13
		]

	--test-- "tt-15"
		clear logs
		--assert [] = transcode/trace "{^/" :lex-logger
		--assert logs = [
			   prescan string! datatype! 1 1x1 
			   open string! datatype! 1 1x1
			   error string! datatype! 2 1x3
		]

	--test-- "tt-16"
		clear logs
		--assert [i/(j): 3] = transcode/trace {i/(j): 3} :lex-logger
		--assert logs = [
		    prescan path! datatype! 1 1x2 
		    open path! datatype! 1 1x1 
		    scan word! datatype! 1 1x2 
		    load word! datatype! 1 i 
		    prescan paren! datatype! 1 3x3 
		    open paren! datatype! 1 3x3 
		    prescan word! datatype! 1 4x5 
		    scan word! datatype! 1 4x5 
		    load word! datatype! 1 j 
		    prescan paren! datatype! 1 5x5 
		    close paren! datatype! 1 5x5 
		    close set-path! datatype! 1 5x6 
		    prescan integer! datatype! 1 8x9 
		    scan integer! datatype! 1 8x9 
		    load integer! datatype! 1 3
		]

	--test-- "tt-17"
		clear logs
		--assert [] = transcode/trace {#"^^(00) a"} :lex-logger
		--assert logs = [
		    prescan char! datatype! 1 1x10 
		    error char! datatype! 1 1x10 
		]

	--test-- "tt-18"
		clear logs
		--assert none? transcode/trace {[(] a} :lex-logger
		--assert logs = [
		    prescan block! datatype! 1 1x1 
		    open block! datatype! 1 1x1 
		    prescan paren! datatype! 1 2x2 
		    open paren! datatype! 1 2x2 
		    prescan block! datatype! 1 3x3 
		    close block! datatype! 1 3x3 
		    error paren! datatype! 1 3x3 
		    prescan word! datatype! 1 5x6 
		    scan word! datatype! 1 5x6 
		    load word! datatype! 1 a 
		    error paren! datatype! 1 2x6
		]

	--test-- "tt-19"
		clear logs
		--assert none? transcode/trace {[(]} :lex-logger
		--assert logs = [
		    prescan block! datatype! 1 1x1 
		    open block! datatype! 1 1x1 
		    prescan paren! datatype! 1 2x2 
		    open paren! datatype! 1 2x2 
		    prescan block! datatype! 1 3x3 
		    close block! datatype! 1 3x3 
		    error paren! datatype! 1 3x3 
		    error paren! datatype! 1 2x4
		]

	--test-- "tt-20"
		clear logs
		--assert [()] = transcode/trace {(])} :lex-logger
		--assert logs = [
		    prescan paren! datatype! 1 1x1 
		    open paren! datatype! 1 1x1 
		    prescan block! datatype! 1 2x2 
		    close block! datatype! 1 2x2 
		    error paren! datatype! 1 2x2 
		    prescan paren! datatype! 1 3x3 
		    close paren! datatype! 1 3x3
		]

	--test-- "tt-21"
		clear logs
		--assert none? transcode/trace {[(]} :lex-logger
		--assert logs = [
		    prescan block! datatype! 1 1x1 
		    open block! datatype! 1 1x1 
		    prescan paren! datatype! 1 2x2 
		    open paren! datatype! 1 2x2 
		    prescan block! datatype! 1 3x3 
		    close block! datatype! 1 3x3 
		    error paren! datatype! 1 3x3 
		    error paren! datatype! 1 2x4
		]

	--test-- "tt-22"
		clear logs
		--assert [[()]] = transcode/trace {[(]])]} :lex-logger
		--assert logs = [
		    prescan block! datatype! 1 1x1 
		    open block! datatype! 1 1x1 
		    prescan paren! datatype! 1 2x2 
		    open paren! datatype! 1 2x2 
		    prescan block! datatype! 1 3x3 
		    close block! datatype! 1 3x3 
		    error paren! datatype! 1 3x3 
		    prescan block! datatype! 1 4x4 
		    close block! datatype! 1 4x4 
		    error paren! datatype! 1 4x4 
		    prescan paren! datatype! 1 5x5 
		    close paren! datatype! 1 5x5 
		    prescan block! datatype! 1 6x6 
		    close block! datatype! 1 6x6
		]

	--test-- "tt-23"
		clear logs
		--assert [] = transcode/trace "#([]22)" :lex-logger
		--assert logs = [
			prescan map! datatype! 1 1x2 
		    open map! datatype! 1 1x2 
		    prescan block! datatype! 1 3x3 
		    open block! datatype! 1 3x3 
		    prescan block! datatype! 1 4x4 
		    close block! datatype! 1 4x4 
		    prescan integer! datatype! 1 5x7 
		    scan integer! datatype! 1 5x7 
		    load integer! datatype! 1 22 
		    prescan paren! datatype! 1 7x7 
		    close map! datatype! 1 7x7 
		    error map! datatype! 1 7x7
		]

	--test-- "tt-24"
		src: "hello world 4a 123"
		clear logs
		--assert [o world 123] = transcode/trace skip src 4 :lex-logger	
		tt-24-logs: [
		    prescan word! datatype! 1 1x2 
		    scan word! datatype! 1 1x2 
		    load word! datatype! 1 o 
		    prescan word! datatype! 1 3x8 
		    scan word! datatype! 1 3x8 
		    load word! datatype! 1 world 
		    prescan error! datatype! 1 9x10 
		    error integer! datatype! 1 9x10 
		    prescan integer! datatype! 1 12x15 
		    scan integer! datatype! 1 12x15 
		    load integer! datatype! 1 123
		]
		--assert logs = tt-24-logs

	--test-- "tt-25"
		src: "hello world 4a 123"
		clear logs
		--assert [o world 123] = transcode/trace copy skip src 4 :lex-logger
		--assert logs = tt-24-logs

	--test-- "tt-26"
		src: to-binary "hello world 4a 123"
		clear logs
		--assert [o world 123] = transcode/trace skip src 4 :lex-logger
		--assert logs = tt-24-logs

	--test-- "tt-27"
		src: to-binary "hello world 4a 123"
		clear logs
		--assert [o world 123] = transcode/trace copy skip src 4 :lex-logger
		--assert logs = tt-24-logs

	--test-- "tt-28"
		lex-logger28: function [
		  event  [word!]
		  input  [string! binary!]
		  type   [datatype! word! none!]
		  line   [integer!]
		  token
		  return:  [logic!]
		][
			t: tail logs
			reduce/into [event to-word type to-word type? type line token input] tail logs
			new-line t yes
			any [event <> 'error all [input: next input false]]
		]
		src: "hello world 4a 123"
		clear logs
		--assert [o world 123] = transcode/trace skip src 4 :lex-logger28
		--assert logs = [
		    prescan word! datatype! 1 1x2 " world 4a 123" 
		    scan word! datatype! 1 1x2 " world 4a 123" 
		    load word! datatype! 1 o " world 4a 123" 
		    prescan word! datatype! 1 3x8 " 4a 123" 
		    scan word! datatype! 1 3x8 " 4a 123" 
		    load word! datatype! 1 world " 4a 123" 
		    prescan error! datatype! 1 9x10 "a 123" 
		    error integer! datatype! 1 9x10 "a 123" 
		    prescan integer! datatype! 1 12x15 "" 
		    scan integer! datatype! 1 12x15 "" 
		    load integer! datatype! 1 123 ""
		]

	--test-- "tt-29"
		clear logs
		--assert [a/b] == transcode/trace "a/b/" :lex-logger
		--assert logs = [
		    prescan path! datatype! 1 1x2
		    open path! datatype! 1 1x1
		    scan word! datatype! 1 1x2
		    load word! datatype! 1 a
		    prescan word! datatype! 1 3x4
		    scan word! datatype! 1 3x4
		    load word! datatype! 1 b
		    error path! datatype! 1 1x4
		]

	--test-- "tt-30"
		clear logs
		--assert (reduce [to-path 'a 'c]) == transcode/trace "a/b:c" :lex-logger
		--assert logs = [
		    prescan path! datatype! 1 1x2 
		    open path! datatype! 1 1x1 
		    scan word! datatype! 1 1x2 
		    load word! datatype! 1 a 
		    prescan word! datatype! 1 3x4 
		    error word! datatype! 1 3x4 
		    prescan word! datatype! 1 5x6 
		    scan word! datatype! 1 5x6 
		    load word! datatype! 1 c
		]

	--test-- "tt-31"
		clear logs
		--assert [] == transcode/trace ";-- comment" :lex-logger
		--assert logs = [
			prescan comment word! 1 1x12 
			scan comment word! 1 1x12
		]

	--test-- "tt-32"
		clear logs
		--assert [] == transcode/trace %%{"dd^}%% :lex-logger
		--assert logs = [
			prescan error! datatype! 1 1x5
			error string! datatype! 1 1x5
		]

===end-group===

~~~end-file~~~
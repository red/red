Red [
	Title:   "Red bugs tests"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test1992.red
	Tabs:	 4
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Needs:	 'View
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "bugs"

===start-group=== "regression"

	; --test-- "#5"

	; --test-- "#28"

	; --test-- "#32"

	; --test-- "#55"

	; --test-- "#59"

	; --test-- "#63"

	; --test-- "#65"

	; --test-- "#71"

	; --test-- "#76"

	; --test-- "#88"

	; --test-- "#89"

	; --test-- "#114"

	; --test-- "#117"

	; --test-- "#121"

	; --test-- "#122"

	; --test-- "#123"

	; --test-- "#125"

	; --test-- "#131"

	; --test-- "#134"

	; --test-- "#136"

	; --test-- "#137"

	; --test-- "#138"

	; --test-- "#139"

	; --test-- "#146"

	; --test-- "#148"

	; --test-- "#149"

	; --test-- "#150"

	; --test-- "#151"

	; --test-- "#153"

	; --test-- "#154"

	; --test-- "#157"

	; --test-- "#158"

	; --test-- "#159"

	; --test-- "#160"

	; --test-- "#161"

	; --test-- "#162"

	; --test-- "#164"

	; --test-- "#165"

	; --test-- "#167"

	; --test-- "#168"

	; --test-- "#169"

	; --test-- "#170"

	; --test-- "#171"

	; --test-- "#172"

	; --test-- "#173"

	; --test-- "#174"

	; --test-- "#175"

	; --test-- "#178"

	; --test-- "#188"

	; --test-- "#198"

	; --test-- "#200"

	; --test-- "#204"

	; --test-- "#205"

	; --test-- "#207"

	; --test-- "#208"

	; --test-- "#209"

	; --test-- "#210"

	; --test-- "#212"

	; --test-- "#216"

	; --test-- "#217"

	; --test-- "#220"

	; --test-- "#221"

	; --test-- "#222"

	; --test-- "#223"

	; --test-- "#224"

	; --test-- "#225"

	; --test-- "#226"

	; --test-- "#227"

	; --test-- "#228"

	; --test-- "#229"

	; --test-- "#231"

	; --test-- "#233"

	; --test-- "#234"

	; --test-- "#235"

	; --test-- "#236"

	; --test-- "#238"

	; --test-- "#239"

	; --test-- "#241"

	; --test-- "#243"

	; --test-- "#244"

	; --test-- "#245"

	; --test-- "#250"

	; --test-- "#253"

	; --test-- "#254"

	; --test-- "#257"

	; --test-- "#258"

	; --test-- "#261"

	; --test-- "#262"

	; --test-- "#263"

	; --test-- "#265"

	; --test-- "#269"

	; --test-- "#272"

	; --test-- "#273"

	; --test-- "#274"

	; --test-- "#275"

	; --test-- "#276"

	; --test-- "#278"

	; --test-- "#279"

	; --test-- "#281"

	; --test-- "#282"

	; --test-- "#284"

	; --test-- "#285"

	; --test-- "#288"

	; --test-- "#289"

	; --test-- "#290"

	; --test-- "#291"

	; --test-- "#292"

	; --test-- "#293"

	; --test-- "#298"

	; --test-- "#300"

	; --test-- "#304"

	; --test-- "#306"

	; --test-- "#308"

	; --test-- "#310"

	; --test-- "#312"

	; --test-- "#313"

	; --test-- "#316"

	; --test-- "#317"

	; --test-- "#321"

	; --test-- "#323"

	; --test-- "#324"

	; --test-- "#326"

	; --test-- "#328"

	; --test-- "#330"

	; --test-- "#331"

	; --test-- "#332"

	; --test-- "#334"

	; --test-- "#338"

	; --test-- "#340"

	; --test-- "#342"

	; --test-- "#344"

	; --test-- "#345"

	; --test-- "#346"

	; --test-- "#347"

	; --test-- "#348"

	; --test-- "#355"

	; --test-- "#356"

	; --test-- "#357"

	; --test-- "#358"

	; --test-- "#360"

	; --test-- "#362"

	; --test-- "#363"

	; --test-- "#364"

	; --test-- "#366"

	; --test-- "#367"

	; --test-- "#369"

	; --test-- "#370"

	; --test-- "#372"

	; --test-- "#373"

	; --test-- "#374"

	; --test-- "#376"

	; --test-- "#377"

	; --test-- "#379"

	; --test-- "#381"

	; --test-- "#383"

	; --test-- "#384"

	; --test-- "#385"

	; --test-- "#386"

	; --test-- "#388"

	; --test-- "#389"

	; --test-- "#391"

	; --test-- "#392"

	; --test-- "#393"

	; --test-- "#394"

	; --test-- "#395"

	; --test-- "#396"

	; --test-- "#397"

	; --test-- "#398"

	; --test-- "#399"

	; --test-- "#400"

	; --test-- "#401"

	; --test-- "#402"

	; --test-- "#403"

	; --test-- "#404"

	; --test-- "#405"

	; --test-- "#406"

	; --test-- "#407"

	; --test-- "#409"

	; --test-- "#411"

	; --test-- "#412"

	; --test-- "#413"

	; --test-- "#414"

	; --test-- "#415"

	; --test-- "#416"

	; --test-- "#417"

	; --test-- "#418"

	; --test-- "#419"

	; --test-- "#420"

	; --test-- "#422"

	; --test-- "#423"

	; --test-- "#424"

	; --test-- "#425"

	; --test-- "#426"

	; --test-- "#427"

	; --test-- "#428"

	; --test-- "#429"

	; --test-- "#430"

	; --test-- "#431"

	; --test-- "#432"

	; --test-- "#435"

	; --test-- "#437"

	; --test-- "#443"

	; --test-- "#449"

	; --test-- "#453"

	; --test-- "#455"

	; --test-- "#457"

	; --test-- "#458"

	; --test-- "#459"

	; --test-- "#460"

	; --test-- "#461"

	; --test-- "#465"

	; --test-- "#468"

	; --test-- "#473"

	; --test-- "#474"

	; --test-- "#475"

	; --test-- "#481"

	; --test-- "#482"

	; --test-- "#483"

	; --test-- "#484"

	; --test-- "#486"

	; --test-- "#488"

	; --test-- "#490"

	; --test-- "#491"

	; --test-- "#492"

	; --test-- "#493"

	; --test-- "#494"

	; --test-- "#497"

	; --test-- "#498"

	; --test-- "#501"

	; --test-- "#505"

	; --test-- "#506"

	; --test-- "#507"

	; --test-- "#508"

	; --test-- "#509"

	; --test-- "#510"

	; --test-- "#511"

	; --test-- "#512"

	; --test-- "#513"

	; --test-- "#514"

	; --test-- "#515"

	; --test-- "#518"

	; --test-- "#519"

	; --test-- "#520"

	; --test-- "#522"

	; --test-- "#523"

	; --test-- "#524"

	; --test-- "#525"

	; --test-- "#526"

	; --test-- "#528"

	; --test-- "#530"

	; --test-- "#531"

	; --test-- "#532"

	; --test-- "#533"

	; --test-- "#535"

	; --test-- "#537"

	; --test-- "#538"

	; --test-- "#539"

	; --test-- "#540"

	; --test-- "#541"

	; --test-- "#542"

	; --test-- "#545"

	; --test-- "#547"

	; --test-- "#548"

	; --test-- "#552"

	; --test-- "#553"

	; --test-- "#554"

	; --test-- "#555"

	; --test-- "#558"

	; --test-- "#559"

	; --test-- "#560"

	; --test-- "#562"

	; --test-- "#563"

	; --test-- "#564"

	; --test-- "#565"

	; --test-- "#569"

	; --test-- "#570"

	; --test-- "#572"

	; --test-- "#573"

	; --test-- "#574"

	; --test-- "#581"

	; --test-- "#584"

	; --test-- "#586"

	; --test-- "#587"

	; --test-- "#589"

	; --test-- "#592"

	; --test-- "#593"

	; --test-- "#594"

	; --test-- "#596"

	; --test-- "#598"

	; --test-- "#599"

	; --test-- "#601"

	; --test-- "#604"

	; --test-- "#605"

	; --test-- "#606"

	; --test-- "#608"

	; --test-- "#609"

	; --test-- "#616"

	; --test-- "#620"

	; --test-- "#625"

	; --test-- "#626"

	; --test-- "#628"

	; --test-- "#630"

	; --test-- "#633"

	; --test-- "#634"

	; --test-- "#637"

	; --test-- "#644"

	; --test-- "#645"

	; --test-- "#646"

	; --test-- "#647"

	; --test-- "#650"

	; --test-- "#651"

	; --test-- "#653"

	; --test-- "#655"

	; --test-- "#656"

	; --test-- "#657"

	; --test-- "#659"

	; --test-- "#660"

	; --test-- "#667"

	; --test-- "#669"

	; --test-- "#678"

	; --test-- "#682"

	; --test-- "#687"

	; --test-- "#696"

	; --test-- "#699"

	; --test-- "#702"

	; --test-- "#704"

	; --test-- "#706"

	; --test-- "#710"

	; --test-- "#714"

	; --test-- "#715"

	; --test-- "#716"

	; --test-- "#720"

	; --test-- "#725"

	; --test-- "#726"

	; --test-- "#727"

	; --test-- "#740"

	; --test-- "#745"

	; --test-- "#748"

	; --test-- "#751"

	; --test-- "#757"

	; --test-- "#764"

	; --test-- "#765"

	; --test-- "#770"

	; --test-- "#776"

	; --test-- "#778"

	; --test-- "#785"

	; --test-- "#787"

	; --test-- "#789"

	; --test-- "#791"

	; --test-- "#796"

	; --test-- "#800"

	; --test-- "#806"

	; --test-- "#810"

	; --test-- "#817"

	; --test-- "#818"

	; --test-- "#820"

	; --test-- "#825"

	; --test-- "#829"

	; --test-- "#831"

	; --test-- "#832"

	; --test-- "#837"

	; --test-- "#839"

	; --test-- "#847"

	; --test-- "#849"

	; --test-- "#853"

	; --test-- "#854"

	; --test-- "#856"

	; --test-- "#858"

	; --test-- "#861"

	; --test-- "#869"

	; --test-- "#871"

	; --test-- "#873"

	; --test-- "#876"

	; --test-- "#877"

	; --test-- "#880"

	; --test-- "#884"

	; --test-- "#893"

	; --test-- "#899"

	; --test-- "#902"

	; --test-- "#913"

	; --test-- "#916"

	; --test-- "#917"

	; --test-- "#918"

	; --test-- "#919"

	; --test-- "#920"

	; --test-- "#923"

	; --test-- "#927"

	; --test-- "#928"

	; --test-- "#929"

	; --test-- "#930"

	; --test-- "#931"

	; --test-- "#932"

	; --test-- "#934"

	; --test-- "#939"

	; --test-- "#943"

	; --test-- "#946"

	; --test-- "#947"

	; --test-- "#956"

	; --test-- "#957"

	; --test-- "#959"

	; --test-- "#960"

	; --test-- "#962"

	; --test-- "#965"

	; --test-- "#967"

	; --test-- "#969"

	; --test-- "#970"

	; --test-- "#971"

	; --test-- "#973"

	; --test-- "#974"

	; --test-- "#980"

	; --test-- "#981"

	; --test-- "#983"

	; --test-- "#988"

	; --test-- "#990"

	; --test-- "#993"

	; --test-- "#994"

	; --test-- "#995"

	; --test-- "#1001"

	; --test-- "#1003"

	; --test-- "#1005"

	; --test-- "#1019"

	; --test-- "#1020"

	; --test-- "#1022"

	; --test-- "#1031"

	; --test-- "#1035"

	; --test-- "#1042"

	; --test-- "#1050"

	; --test-- "#1054"

	; --test-- "#1055"

	; --test-- "#1059"

	; --test-- "#1063"

	; --test-- "#1071"

	; --test-- "#1074"

	; --test-- "#1075"

	; --test-- "#1079"

	; --test-- "#1080"

	; --test-- "#1083"

	; --test-- "#1085"

	; --test-- "#1088"

	; --test-- "#1090"

	; --test-- "#1093"

	; --test-- "#1098"

	; --test-- "#1102"

	; --test-- "#1113"

	; --test-- "#1115"

	; --test-- "#1116"

	; --test-- "#1117"

	; --test-- "#1119"

	; --test-- "#1120"

	; --test-- "#1122"

	; --test-- "#1126"

	; --test-- "#1128"

	; --test-- "#1130"

	; --test-- "#1135"

	; --test-- "#1136"

	; --test-- "#1141"

	; --test-- "#1143"

	; --test-- "#1144"

	; --test-- "#1146"

	; --test-- "#1147"

	; --test-- "#1148"

	; --test-- "#1153"

	; --test-- "#1154"

	; --test-- "#1158"

	; --test-- "#1159"

	; --test-- "#1160"

	; --test-- "#1163"

	; --test-- "#1164"

	; --test-- "#1167"

	; --test-- "#1168"

	; --test-- "#1169"

	; --test-- "#1171"

	; --test-- "#1176"

	; --test-- "#1186"

	; --test-- "#1195"

	; --test-- "#1199"

	; --test-- "#1206"

	; --test-- "#1207"

	; --test-- "#1209"

	; --test-- "#1213"

	; --test-- "#1218"

	; --test-- "#1222"

	; --test-- "#1230"

	; --test-- "#1232"

	; --test-- "#1238"

	; --test-- "#1243"

	; --test-- "#1245"

	; --test-- "#1246"

	; --test-- "#1259"

	; --test-- "#1265"

	; --test-- "#1275"

	; --test-- "#1281"

	; --test-- "#1284"

	; --test-- "#1290"

	; --test-- "#1293"

	; --test-- "#1307"

	; --test-- "#1322"

	; --test-- "#1324"

	; --test-- "#1329"

	; --test-- "#1345"

	; --test-- "#1354"

	; --test-- "#1378"

	; --test-- "#1384"

	; --test-- "#1396"

	; --test-- "#1397"

	; --test-- "#1400"

	; --test-- "#1416"

	; --test-- "#1417"

	; --test-- "#1418"

	; --test-- "#1420"

	; --test-- "#1422"

	; --test-- "#1424"

	; --test-- "#1427"

	; --test-- "#1435"

	; --test-- "#1438"

	; --test-- "#1443"

	; --test-- "#1449"

	; --test-- "#1451"

	; --test-- "#1456"

	; --test-- "#1457"

	; --test-- "#1458"

	; --test-- "#1464"

	; --test-- "#1468"

	; --test-- "#1472"

	; --test-- "#1475"

	; --test-- "#1477"

	; --test-- "#1479"

	; --test-- "#1481"

	; --test-- "#1485"

	; --test-- "#1487"

	; --test-- "#1489"

	; --test-- "#1490"

	; --test-- "#1493"

	; --test-- "#1496"

	; --test-- "#1499"

	; --test-- "#1500"

	; --test-- "#1501"

	; --test-- "#1502"

	; --test-- "#1509"

	; --test-- "#1515"

	; --test-- "#1519"

	; --test-- "#1522"

	; --test-- "#1524"

	; --test-- "#1527"

	; --test-- "#1528"

	; --test-- "#1530"

	; --test-- "#1537"

	; --test-- "#1540"

	; --test-- "#1542"

	; --test-- "#1545"

	; --test-- "#1551"

	; --test-- "#1557"

	; --test-- "#1558"

	; --test-- "#1559"

	; --test-- "#1561"

	; --test-- "#1562"

	; --test-- "#1565"

	; --test-- "#1566"

	; --test-- "#1567"

	; --test-- "#1568"

	; --test-- "#1570"

	; --test-- "#1571"

	; --test-- "#1574"

	; --test-- "#1576"

	; --test-- "#1578"

	; --test-- "#1583"

	; --test-- "#1587"

	; --test-- "#1589"

	; --test-- "#1590"

	; --test-- "#1591"

	; --test-- "#1592"

	; --test-- "#1593"

	; --test-- "#1596"

	; --test-- "#1598"

	; --test-- "#1600"

	; --test-- "#1606"

	; --test-- "#1607"

	; --test-- "#1609"

	; --test-- "#1611"

	; --test-- "#1622"

	; --test-- "#1624"

	; --test-- "#1627"

	; --test-- "#1628"

	; --test-- "#1630"

	; --test-- "#1632"

	; --test-- "#1633"

	; --test-- "#1645"

	; --test-- "#1646"

	; --test-- "#1655"

	; --test-- "#1657"

	; --test-- "#1670"

	; --test-- "#1671"

	; --test-- "#1674"

	; --test-- "#1677"

	; --test-- "#1678"

	; --test-- "#1679"

	; --test-- "#1680"

	; --test-- "#1683"

	; --test-- "#1684"

	; --test-- "#1694"

	; --test-- "#1698"

	; --test-- "#1700"

	; --test-- "#1702"

	; --test-- "#1709"

	; --test-- "#1710"

	; --test-- "#1715"

	; --test-- "#1717"

	; --test-- "#1718"

	; --test-- "#1720"

	; --test-- "#1723"

	; --test-- "#1729"

	; --test-- "#1730"

	; --test-- "#1732"

	; --test-- "#1741"

	; --test-- "#1745"

	; --test-- "#1746"

	; --test-- "#1750"

	; --test-- "#1751"

	; --test-- "#1753"

	; --test-- "#1754"

	; --test-- "#1755"

	; --test-- "#1758"

	; --test-- "#1762"

	; --test-- "#1764"

	; --test-- "#1768"

	; --test-- "#1769"

	; --test-- "#1774"

	; --test-- "#1775"

	; --test-- "#1781"

	; --test-- "#1784"

	; --test-- "#1785"

	; --test-- "#1790"

	; --test-- "#1797"

	; --test-- "#1799"

	; --test-- "#1807"

	; --test-- "#1809"

	; --test-- "#1814"

	; --test-- "#1816"

	; --test-- "#1817"

	; --test-- "#1820"

	; --test-- "#1829"

	; --test-- "#1831"

	; --test-- "#1834"

	; --test-- "#1835"

	; --test-- "#1836"

	; --test-- "#1838"

	; --test-- "#1842"

	; --test-- "#1847"

	; --test-- "#1853"

	; --test-- "#1858"

	; --test-- "#1865"

	; --test-- "#1866"

	; --test-- "#1867"

	; --test-- "#1868"

	; --test-- "#1869"

	; --test-- "#1872"

	; --test-- "#1874"

	; --test-- "#1878"

	; --test-- "#1879"

	; --test-- "#1880"

	; --test-- "#1881"

	; --test-- "#1882"

	; --test-- "#1883"

	; --test-- "#1884"

	; --test-- "#1887"

	; --test-- "#1889"

	; --test-- "#1892"

	; --test-- "#1893"

	; --test-- "#1894"

	; --test-- "#1895"

	; --test-- "#1900"
		; GUI

	--test-- "#1905"
		x: [a b c 4 d e f]
		move/part x skip x 3 2
		--assert equal? x [c 4 a b d e f]

	; --test-- "#1907"
		; should check for crash

	; --test-- "#1910"
		; GUI

	--test-- "#1911"
		m: make map! []
		k: "a"
		put m k 1
		k: "b"
		--assert error? try [set m k]

	; --test-- "#1916"
		; GUI

	; --test-- "#1919"
		; GUI console behaviour

	; --test-- "#1920"
		; GUI

	--test-- "#1923"
		a: [1 2 3] 
		forall a [if a/1 = 2 [break]]
		--assert equal? a [2 3]

	; --test-- "#1925"
		; NOTE: Red Compiler internal error

		; test!: object [
		; clone: func [
		; 	/local ret [test!]
		; ][
		; 	ret: make test! []
		; 	;initialize ret here, in real application
		; 	ret
		; 	]
		; ]

	; --test-- "#1930"
		; GUI

	; --test-- "#1933"
		; GUI

	; --test-- "#1935"
;		--assert error? try [test/:]
;		; NOTE: bug should crash, how to test it?

	; --test-- "#1937"
		; GUI console behaviour

	--test-- "#1939"
		unset 'a
		--assert error? try [parse blk: [1][change integer! a]]

	; --test-- "#1942"
		; GUI

	--test-- "#1947"
		--assert equal? [1] find [a 1] integer!

	; --test-- "#1953"
		; GUI console behaviour
		
	; --test-- "#1963"
		; GUI console behaviour

	; --test-- "#1965"
		; R/S

	--test-- "#1968"
		--assert not equal? mold #"^(005E)" mold #"^(001E)"
		--assert equal? {#"^^(1E)"} #"^(001E)"

	; --test-- "#1969"
		; FIXME: still a problem in R/S

		; foo: func [a [float!] b [float!]][a + b]

		; out: #system [
		; 	#call [foo 2.0 4.0]
		; 	fl: as red-float! stack/arguments
		; 	probe fl/value
		; ]
		; print ["*** out:" out]


	; --test-- "#1974"
		f: func [p [string!]] [print p]
		--assert error? try [f 'spec] 	; NOTE: this should check that it does not crash
										; 		how to do it?

	; --test-- "#1983"
		; R/S

	; --test-- "#1991"
		; console behaviour

	; --test-- "#1992"
		; GUI

	--test-- "#1993"
		range: [0 0] 
		a: range/1: 1
		--assert equal? [1 0] range

	--test-- "#1995"
		--assert error? try [load/next "(]" 'a]

	--test-- "#1996"
		blk: [a b #x #y 2 3]
		put blk 2 4
		--assert equal? [a b #x #y 2 4] blk

	; --test-- "#1999"
		; R/S

	; --test-- "#2003"
		; GUI console

	--test-- "#2007"
		; NOTE: how to check for crash?
		--assert not error? [make image! 0x0]

	--test-- "#2012"
		random/seed 1
		t: random 0:0:1
		--assert equal? 0:00:00.0 round t

	--test-- "#2014"
		--assert equal? 1:00:00 / 0:0:1 3600.0

	--test-- "#2015"
		--assert error? try [0:0:2 ** 5]

	; --test-- "#2019"
		; R/S

	--test-- "#2021"
		--assert error? try [set 'vv first reduce [()]]
	
	--test-- "#2024"
		write %test.txt "abcdef"
		--assert equal? "bcdef" read/seek %test.txt 1

	--test-- "#2031"
		--assert equal? ["1" "3" "" "3" "" ""] split "1,3,.3,," charset ".,"

	--test-- "#2033"
		--assert not error? try [func [x "radius" y "degrees"][x + y]]
;		--assert error? try [func [x "radius" [integer!] y [integer!] "degrees"][x + y]] ; test for #2027 -- how to test for compiler errors?

	; --test-- "#2034"
		; GUI

	; --test-- "#2041"
		; GUI

	; --test-- "#2048"
		; R/S

	; --test-- "#2050"
		; GUI console behaviour

	; --test-- "#2052"
		; GUI console behaviour

	--test-- "#2068"
;		TODO: need more info, what is maximal length of tuple?
;			it is still buggy when compiled
		x: 1.2.3.4.5.6.7.8.9.10
		--assert equal? x 1.2.3.4.5.6.7.8.9.10
		x: 1.2.3.4.5.6.7.8.9.10.11.12
		--assert equal? x 1.2.3.4.5.6.7.8.9.10.11.12

	--test-- "#2069"
		--assert equal? "abc1abc2abc3" unique/skip "abc1abc2abc3" 3

	; --test-- "#2070"

	--test-- "#2072"
		m: make map! 10
		a: [1 2 3]
		m/a: a
		save %file m
		n: load %file
		--assert equal? m n

	--test-- "#2077"
		sum: function [list [block!]] [
			total: 0
			foreach i list [total: i + total]
			total
		]
		r: make reactor! [l: [3 4 5 6] total: is [sum l]]
		r/l: append copy r/l 5
		--assert not error? try [append r/l 5]

	--test-- "#2079"
		i: make image! 2x2
		--assert not error? try [foreach p i [p]]

	; --test-- "#2081"

	--test-- "#2083"
		a: make reactor! [x: 1 y: is [x + 1] z: is [y + 1]]
		a/x: 4
		--assert equal? 6 a/z

;	--test-- "#2085"
		; FIME: throws error: *** Script Error: y has no value
;		--assert error? try [d: make reactor! [x: is [y + 1] y: is [x + 3]]]

	; --test-- "#2096"

	--test-- "#2097"
		write %test.bin #{00000000}
		write/seek %test.bin #{AAAA} 2
		--assert equal? #{0000AAAA} read/binary %test.bin
		write/seek %test.bin #{BBBB} 0
		--assert equal? #{BBBBAAAA} read/binary %test.bin

	; --test-- "#2098"
		; GUI

	--test-- "#2099"
		original: read/binary http://www.rebol.com/how-to/graphics/button.gif
		write/binary %button.gif original
		saved: read/binary %button.gif
		--assert equal? saved original

	; --test-- "#2104"
		; console behaviour - #1995

	; --test-- "#2105"
		; infinite loop - how to catch it?

	--test-- "#2108"
		--assert parse "x" [to [end]]

	; --test-- "#2109"
		; console

	; --test-- "#2113"
		; FIXME: got "compilation error"

		; a: make object! [
		; 	act-state: make object! [
		; 		finish?: false
		; 		fn-callback: none
		; 	]
		; 	start: function[callback][
		; 		self/act-state/fn-callback: :callback
		; 	]
		; ]
		; callback1: function[][bad-value: "xyz"]
		; a/start :callback1
		; --assert not value? 'bad-value
	
	; --test-- "#2118"
		; GUI

	--test-- "#2125"
		--assert 2 = length? find reduce [integer! 1] integer!

	; --test-- "#2133"
		; TODO: compiler error

	; --test-- "#2135"
		; TODO: R/S

	--test-- "#2136"
		blk: copy []
		insert/dup blk 0 3
		insert/dup blk 1 2
		--assert equal? blk [1 1 0 0 0]

	--test-- "#2137"
		repeat n 56 [to string! debase/base at form to-hex n + 191 7 16]
		; NOTE: how to catch crash? - should crash in old version

	--test-- "#2138"
		b: [1 2 3 4 5]
		forall b [i: b/1: form b/1]
		--assert equal? b ["1" "2" "3" "4" "5"]

	--test-- "#2139"
		--assert equal? 1% 1% * 1

	--test-- "#2143"
		; NOTE: how to catch crash? - should crash in old version
		ts: [test: 10]
		t-o: object []
		make t-o ts

	--test-- "#2146"
		test: make hash! [a: 10]
		--assert equal? 10 test/a
		test: make hash! [a: 10 a 20]
		--assert equal? 10 test/a

	; --test-- "#2147"
		; GUI

	; --test-- "#2149"
		; GUI

;	--test-- "#2152"
;		--assert error? try [func [/x x] []]
;		; causes compiler error

;	--test-- "#2155"
;		--assert error? try [func [h [integer!!]] [h]]
;		; causes compiler error

	--test-- "#2157"
		--assert error? try [-2147483648 / -1]
		--assert error? try [-2147483648 % -1]
		--assert error? try [remainder -2147483648 -1]

	; --test-- "#2159"
		--assert equal? #{3030303030303134} append #{} to-hex 20
		; bug causes crash

	; --test-- "#2160"
		--assert not error? try [extract/into/index [1 2 3 4 5 6] 2 b: [] 2]

	; --test-- "#2162"
		; write/info https://api.github.com/user [GET [User-Agent: "me"]]
		; crashes runtime

	; --test-- "#2163"
		; TODO: get some example, description is not good enough

	; --test-- "#2166"
		x: 2147483648
		--assert not equal? x -2147483648
		--assert equal? x 2147483648.0

	; --test-- "#2170"
		; GUI

===end-group===

~~~end-file~~~
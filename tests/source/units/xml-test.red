Red [
	Title:   "CSV codec test script"
	Author:  "Boleslav Březovský"
	File: 	 %csv-test.red
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red


~~~start-file~~~ "XML"

===start-group=== "load-xml"
	--test-- "load-xml-triples"
		--assert [] = load-xml ""
		--assert [tag none none] = load-xml {<tag/>}
		--assert [tag none [attr "value"]] = load-xml {<tag attr="value"/>}
		--assert [tag none [attr "value"]] = load-xml {<tag attr='value'/>}
		--assert equal?
			[tag none [att1 "value" att2 "hodnota"]]
			load-xml {<tag att1='value' att2="hodnota"/>}
		-assert equal?
			[tag none [att1 "value" att2 "hodnota"]]
			load-xml {<tag att1='value' att2="hodnota"></tag>}
		-assert equal?
			[tag "Content" [att1 "value" att2 "hodnota"]]
			load-xml {<tag att1='value' att2="hodnota">Content</tag>}

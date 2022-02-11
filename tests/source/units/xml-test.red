Red [
	Title:   "XML codec test script"
	Author:  "Boleslav Březovský"
	File: 	 %xml-test.red
	Rights:  "Copyright (C) 2011-2022 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red


~~~start-file~~~ "XML"

===start-group=== "load-xml"
	--test-- "load-xml-triples"
		--assert [] = load-xml ""
		--assert [tag #[none] #[none]] = load-xml {<tag/>}
		--assert [tag #[none] [attr "value"]] = load-xml {<tag attr="value"/>}
		--assert [tag #[none] [attr "value"]] = load-xml {<tag attr='value'/>}
		--assert equal?
			[tag #[none] [att1 "value" att2 "hodnota"]]
			load-xml {<tag att1='value' att2="hodnota"/>}
		--assert equal?
			[tag #[none] [att1 "value" att2 "hodnota"]]
			load-xml {<tag att1='value' att2="hodnota"></tag>}
		--assert equal?
			[tag "Content" [att1 "value" att2 "hodnota"]]
			load-xml {<tag att1='value' att2="hodnota">Content</tag>}
	--test-- "load-xml-compact"
		--assert [] = load-xml/as "" 'compact
		--assert [tag []] = load-xml/as {<tag/>} 'compact
		--assert [tag [#attr "value"]] = load-xml/as {<tag attr="value"/>} 'compact
		--assert [tag [#attr "value"]] = load-xml/as {<tag attr='value'/>} 'compact
		--assert equal?
			[tag [#att1 "value" #att2 "hodnota"]]
			load-xml/as {<tag att1='value' att2="hodnota"/>} 'compact
		--assert equal?
			[tag [#att1 "value" #att2 "hodnota"]]
			load-xml/as {<tag att1='value' att2="hodnota"></tag>} 'compact
		--assert equal?
			[tag [#att1 "value" #att2 "hodnota" text! "Content"]]
			load-xml/as {<tag att1='value' att2="hodnota">Content</tag>} 'compact
	--test-- "load-xml-key-val"
		--assert [] = load-xml/as "" 'key-val
		--assert equal?
			[tag []]
			load-xml/as {<tag/>} 'key-val
		--assert equal?
			[tag [attr! [attr "value"]]]
			load-xml/as {<tag attr="value"/>} 'key-val
		--assert equal?
			[tag [attr! [attr "value"]]]
			load-xml/as {<tag attr='value'/>} 'key-val
		--assert equal?
			[tag [attr! [att1 "value" att2 "hodnota"]]]
			load-xml/as {<tag att1='value' att2="hodnota"/>} 'key-val
		--assert equal?
			[tag [attr! [att1 "value" att2 "hodnota"]]]
			load-xml/as {<tag att1='value' att2="hodnota"></tag>} 'key-val
		--assert equal?
			[tag [attr! [att1 "value" att2 "hodnota"] text! "Content"]]
			load-xml/as {<tag att1='value' att2="hodnota">Content</tag>} 'key-val

REBOL [
	Title: "MakeDoc 2 - The REBOL Standard Document Formatter"
	Version: 2.5.7
	Copyright: "REBOL Technologies 1999-2005"
	Author: "Carl Sassenrath"
	File: %makedoc2.r
	Date: 10-Mar-2007 ;10-Jan-2005
	Purpose: {
		This is the official MakeDoc document formatter that is used by
		REBOL Technologies for all documentation. It is the fastest and
		easiest way to create good looking documentation using any text
		editor (even ones that do not auto-wrap text). It creates titles,
		headings, contents, bullets, numbered lists, indented examples,
		note blocks, and more. For documentation, notes, and other info
		visit http://www.rebol.net/docs/makedoc.html
	}
	Usage: {
		Create a text document in any editor. Separate each paragraph
		with a blank line. Run this script and provide your text file.
		The output file will be the same name with .html following it.
		If you use REBOL/View the output file will be displayed in
		your web browser as well.

		You can also call this script from other scripts (e.g. CGI).
		These are supported:

			do %makedoc2.r

			do/args %makedoc2.r %document.txt

			do/args %makedoc2.r 'load-only
			doc: scan-doc read %file.txt
			set [title out] gen-html/options doc [(options)]
			write %out.html out
	}
	Library: [
		level: 'intermediate
		platform: 'all
		type: [tool]
		domain: [html cgi markup]
		tested-under: none
		support: none
		license: 'BSD
		see-also: none
	]
]

; Below you can specify an HTML output template to use for all your docs.
; See the default-template example below as a starting suggestion.
template-file: %template.html  ; Example: %template.html

; There are three parts to this script:
;   1. The document input scanner.
;   2. The document output formatter (for HTML).
;   3. The code that deals with input and output files.

*scanner*: context [

;-- Debugging:
verbose: off
debug: func [data] [if verbose [print data]]

;-- Module Variables:
text: none
para: none
code: none
title: none
left-flag: off
opts: [] ;[no-toc no-nums]
out: [] ; The output block (static, reused)
option: none

;--- Parser rules for the Makedoc text language (top-down):

rules: [some commands]
commands: [
	newline
	here: (debug ["---PARSE:" copy/part here find here newline])

	;-- Document sections:
	| ["===" | "-1-"] text-line (emit-section 1)
	| ["---" | "-2-"] text-line (emit-section 2)
	| ["+++" | "-3-"] text-line (emit-section 3)
	| ["..." | "-4-"] text-line (emit-section 4)
	| "###" to end (emit end none) ; allows notes, comments to follow

	;-- Common commands:
	| #"*" [
		  [">>" | "**"] text-block (emit bullet3 para)
		| [">"  | "*" ] text-block (emit bullet2 para)
		| text-block (emit bullet para)
	]
	| #"#" [
		  ">>" text-block (emit enum3 para)
		| ">"  text-block (emit enum2 para)
		| text-block (emit enum para)
	]
	| #":" define opt newline (emit define reduce [text para])

;   ">>" reserved
;   "<<" reserved

	;-- Enter a special section:
	| #"\" [
		  "in" (emit indent-in none)
		| "note" text-line (emit note-in text)
		| "table" text-line (emit table-in text)
		| "group" (emit group-in none)
		| "center" (emit center-in none)
		| "column" (emit column-in none)
	]

	;-- Exit a special section:
	| #"/" [
		  "in" (emit indent-out none)
		| "note" (emit note-out none)
		| "table" (emit table-out none)
		| "group" (emit group-out none)
		| "center" (emit center-out none)
		| "column" (emit column-out none)
	]

	;-- Extended commands (all begin with "="):
	| #";" text-block ; comments and hidden paragraphs
	| #"=" [
		  #"=" output (emit output trim/auto code)
		| "image" image
		| "row" (emit table-row none)
		| "column" (emit column none) ; (for doc, not tables)
		| "options" [
			any [
				spaces copy option [
					  "toc"
					| "nums"
					| "indent"
					| "no-indent"
					| "no-toc"
					| "no-nums"
					| "no-template"
					| "no-title"
					| "old-tags"
					| "root-images"
				] (append opts to-word option)
			]
		]
		| "template" some-chars (repend opts ['template as-file text])
	]

	;-- Primary implied paragraph types:
	| example (emit code trim/auto detab code)
	| paragraph (
		either title [emit para para][emit title title: para]
	)
	| skip (debug "???WARN:  Unrecognized")
]
space: charset " ^-"
nochar: charset " ^-^/"
chars: complement nochar
spaces: [any space]
some-chars: [some space copy text some chars]
text-line:  [any space copy text thru newline]
text-block: [any space paragraph opt newline] ; ignore leading space, extra NL !???
paragraph: [copy para some [chars thru newline]]
example:   [copy code some [indented | some newline indented]]
indented:  [some space chars thru newline]
output:    [
	some space copy code thru newline
	any ["==" ["^-" | "  "] copy text thru newline (append code text)]
] 
define:    [copy text to " -" 2 skip text-block]
image: [
	left? any space copy text some chars (
		if text/1 = #"%" [remove text] ; remove %file
		text: as-file text
		emit image reduce [text pick [left center] left-flag]
	) 
]
left?: [some space "left" (left-flag: on) | none (left-flag: off)]

as-file: func [str] [to-file trim str]

;-- Output emitters:

emit: func ['word data] [
	debug ["===EMIT: " word]
	if block? word [word: do word] ;????
	if string? data [trim/tail data]
	repend out [word data]
]

emit-section: func [num] [
	emit [to-word join "sect" num] text
	title: true
]

;-- Export function to scan doc. Returns format block.
set 'scan-doc func [str /options block] [
	clear out
	title: none

	if options [
		if find block 'no-title [title: true]
	]
	emit options opts
	str: join str "^/^/###" ; makes the parse easier
	parse/all detab str rules
	if verbose [
		n: 1
		foreach [word data] out [
			print [word data]
			if (n: n + 1) > 5 [break]
		]
	]
	copy out
]
]

;-- HTML Output Generator ----------------------------------------------------

*html*: context [

;-- HTML foprmat global option variables:
no-nums:    ; Do not use numbered sections
no-toc:     ; Do not generate table of contents
no-title:   ; Do not generate a title or boilerplate
no-indent:  ; Do not indent each section
no-template: ; Do not use a template HTML page
old-tags:   ; Allow old markup convention (slower)
root-images: ; Images should be located relative to /
	none

toc-levels: 2  ; Levels shown in table of contents
image-path: "" ; Path to images

set 'gen-html func [
	doc [block!]
	/options opts [block!]
	/local title template tmp
][
	clear out ; (reused)
	group-count: 0

	; Options still need work!!!
	no-nums:
	no-toc:
	no-title:
	no-indent:
	no-template:
	old-tags:
	root-images:
		none

	set-options opts: any [opts []]
	set-options select doc 'options
	if root-images [image-path: %/]

	; Template can be provided in =template or in
	; options block following 'template. If options
	; has 'no-template, then do not use a template.
	if not no-template [
		template: any [select opts 'template select doc 'template template-file]
		if file? template [template: attempt [read template]]
		if not template [template: trim/auto default-template]
	]

	; Emit title and boilerplate:
	if not no-title [title: emit-boiler doc]

	; Emit table of contents:
	clear-sects
	if not no-toc [
		emit-toc doc
		clear-sects
	]

	prior-cmd: none
	forskip doc 2 [
		; If in a table, emit a cell each time.
		if all [
			in-table
			zero? group-count ; do not emit cell if in group
			not find [table-out table-row] doc/1 
			not find [table-in table-row] prior-cmd
		][
			emit-table-cell
		]
		switch prior-cmd: doc/1 [
			para        [emit-para doc/2]
			sect1       [emit-sect 1 doc/2]
			sect2       [emit-sect 2 doc/2]
			sect3       [emit-sect 3 doc/2]
			sect4       [emit-sect 4 doc/2]
			bullet      [emit-item doc doc/1]
			bullet2     [emit-item doc doc/1]
			bullet3     [emit-item doc doc/1]
			enum        [emit-item doc doc/1]
			enum2       [emit-item doc doc/1]
			enum3       [emit-item doc doc/1]
			code        [doc: emit-code doc]
			output      [doc: emit-code doc]
			define      [emit-def doc]
			image       [emit-image doc/2]
			table-in    [emit-table doc/2]
			table-out   [emit-table-end]
			table-row   [emit-table-row]
			center-in   [emit <center>]
			center-out  [emit </center>]
			note-in     [emit-note doc/2]
			note-out    [emit-note-end]
			group-in    [group-count: group-count + 1]
			group-out   [group-count: max 0 group-count - 1]
			indent-in   [emit <blockquote>]
			indent-out  [emit </blockquote>]
			column-in   [emit {<table border=0 cellpadding=4 width=100%><tr><td valign=top>}]
			column-out  [emit {</td></tr></table>}]
			column      [emit {</td><td valign=top>}]
		]
	]
	doc: head doc
	emit </blockquote>

	if template [
		; Template variables all begin with $
		tmp: copy template ; in case it gets reused
		replace/all tmp "$title" title
		replace/all tmp "$date" now/date
		replace tmp "$content" out
		out: tmp
	]
	reduce [title out]
]

set-options: func [options] [
	if none? options [exit]
	foreach opt [
			no-nums 
			no-toc
			no-indent
			no-template
			no-title
			old-tags
			root-images
	][if find options opt [set opt true]]
	foreach [opt word] [
			nums no-nums
			toc no-toc
			indent no-indent
	][if find options opt [set word false]]
]

;-- Default HTML Template:

default-template: {
<html>
<!--Page generated by REBOL-->
<head>
<title>$title</title>
<style type="text/css">
html, body, p, td, li {font-family: arial, sans-serif, helvetica; font-size: 10pt;}
h1 {font-size: 16pt; Font-Weight: bold;}
h2 {font-size: 14pt; color: #2030a0; Font-Weight: bold; width: 100%;
	border-bottom: 1px solid #c09060;}
h3 {font-size: 12pt; color: #2030a0; Font-Weight: bold;}
h4 {font-size: 10pt; color: #2030a0; Font-Weight: bold;}
h5 {font-size: 10pt; Font-Weight: bold;}
tt {font-family: "courier new", monospace, courier; color: darkgreen;}
pre {font: bold 10pt "courier new", monospace, console;
	background-color: #e0e0e0; padding: 16px; border: solid #a0a0a0 1px;}
.toc1 {margin-left: 1cm; font-size: 12pt; font-weight: bold;}
.toc2 {margin-left: 2cm; font-size: 10pt; Font-Weight: bold; text-decoration: none;}
.toc3 {margin-left: 3cm; font-size: 10pt; text-decoration: none;}
.toc4 {margin-left: 4cm; font-size: 10pt; color: grey; text-decoration: none;}
.output {color: #000080; font-weight: normal;}
.note {background-color: #f0e090; width: 100%; padding: 16px; border: solid #a0a0a0 1px;}
.tail {color: gray; font-size: 8pt;}
</style>
</head>
<body bgcolor="white">
<table width="660" cellpadding="4" cellspacing="0" border="0">
<tr>
<td><a href="http://www.rebol.com"><img src="http://www.rebol.net/graphics/reb-bare.jpg"
	border=0 alt="REBOL"></a></td>
</tr>
<tr height="10"><td></td></tr>
<tr><td>$content</td></tr><tr>
<tr><td><img src="http://www.rebol.net/graphics/reb-tail.jpg" border=0></td></tr>
<td align="center">
<span class="tail"><a href="http://www.rebol.com">MakeDoc2 by REBOL</a> - $date</span>
</td></tr></table>
</body></html>
}

;-- HTML Emit Utility Functions:

out: make string! 10000

emit: func [data /line] [
	; Primary emit function:
	insert insert tail out reduce data newline
]

wsp: charset " ^-^/" ; whitespace: sp, tab, return

emit-end-tag: func [tag] [
	; Emit an end tag from a tag.
	tag: copy/part tag any [find tag wsp tail tag]
	insert tag #"/"
	emit tag
]

emit-tag: func [text tag start end] [
	; Used to emit special one-sided tags:
	while [text: find text tag] [
		remove/part text length? tag
		text: insert text start
		text: insert any [find text end-char tail text] end
	]
]
end-char: charset [" " ")" "]" "." "," "^/"]

escape-html: func [text][
	; Convert to avoid special HTML chars:
	foreach [from to] html-codes [replace/all text from to]
	text
]
html-codes: ["&" "&amp;"  "<" "&lt;"  ">" "&gt;"]

emit-lines: func [text] [
	; Emit separate lines in normal font:
	replace/all text newline <br>
	emit text
]

;-- HTML Document Formatting Functions:

fix-tags: func [text] [
	if old-tags [
		emit-tag text "<c>" "<tt>" "</tt>"
		emit-tag text "<w>" "<b><tt>" "</tt></b>"
		emit-tag text "<s>" "<b><i>" "</i></b>"
	]
	text
]

emit-para: func [text] [
	; Emit standard text paragraph:
	emit [<p> fix-tags text </p>]
]

emit-code: func [doc] [
	emit <pre>
	while [
		switch doc/1 [
			code   [emit [escape-html doc/2]]
			output [emit [<span class="output"> escape-html doc/2 </span>]]
		]
	][doc: skip doc 2]
	emit </pre>
	doc: skip doc -2
]

emit-image: func [spec /local tag] [
	; Emit image. Spec = 'center or default is 'left.
	emit [
		either spec/2 = 'center [<p align="center">][<p>]
		join {<img src="} [(join image-path spec/1) {">}]
		</p>
	]
]

buls: [bullet bullet2 bullet3]
enums: [enum enum2 enum3]

bul-stack: []

push-bul: func [bul][
	if any [empty? bul-stack  bul <> last bul-stack][
		;print ['push bul mold bul-stack]
		append bul-stack bul
		emit pick [<ul><ol>] found? find buls bul
	]
]

pop-bul: func [bul /local here][
	here: any [find buls bul find enums bul]
	while [
		all [
			not empty? bul-stack
			bul <> last bul-stack
			any [
				not here ; not bullet or enum
				find next here last bul-stack
				all [here: find bul-stack bul not tail? here]
			]
		]
	][
		;print ['pop bul mold bul-stack]
		emit pick [</ul></ol>] found? find buls last bul-stack
		remove back tail bul-stack
	]
]

emit-item: func [doc item /local tag][
	push-bul item
	emit [<li> fix-tags doc/2 </li>]
	pop-bul doc/3
]

emit-def: func [doc] [
	; Emit indented definitions table. Start and end it as necessary.
	if doc/-2 <> 'define [
		emit {<table cellspacing="6" border="0" width="95%">}
	]
	emit [
		<tr><td width="20"> "&nbsp;" </td>
		<td valign="top" width="80">
		<b> any [doc/2/1 "&nbsp;"] </b></td>
		<td valign="top"> fix-tags any [doc/2/2 " "] </td>
		</tr>
	]
	if doc/3 <> 'define [emit {</table>}]
]

emit-note: func [text] [
	; Start a note sidebar, centered on page:
	emit [<p><fieldset class="fset"><legend> fix-tags text </legend>]
]

emit-note-end: does [
	; End a note sidebar.
	emit </fieldset></p>
]

in-table: in-header: false

emit-table: does [
	in-table: true
	in-header: true
	emit {<table border="0" cellspacing="1" cellpadding="4" bgcolor="#505050">
		<tr bgcolor="silver"><td><b>}
]

emit-table-end: does [
	in-table: false
	emit "</td></tr></table>"
]

emit-table-cell: does [ 
	emit pick [{</b></td><td><b>} {</td><td valign="top" bgcolor="white">}] in-header
]

emit-table-row: does [
	in-header: false
	emit {</td></tr><tr><td valign="top" bgcolor="white">}
]

;-- Section handling:

clear-sects: does [sects: 0.0.0.0]

next-section: func [level /local bump mask] [
	; Return next section number. Clear sub numbers.
	set [bump mask] pick [
		[1.0.0.0 1.0.0.0]
		[0.1.0.0 1.1.0.0]
		[0.0.1.0 1.1.1.0]
		[0.0.0.1 1.1.1.1]
	] level
	level: form sects: sects + bump * mask
	clear find level ".0"
	level
]

make-heading: func [level num str /toc /local lnk][
	; Make a proper heading link or TOC target.
	; Determine link target str. Search for [target] in front of heading.
	either parse str [
		"[" copy lnk to "]"
		s: to end
	][
		str: next s ; remove link target
	][
		lnk: join "section-" num
	]
	if not no-nums [str: rejoin [num pick [". " " "] level = 1 str]]
	rejoin either toc [
		[{<a class="toc} level {" href="#} lnk {">} str </a>]
	][
		[{<h} level + 1 { id="} lnk {">} str {</h} level + 1 {>}]
	]
]

emit-sect: func [level str /local sn] [
	; Unindent prior level:
	if all [not no-indent level <= 2 sects/1 > 0] [emit </blockquote>]
	sn: next-section level
	emit make-heading level sn str
	if all [not no-indent level <= 2] [emit <blockquote>]
]

emit-toc: func [doc /local w sn] [
	; Output table of contents:
	emit [<h2> "Contents:" </h2>]
	foreach [word str] doc [
		if w: find [sect1 sect2 sect3 sect4] word [
			w: index? w
			if w <= toc-levels [
				sn: next-section w
				emit [make-heading/toc w sn str <br>]
			]
		]
	]
]

emit-boiler: func [doc /local title info temp] [
	; Output top boiler plate:
	title: any [
		select doc 'title
		select doc 'sect1
		"Untitled"
	]
	emit [<h1> title </h1>]
	foreach [word val] doc [
		if word = 'code [
			emit {<blockquote><b>}
			emit-lines val
			emit {</b></blockquote>}
			remove/part find doc 'code 2
			break
		]
		if not find [title template options] word [break]
	]
	title
]

]

do-makedoc: has [in-view? file msg doc] [

	in-view?: all [value? 'view? view?] ; Are we using View?

	; Get the file name from the script argument:
	file: system/script/args
	if any-string? file [file: to-file file] ; makes copy too

	; If no file provided, should we do the last file again?
	if all [
		not file
		exists? %last-file.tmp
	][
		file: load %last-file.tmp
		either confirm reform ["Reprocess" file "?"] [
			system/script/args: none
		][
			file: none
		]
	]

	; If no file still, then ask the user for the file name:
	if not file [
		either in-view? [
			file: request-file/only
		][
			file: ask "Filename? "
			file: all [not empty? trim file to-file file]
		]
	]

	; No file provided:
	if not file [exit]

	; File must exist:
	if not exists? file [
		msg: reform ["Error:" file "does not exist"]
		either in-view? [alert msg] [ask msg]
		exit
	]

	; Save this as the last file processed:
	save %last-file.tmp file

	; Process the file. Returns [title doc]
	doc: second gen-html scan-doc read file

	; Create output file name:
	append clear find/last file #"." ".html"
	write file doc

	if all [in-view? not system/script/args] [browse file]
	file ; return new file (entire path)
]

; Start process (but caller may request it only be loaded):
if system/script/args <> 'load-only [do-makedoc]

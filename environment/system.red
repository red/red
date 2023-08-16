Red [
	Title:   "Red system object definition"
	Author:  "Nenad Rakocevic"
	File: 	 %system.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

system: context [
	version: #do keep [form load-cache %encapper/version.r]
	build: context [
		date: #do keep [
			use [date][
				date: now
				date: date - date/zone
				date/zone: none
				date
			]
		]
		git: #do keep [load-cache %build/git.r]
		config: context #do keep [reduce [load find mold config to-char 91]]
	]
	
	words: #system [
		__make-sys-object: func [
			/local
				obj [red-object!]
				s	[series!]
		][
			obj: as red-object! stack/push*
			obj/header: TYPE_OBJECT
			obj/ctx:	global-ctx
			obj/class:	-1
			obj/on-set:	null
			
			s: as series! global-ctx/value
			copy-cell as red-value! obj s/offset + 1		;-- set back-reference
		]
		__make-sys-object
	]

	platform: #do keep [to-lit-word config/OS]
	
	catalog: context [
		datatypes:
		actions:
		natives: none
		
		accessors: [
			date!	[
				date year month day zone time hour minute second weekday yearday
				timezone week isoweek julian
			]
			email!	[user host]
			event!	[
				type face window offset key picked flags orientation away? down? mid-down?
				alt-down? aux-down? ctrl? shift?
			]
			image!	[size argb rgb alpha]
			pair!	[x y]
			point2D![x y]
			point3D![x y z]
			time!	[hour minute second]
			money!  [code amount]
		]
		
		errors: context [
			throw: object [
				code:				0
				type:				"Throw Error"
				break:				"no loop to break"
				return:				"return or exit not in function"
				throw:				["no catch for throw:" :arg1]
				continue:			"no loop to continue"
				while-cond:			"BREAK/CONTINUE cannot be used in WHILE condition block"
			]
			note: object [
				code:				100
				type:				"note"
				no-load:			["cannot load: " :arg1]
			]
			syntax: object [
				code:				200
				type:				"Syntax Error"
				invalid:			[:arg1 "invalid" :arg2 "at" :arg3]
				missing:			[:arg1 "missing" :arg2 "at"  :arg3]
				no-header:			["script is missing a Red header:" :arg1]
				no-rs-header:		["script is missing a Red/System header:" :arg1]
				bad-header:			["script header is not valid:" :arg1]
				malconstruct:		[:arg1 "invalid construction spec at" :arg2]
				bad-char:			[:arg1 "invalid character at" :arg2]
			]
			script: object [
				code:				300
				type:				"Script Error"
				no-value:			[:arg1 "has no value"]
				need-value:			[:arg1 "needs a value"]
				not-defined:		[:arg1 "word is not bound to a context"]
				not-in-context:		["context for" :arg1 "is not available"]
				no-arg:				[:arg1 "is missing its" :arg2 "argument"]
				expect-arg:			[:arg1 "does not allow" :arg2 "for its" :arg3 "argument"]
				expect-val:			["expected" :arg1 "not" :arg2]
				expect-type:		[:arg1 :arg2 "field must be of type" :arg3]
				cannot-use:			["cannot use" :arg1 "on" :arg2 "value"]
				invalid-arg:		["invalid argument:" :arg1]
				invalid-type:		[:arg1 "type is not allowed here"]
				invalid-type-spec:	["invalid type specifier:" :arg1]
				invalid-op:			["invalid operator:" :arg1]
				no-op-arg:			[:arg1 "operator is missing an argument"]
				bad-op-spec:		"making an op! requires a function with only 2 arguments and no lit/get-word on left argument"
				invalid-data:		["data not in correct format:" :arg1]
				invalid-part:		["invalid /part count:" :arg1]
				not-same-type:		"values must be of the same type"
				not-same-class:		["cannot coerce" :arg1 "to" :arg2]
				not-related:		["incompatible argument for" :arg1 "of" :arg2]
				bad-func-def:		["invalid function definition:" :arg1]
				bad-func-arg:		["function argument" :arg1 "is not valid"]
				bad-func-extern:	["invalid /extern value:" :arg1]
				no-refine:			[:arg1 "has no refinement called" :arg2]
				bad-refines:		"incompatible or invalid refinements"
				bad-refine:			["incompatible refinement:" :arg1]
				dup-refine:			["duplicate refinement usage in:" :arg1]
				word-first:			["path must start with a word:" :arg1]
				empty-path:			"cannot evaluate an empty path value"
				unset-path:			[:arg2 "is unset in path" :arg1]
				invalid-path:		["cannot access" :arg2 "in path" :arg1]
				invalid-path-set:	["unsupported type in" :arg1 "set-path"]
				invalid-path-get:	["unsupported type in" :arg1 "get-path"]
				bad-path-type:		["path" :arg1 "is not valid for" :arg2 "type"]
				bad-path-type2:		["path element >" :arg1 "< does not apply to" :arg2 "type"]
				bad-path-set:		["cannot set" :arg2 "in path" :arg1]
				bad-field-set:		["cannot set" :arg1 "field to" :arg2 "datatype"]
				dup-vars:			["duplicate variable specified:" :arg1]
				past-end:			"out of range or past end"
				missing-arg:		"missing a required argument or refinement"
				out-of-range:		["value out of range:" :arg1]
				invalid-chars:		"contains invalid characters"
				invalid-compare:	["cannot compare" :arg1 "with" :arg2]
				wrong-type:			["datatype assertion failed for:" :arg1]
				invalid-refine-arg: ["invalid" :arg1 "argument:" :arg2]
				type-limit:			[:arg1 "overflow/underflow"]
				size-limit:			["maximum limit reached:" :arg1]
				no-return:			"block did not return a value"
				throw-usage:		"invalid use of a thrown error value"
				locked-word:		["protected word - cannot modify:" :arg1]
				protected:			"protected value or series - cannot modify"
				;self-protected:	"cannot set/unset self - it is protected"
				bad-bad:			[:arg1 "error:" :arg2]
				bad-make-arg:		["cannot MAKE" :arg1 "from:" :arg2]
				bad-to-arg:			["cannot MAKE/TO" :arg1 "from:" :arg2]
				invalid-months:		"invalid system/locale/month list"
				invalid-spec-field: ["invalid" :arg1 "field in spec block"]
				missing-spec-field: [:arg1 "not found in spec block"]
				move-bad:			["Cannot MOVE elements from" :arg1 "to" :arg2]
				too-long:			"Content too long"
				invalid-char:		["Invalid char! value:" :arg1]
				bad-loop-series:	["Loop series changed to invalid value:" :arg1]
				;bad-decode:		"missing or unsupported encoding marker"
				;already-used:		["alias word is already in use:" :arg1]
				wrong-denom:		[:arg1 "not same denomination as" :arg2]
				bad-denom:			["invalid denomination:" :arg1]
				;bad-press:			["invalid compressed data - problem:" :arg1]
				;dialect:			["incorrect" :arg1 "dialect usage at:" :arg2]
				invalid-obj-evt:	["invalid object event handler:" :arg1]
				parse-rule:			["PARSE - invalid rule or usage of rule:" :arg1]
				parse-end:			["PARSE - unexpected end of rule after:" :arg1]
				;parse-variable:	["PARSE - expected a variable, not:" :arg1]
				;parse-command:		"PARSE - command cannot be used as variable:" :arg1]
				parse-invalid-ref:	["PARSE - get-word refers to a different series!" :arg1]
				parse-block:		["PARSE - input must be of any-block! type:" :arg1]
				parse-unsupported:	"PARSE - matching by datatype not supported for any-string! input"
				parse-infinite:		["PARSE - infinite recursion at rule: [" :arg1 "]"]
				parse-stack:		"PARSE - stack limit reached"
				parse-keep:			"PARSE - KEEP is used without a wrapping COLLECT"
				parse-into-bad:		"PARSE - COLLECT INTO/AFTER invalid series! argument"
				parse-into-type:    "PARSE - COLLECT INTO/AFTER expects a series! of compatible datatype"
				invalid-draw:		["invalid Draw dialect input at:" :arg1]
				invalid-data-facet: ["invalid DATA facet content" :arg1]
				face-type:			["VIEW - invalid face type:" :arg1]
				not-window:			"VIEW - expected a window root face"
				bad-window:			"VIEW - a window face cannot be nested in another window"
				not-linked:			"VIEW - face not linked to a window"
				not-event-type:		["VIEW - not a valid event type" :arg1]
				invalid-facet-type:	["VIEW - invalid rate value:" :arg1]
				vid-invalid-syntax:	["VID - invalid syntax at:" :arg1]
				rtd-invalid-syntax: ["RTD - invalid syntax at:" :arg1]
				rtd-no-match:		["RTD - opening/closing tag not matching for:" :arg1]
				react-bad-func:		"REACT - /LINK option requires a function! as argument"
				react-not-enough:	"REACT - reactive functions must accept at least 2 arguments"
				react-no-match:		"REACT - objects block length must match reaction function arg count"
				react-bad-obj:		"REACT - target can only contain object values"
				react-gctx:			["REACT - word" :arg1 "is not a reactor's field"]
				lib-invalid-arg:	["LIBRED - invalid argument for" :arg1]
			]
			math: object [
				code:				400
				type:				"Math Error"
				zero-divide:		"attempt to divide by zero"
				overflow:			"math or number overflow"
				positive:			"positive number required"
			]
			access: object [
				code:				500
				type:				"Access Error"
				cannot-open:		["cannot open:" :arg1]
				cannot-close:		["cannot close:" :arg1]
				invalid-utf8:		["invalid UTF-8 encoding:" :arg1]
				not-open:			["port is not open:" :arg1]
				;already-open:		["port is already open:" :arg1]
				no-connect:			["cannot connect:" :arg1 "reason: timeout"]
				;not-connected:		["port is not connected:" :arg1]
				;no-script:			["script not found:" :arg1]
				;no-scheme-name:	["new scheme must have a name:" :arg1]
				no-scheme:			["missing port scheme:" :arg1]
				unknown-scheme:		["scheme is unknown:" :arg1]
				invalid-spec:		["invalid spec or options:" :arg1]
				invalid-port:		["invalid port object (invalid field values)"]
				invalid-actor:		["invalid port actor (must be handle or object)"]
				;invalid-port-arg:	["invalid port argument:" arg1]
				no-port-action:		"port action not supported"
				;protocol:			["protocol error:" :arg1]
				;invalid-check:		["invalid checksum (tampered file):" :arg1]
				;write-error:		["write failed:" :arg1 "reason:" :arg2]
				;read-error:		["read failed:" :arg1 "reason:" :arg2]
				;read-only:			["read-only - write not allowed:" :arg1]
				;no-buffer:			["port has no data buffer:" :arg1]
				;timeout:			["port action timed out:" :arg1]
				no-create:			["cannot create:" :arg1]
				;no-delete:			["cannot delete:" :arg1]
				;no-rename:			["cannot rename:" :arg1]
				;bad-file-path:		["bad file path:" :arg1]
				;bad-file-mode:		["bad file mode:" :arg1]
				;security:			["security violation:" :arg1 " (refer to SECURE function)"]
				;security-level:	["attempt to lower security to" :arg1]
				;security-error:	["invalid" :arg1 "security policy:" :arg2]
				no-codec:			["cannot decode or encode (no codec):" :arg1]
				bad-media:			["bad media data (corrupt image, sound, video)"]
				;no-extension:		["cannot open extension:" :arg1]
				;bad-extension:		["invalid extension format:" :arg1]
				;extension-init:	["extension cannot be initialized (check version):" :arg1]
				;call-fail:			["external process failed:" :arg1]
				invalid-cmd:		["invalid port command:" :arg1]
			]
			reserved1: object [
				code:				600
				type:				"Reserved1 Error"
			]
			reserved2: object [
				code:				700
				type:				"Reserved2 Error"
			]
			user: object [
				code:				800
				type:				"User Error"
				message:			'arg1
			]
			internal: object [
				code:				900
				type:				"Internal Error"
				bad-path:			["bad path:" arg1]
				not-here:			[arg1 "not supported on your system"]
				no-memory:			"not enough memory"
				wrong-mem:			"failed to release memory"
				stack-overflow:		"stack overflow"
				;bad-series:		"invalid series"
				limit-hit:			["internal limit reached:" :arg1]
				;bad-sys-func:		["invalid or missing system function:" :arg1]
				too-deep:			"block or paren series is too deep to display"
				no-cycle:			"circular reference not allowed"
				feature-na:			"feature not available"
				not-done:			"reserved for future use (or not yet implemented)"
				invalid-error:		["invalid error object field value:" :arg1]
				routines:			"routines require compilation, from OS shell: `red -r <script.red>`"
				red-system:			"contains Red/System code which requires compilation"
				deprecated:			[arg1 "is DEPRECATED, please use" arg2 "instead"]
			]
		]

	]
	
	state: context [
		interpreted?: func ["Return TRUE if called from the interpreter"][
			#system [logic/box stack/eval? null no]
		]
		last-error:  none
		stack-trace: 1									;-- 0: disabled
		
		callbacks: object [
			lexer?: 	  no							;-- called by transcode/trace
			parse?:		  no							;-- called by parse/trace
			sort?:		  no							;-- called by sort/compare
			change?:	  no							;-- called by object's on-change*
			deep?:		  no							;-- called by object's on-deep-change*
			port?:		  no							;-- called by port's action dispatcher
			bits:		  0								;-- (internal) automatically set

			on-change*: function [word old new][
				unless integer? bits [set-quiet 'bits 0]	;-- prevents tampering with that field
				idx: 1 << ((index? word) - 1)
				set-quiet 'bits either new [bits or idx][bits and complement idx]
			]
		]
	]
	
	modules: make block! 8
	codecs:  make map!   8
	schemes: make block! 10
	ports:	 context []
	
	locale: context [
		language:
		language*:										;-- in locale language
		locale:
		locale*: none									;-- in locale language

		months: [
		  "January" "February" "March" "April" "May" "June"
		  "July" "August" "September" "October" "November" "December"
		]

		days: [
		  "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"
		]
		
		currencies: context [
			;-- ISO currencies + BTC, ETH, RED
			list: [
				AED AFN ALL AMD ANG AOA ARS AUD AWG AZN BAM BBD BDT BTC BGN BHD BIF BMD BND BOB BRL BSD
				BTN	BWP BYN BZD CAD CDF CHF CKD CLP CNY COP CRC CUC CUP CVE CZK DJF DKK DOP DZD EGP ERN
				ETB ETH	EUR FJD FKP FOK GBP GEL GGP GHS GIP GMD GNF GTQ GYD HKD HNL HRK HTG HUF IDR ILS
				IMP INR	IQD IRR ISK JEP JMD JOD JPY KES KGS KHR KID KMF KPW KRW KWD KYD KZT LAK LBP LKR
				LRD LSL	LYD MAD MDL MGA MKD MMK MNT MOP MRU MUR MVR MWK MXN MYR MZN NAD NGN NIO NOK NPR
				NZD OMR	PAB PEN PGK PHP PKR PLN PND PRB PYG QAR RED RON RSD RUB RWF SAR SBD SCR SDG SEK
				SGD SHP SLL	SLS SOS SRD SSP STN SYP SZL THB TJS TMT TND TOP TRY TTD TVD TWD TZS UAH UGX
				USD UYU UZS	VES VND VUV WST CFA XAF XCD XOF CFP XPF YER ZAR ZMW
			]
			on-change*: func [word old new][
				set-quiet word old
				cause-error 'script 'protected []
			]
			on-deep-change*: func [owner word target action new index part][
				if any [
					word <> 'list
					not find [append appended] action
					not word? :new
					all [action = 'append any [find list new 255 < length? list]] ;-- limit index to 8-bit
					3 <> length? form new
				][cause-error 'script 'protected []]
				
				if action = 'appended [set-slot-quiet back tail list to word! uppercase form new]
			]
		]
	]
	
	options: context [
		boot: 			none
		home: 			none
		path: 			to-red-file get-current-dir
		script: 		none
		cache:			none
		thru-cache:		none
		args: 			none
		do-arg: 		none
		debug: 			none
		secure: 		none
		quiet: 			false
		binary-base: 	16
		decimal-digits: 15
		money-digits:	2
		module-paths: 	make block! 1
		file-types: 	none
		
		;-- change the way float numbers are processed
		float: context [
			pretty?: true
			full?: 	 false
			
			on-change*: func [word old new][
				switch word [
					pretty? [
						either new [
							#system [float/pretty-print?: yes]
						][
							#system [float/pretty-print?: no]
						]
					]
					full? [
						either new [
							#system [float/full-support?: yes]
						][
							#system [float/full-support?: no]
						]
					]
				]
			]
		]

		on-change*: func [word old new][
			if word = 'path [
				either file? :new [set-current-dir new][
					set word old
					cause-error 'script 'invalid-type reduce [type? :new]
				]
			]
		]

		on-deep-change*: function [owner word target action new index part][
			if all [
				word = 'path
				not find [remove clear take] action
			][
				set-current-dir new
			]
		]
	]
	
	script: context [
		title: header: parent: path: none
		args: #system [
			#either type = 'exe [stack/push get-cmdline-args][none/push]
		]
	]
	
	standard: context [									;-- do not change object fields number/order
		header: object [
			Title: Name: Type: Version: Date: File: Home: Author: Tabs: Needs: License: Note: History: none
		]
		port: object [
			spec: scheme: actor: awake: state: data: extra: none
		]
		error: object [
			code: type: id: arg1: arg2: arg3: near: where: stack: none
		]
		file-info: object [
			name: size: date: type: none
		]
		url-parts: object [
			scheme: user-info: host: port: path: target: query: fragment: ref: none
		]
		scheme: object [
			name: title: info: actor: awake: none
		]
	]
	
	lexer: context [
		pre-load: none
		
		exit-states: reduce [
			'eof error! block! block! paren! paren! string! string! map! path! datatype!
			'comment string! word! issue! integer! refinement! char! file! binary! percent!
			float! float! tuple! date! pair! time! money! tag! url! email! 'hex 'rawstring ref!
		]
		
		tracer: func [
			event  [word!]                  			;-- event name
			input  [string! binary!]            		;-- input series at current loading position
			type   [datatype! word! none!]       		;-- type of token or value currently processed.
			line   [integer!]               			;-- current input line number
			token                      					;-- current token as an input slice (pair!) or a loaded value.
			return: [logic!]                			;-- YES: continue to next lexing stage, NO: cancel current token lexing
		][
			print [										;-- total: 64
				uppercase pad event 8
				pad mold type 12
				pad mold/part token 12 12				;-- limit in case it's a huge string/binary
				pad line 4
				mold/part input 16
			]
			either event = 'error [input: next input no][yes]
		]
	]
	
	console:	none
	view:		none
	reactivity: none
	tools:		none
]

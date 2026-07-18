REBOL [
	Title:   "Mach-O linker-signed ad-hoc code signature emitter"
	File:    %Mach-O-sign.r
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

macho-code-sign: context [
	page-size: 16384
	code-directory-header-size: 88
	superblob-header-size: 20

	append-be32: func [out [binary!] value [integer! char!]][
		append out sha256/word-to-binary to integer! value
	]

	append-be64: func [out [binary!] value [integer!]][
		append out #{00000000}
		append-be32 out value
	]

	code-slot-count: func [code-limit [integer!]][
		(round/to/ceiling code-limit page-size) / page-size
	]

	size?: func [code-limit [integer!] identifier [string!] /local code-directory-size][
		code-directory-size: code-directory-header-size + 1 + (length? identifier)
			+ (32 * (code-slot-count code-limit))
		round/to/ceiling (superblob-header-size + code-directory-size) 8
	]

	build-load-command: func [data-offset data-size [integer!] /local out][
		out: make binary! 16
		append out to-bin32 29                                ; LC_CODE_SIGNATURE
		append out to-bin32 16
		append out to-bin32 data-offset
		append out to-bin32 data-size
		out
	]

	build: func [
		image [binary!]
		code-limit [integer!]
		identifier [string!]
		executable-size [integer!]
		main? [logic!]
		/local out slots hash-offset code-directory-size blob-length hashes
	][
		if code-limit <> (length? image) [
			make error! rejoin [
				"invalid Mach-O code limit " code-limit " for " (length? image) " bytes"
			]
		]
		slots: code-slot-count code-limit
		hash-offset: code-directory-header-size + 1 + (length? identifier)
		code-directory-size: hash-offset + (32 * slots)
		blob-length: superblob-header-size + code-directory-size
		out: make binary! round/to/ceiling blob-length 8

		append-be32 out to integer! #{FADE0CC0}               ; CSMAGIC_EMBEDDED_SIGNATURE
		append-be32 out blob-length
		append-be32 out 1                                      ; one CodeDirectory slot
		append-be32 out 0                                      ; CSSLOT_CODEDIRECTORY
		append-be32 out superblob-header-size

		append-be32 out to integer! #{FADE0C02}               ; CSMAGIC_CODEDIRECTORY
		append-be32 out code-directory-size
		append-be32 out 132096                                 ; CS_SUPPORTSEXECSEG (0x20400)
		append-be32 out 131074                                 ; CS_ADHOC | CS_LINKER_SIGNED
		append-be32 out hash-offset
		append-be32 out code-directory-header-size
		append-be32 out 0                                      ; nSpecialSlots
		append-be32 out slots
		append-be32 out code-limit
		append out #{2002000E}                                 ; SHA-256, 16 KiB pages
		append-be32 out 0                                      ; spare2
		append-be32 out 0                                      ; scatterOffset
		append-be32 out 0                                      ; teamOffset
		append-be32 out 0                                      ; spare3
		append-be64 out 0                                      ; codeLimit64
		append-be64 out 0                                      ; __TEXT file offset
		append-be64 out executable-size
		append-be64 out either main? [1][0]                   ; CS_EXECSEG_MAIN_BINARY
		append out to binary! identifier
		append out #{00}

		hashes: sha256/digest-pages image code-limit page-size
		append out hashes
		insert/dup tail out #{00} (round/to/ceiling blob-length 8) - length? out
		out
	]
]

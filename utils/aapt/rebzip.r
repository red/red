;; ==================================================
;; Script: rebzip.r
;; downloaded from: www.REBOL.org
;; on: 10-Aug-2014
;; at: 2:44:22.682826 UTC
;; owner: vincentecuye [script library member who can
;; update this script]
;; ==================================================
REBOL [
    Title: "rebzip"
    Date: 17-Jul-2009
    Version: 1.0.1
    File: %rebzip.r
    Author: "Vincent Ecuyer"
    Purpose: "Zip archiver / unarchiver"
    Usage: {
        Two functions: 'zip and 'unzip

        [archiving: zip]

        you can zip a single file:
            zip %new-zip.zip %my-file

        a block of files:
            zip %new-zip.zip [%file-1.txt %file-2.exe]

        a block of data (binary!/string!) and files:
            zip %new-zip.zip [%my-file "my data"]

        a entire directory:
            zip/deep %new-zip.zip %my-directory/

        from an url:
            zip %new-zip.zip ftp://192.168.1.10/my-file.txt

        any combinaison of these:
            zip/deep %new-zip.zip  [
                %readme.txt "An example"
                ftp://192.168.1.10/my-file.txt
                %my-directory
            ]

        [unarchiving: unzip]
        ! only works from REBOL/View,
        ! only understands methods 'store and 'deflate

        you can uncompress to a directory (created if inexistant):
            unzip %my-new-dir %my-zip-file.zip

        or a block:
            unzip my-block %my-zip-file.zip

            my-block == [%file-1.txt #{...} %file-2.exe #{...}]
    }
    Comment: {
        'compress uses a zlib compatible format - always with
        deflate algorithm, 32k window size, max compression
        and no dictionary - followed by adler-32 checksum (4 bytes)
        and uncompressed data length (4 bytes).

        'deflate method is used in gzip, PiNG, and in most .zip files.

        For decompression, as the adler-32 checksum is unknown,
        a PiNG file is build with the data to decompress, letting
        'load to do the work.
    }
    History: [
        1.0.0 [13-Jan-2005 "First version"]
        1.0.1 [17-Jul-2009 "Bugfix: empty files compressed with 'deflate now properly handled"]
    ]
    Library: [
        level: 'advanced
        platform: 'all
        type: [module tool]
        domain: [compression file-handling files]
        tested-under: [
            view 1.2.1.3.1 on [Win2K]
            view 1.2.1.1.1 on [AmigaOS30]
            view 1.2.57.3.1 on [Win2K]
            view 2.7.6.4.2 on [Linux]
        ]
        support: none
        license: 'public-domain
        see-also: %zip-fix.r
    ]
]

ctx-zip: context [
    crc-long: [
                 0   1996959894  -301047508 -1727442502   124634137  1886057615
        -379345611  -1637575261   249268274  2044508324  -522852066 -1747789432
         162941995   2125561021  -407360249 -1866523247   498536548  1789927666
        -205950648  -2067906082   450548861  1843258603  -187386543 -2083289657
         325883990   1684777152   -43845254 -1973040660   335633487  1661365465
         -99664541  -1928851979   997073096  1281953886  -715111964 -1570279054
        1006888145   1258607687  -770865667 -1526024853   901097722  1119000684
        -608450090  -1396901568   853044451  1172266101  -589951537 -1412350631
         651767980   1373503546  -925412992 -1076862698   565507253  1454621731
        -809855591  -1195530993   671266974  1594198024  -972236366 -1324619484
         795835527   1483230225 -1050600021 -1234817731  1994146192    31158534
       -1731059524   -271249366  1907459465   112637215 -1614814043  -390540237
        2013776290    251722036 -1777751922  -519137256  2137656763   141376813
       -1855689577   -429695999  1802195444   476864866 -2056965928  -228458418
        1812370925    453092731 -2113342271  -183516073  1706088902   314042704
       -1950435094    -54949764  1658658271   366619977 -1932296973   -69972891
        1303535960    984961486 -1547960204  -725929758  1256170817  1037604311
       -1529756563   -740887301  1131014506   879679996 -1385723834  -631195440
        1141124467    855842277 -1442165665  -586318647  1342533948   654459306
       -1106571248   -921952122  1466479909   544179635 -1184443383  -832445281
        1591671054    702138776 -1328506846  -942167884  1504918807   783551873
       -1212326853  -1061524307  -306674912 -1698712650    62317068  1957810842
        -355121351  -1647151185    81470997  1943803523  -480048366 -1805370492
         225274430   2053790376  -468791541 -1828061283   167816743  2097651377
        -267414716  -2029476910   503444072  1762050814  -144550051 -2140837941
         426522225   1852507879   -19653770 -1982649376   282753626  1742555852
        -105259153  -1900089351   397917763  1622183637  -690576408 -1580100738
         953729732   1340076626  -776247311 -1497606297  1068828381  1219638859
        -670225446  -1358292148   906185462  1090812512  -547295293 -1469587627
         829329135   1181335161  -882789492 -1134132454   628085408  1382605366
        -871598187  -1156888829   570562233  1426400815  -977650754 -1296233688
         733239954   1555261956 -1026031705 -1244606671   752459403  1541320221
       -1687895376   -328994266  1969922972    40735498 -1677130071  -351390145
        1913087877     83908371 -1782625662  -491226604  2075208622   213261112
       -1831694693   -438977011  2094854071   198958881 -2032938284  -237706686
        1759359992    534414190 -2118248755  -155638181  1873836001   414664567
       -2012718362    -15766928  1711684554   285281116 -1889165569  -127750551
        1634467795    376229701 -1609899400  -686959890  1308918612   956543938
       -1486412191   -799009033  1231636301  1047427035 -1362007478  -640263460
        1088359270    936918000 -1447252397  -558129467  1202900863   817233897
       -1111625188   -893730166  1404277552   615818150 -1160759803  -841546093
        1423857449    601450431 -1285129682 -1000256840  1567103746   711928724
       -1274298825  -1022587231  1510334235   755167117
   ]

    right-shift-8: func [
        "Right-shifts the value by 8 bits and returns it."
        value [integer!] "The value to shift"
    ][
        either negative? value [
            -1 xor value and -256 / 256 xor -1 and 16777215
        ][
            -256 and value / 256
        ]
    ]

    update-crc: func [
        "Returns the data crc."
        data [any-string!] "Data to checksum"
        crc [integer!] "Initial value"
    ][
        foreach char data [
             crc: (right-shift-8 crc) xor pick crc-long crc and 255 xor char + 1
        ]
    ]

    crc-32: func [
        "Returns a CRC32 checksum."
        data [any-string!] "Data to checksum"
    ][
        either empty? data [#{00000000}][
            load join "#{" [to-hex -1 xor update-crc data -1 "}"]
        ]
    ]

    ;signatures
    local-file-sig: to-string #{504B0304}
    central-file-sig: to-string #{504B0102}
    end-of-central-sig: to-string #{504B0506}
    data-descriptor-sig: to-string #{504B0708}

    ;conversion funcs
    to-ilong: func [
        "Converts an integer to a little-endian long."
        value [integer!] "Value to convert"
    ][
        to-binary rejoin [
            to-char value and 255
            to-char to-integer (value and 65280) / 256
            to-char to-integer (value and 16711680) / 65536
            to-char to-integer (value / 16777216)
        ]
    ]
    to-ishort: func [
        "Converts an integer to a little-endian short."
        value [integer!] "Value to convert"
    ][
        to-binary rejoin [
            to-char value and 255
            to-char to-integer value / 256
        ]
    ]
    to-long: func [
        "Converts an integer to a big-endian long."
        value [integer!] "Value to convert"
    ][do join "#{" [to-hex value "}"]]
    get-ishort: func [
        "Converts a little-endian short to an integer."
        value [any-string! port!] "Value to convert"
    ][to-integer head reverse to-binary copy/part value 2]
    get-ilong: func [
        "Converts a little-endian long to an integer."
        value [any-string! port!] "Value to convert"
    ][to-integer head reverse to-binary copy/part value 4]
    to-msdos-time: func [
        "Converts to a msdos time."
        value [time!] "Value to convert"
    ][
        to-ishort (value/hour * 2048)
            or (value/minute * 32)
            or (to-integer value/second / 2)
    ]
    to-msdos-date: func [
        "Converts to a msdos date."
        value [date!] "Value to convert"
    ][
        to-ishort 512 * (max 0 value/year - 1980)
            or (value/month * 32) or value/day
    ]
    get-msdos-time: func [
        "Converts from a msdos time."
        value [any-string! port!] "Value to convert"
    ][
        value: get-ishort value
        to-time reduce [
            63488 and value / 2048
            2016 and value / 32
            31 and value * 2
        ]
    ]
    get-msdos-date: func [
        "Converts from a msdos date."
        value [any-string! port!] "Value to convert"
    ][
        value: get-ishort value
        to-date reduce [
            65024 and value / 512 + 1980
            480 and value / 32
            31 and value
        ]
    ]

    set 'zip-entry: func [
{Compresses a file and returns [
         local file header + compressed file
         central file directory entry
     ]}
        name [file!] "Name of file"
        date [date!] "Modification date of file"
        data [any-string!] "Data to compress"
    /store
    /digest
    /local
        crc method compressed-data uncompressed-size compressed-size
        sha1 entry
    ][
		if digest [sha1: checksum/method data 'SHA1]

        ; info on data before compression
        crc: head reverse crc-32 data
        uncompressed-size: to-ilong length? data

        either any [store empty? data] [
            method: 'store
        ][
            ; zlib stream
            compressed-data: compress data
            ; if compression inefficient, store the data instead
            either (length? data) > (length? compressed-data) [
                data: copy/part
                    skip compressed-data 2
                    skip tail compressed-data -8
                method: 'deflate
            ][
                method: 'store
                clear compressed-data
            ]
        ]

        ; info on data after compression
        compressed-size: to-ilong length? data

        entry: reduce [
            ; local file entry
            join #{} [
                local-file-sig
                #{0000} ; version
                #{0000} ; flags
                either method = 'store [
                    #{0000} ; method = store
                ][
                    #{0800} ; method = deflate
                ]
                to-msdos-time date/time
                to-msdos-date date/date
                crc     ; crc-32
                compressed-size
                uncompressed-size
                to-ishort length? name ; filename length
                #{0000} ; extrafield length
                name    ; filename
                        ; no extrafield
                data    ; compressed data
            ]
            ; central-dir file entry
            join #{} [
                central-file-sig
                #{0000} ; version source
                #{0000} ; version min
                #{0000} ; flags
                either method = 'store [
                    #{0000} ; method = store
                ][
                    #{0800} ; method = deflate
                ]
                to-msdos-time date/time
                to-msdos-date date/date
                crc     ; crc-32
                compressed-size
                uncompressed-size
                to-ishort length? name ; filename length
                #{0000} ; extrafield length
                #{0000} ; filecomment length
                #{0000} ; disknumber start
                #{0000} ; internal attributes
                #{00000000} ; external attributes
                #{00000000} ; header offset
                name    ; filename
                        ; extrafield
                        ; comment
            ]
        ]
        either digest [reduce [entry name sha1]][entry]
    ]

    any-file?: func [
        "Returns TRUE for file and url values." value [any-type!]
    ][any [file? value url? value]]

    to-path-file: func [
        {Converts url! to file! and removes heading "/"}
        value [file! url!] "Value to convert"
    ][
        if file? value [
            if #"/" = first value [value: copy next value]
            return value
        ]
        value: decode-url value
        join %"" [
            value/host "/"
            any [value/path ""]
            any [value/target ""]
        ]
    ]

	zip-align: func [
		entry [binary!]
		file-size  [integer!]
		/alignment k [integer!]
		/local name-length data-offset pad
	][
		unless alignment [k: 4]
		if zero? entry/9 [							; method = 'store
			name-length: copy/part skip entry 26 2
			name-length: to-integer reverse name-length
			data-offset: file-size + 30 + name-length
			unless zero? mod data-offset k [		; padding in extra field
				pad: k - mod data-offset k
				change skip entry 28 to-ishort pad
				insert/dup skip entry 30 + name-length #"^@" pad
			]
		]
	]

	set 'package-all-entries func [
{Builds a zip archive from a block of zip-entrys.
     Returns number of entries in archive.}
        where [file! url! binary! string!] "Where to build it"
        source [block!] "zip entrys to include in archive"
        /align
    /local
        nb-entries central-directory files-size out
	][
        out: func [value] either any-file? where [
            [insert where value]
        ][
            [where: insert where value]
        ]
        if any-file? where [where: open/direct/binary/write where]

        files-size: nb-entries: 0
        central-directory: copy #{}

        foreach entry source [
            nb-entries: nb-entries + 1
            if align [zip-align entry/1 files-size]
            ; write file offset in archive
            change skip entry/2 42 to-ilong files-size
            ; directory entry
            insert tail central-directory entry/2
            ; compressed file + header
            out entry/1
            files-size: files-size + length? entry/1
        ]
        out join #{} [
            central-directory
            end-of-central-sig
            #{0000} ; disk num
            #{0000} ; disk central dir
            to-ishort nb-entries ; nb entries disk
            to-ishort nb-entries ; nb entries
            to-ilong length? central-directory
            to-ilong files-size
            #{0000} ; zip file comment length
                    ; zip file comment
        ]
        if port? where [close where]
        nb-entries
	]

    set 'zip func [
{Builds a zip archive from a file or a block of files.
     Returns number of entries in archive.}
        where [file! url! binary! string! block!] "Where to build it"
        source [file! url! block!] "Files to include in archive"
        /deep "Includes files in subdirectories"
        /verbose "Lists files while compressing"
        /to-entry
        /digest
    /local
        name data entry nb-entries files no-modes
        central-directory files-size out date entry-digest
    ][
        out: func [value] either any-file? where [
            [insert where value]
        ][
            [where: insert where value]
        ]
        if any-file? where [where: open/direct/binary/write where]

        files-size: nb-entries: 0
        central-directory: copy #{}

        source: compose [(source)]
        while [not tail? source][
            name: source/1
            no-modes: any [url? name dir? name]
            files: any [
                all [dir? name name: dirize name read name][]
            ]
            ; is name a not empty directory?
            either all [deep not empty? files] [
                ; append content to file list
                    foreach file read name [
                        insert tail source name/:file
                ]
            ][
                nb-entries: nb-entries + 1
                date: now

                ; is next one data or filename?
                data: either any [tail? next source any-file? source/2][
                    either #"/" = last name [copy #{}][
                        if not no-modes [
                            date: get-modes name 'modification-date
                        ]
                        read/binary name
                    ]
                ][
                    first source: next source
                ]
                name: to-path-file name
                if verbose [print name]
                ; get compressed file + directory entry
                entry: either digest [
	                entry-digest: zip-entry/digest name date data
	                entry-digest/1
                ][
	                zip-entry name date data
                ]
				either to-entry [
					append/only where either digest [entry-digest][entry]
				][
	                ; write file offset in archive
	                change skip entry/2 42 to-ilong files-size
	                ; directory entry
	                insert tail central-directory entry/2
	                ; compressed file + header
					out entry/1
                	files-size: files-size + length? entry/1
            	]
            ]
            ; next arg
            source: next source
        ]
        unless to-entry [
	        out join #{} [
	            central-directory
	            end-of-central-sig
	            #{0000} ; disk num
	            #{0000} ; disk central dir
	            to-ishort nb-entries ; nb entries disk
	            to-ishort nb-entries ; nb entries
	            to-ilong length? central-directory
	            to-ilong files-size
	            #{0000} ; zip file comment length
	                    ; zip file comment
	        ]
        ]
	    if port? where [close where]
        nb-entries
    ]

    set 'unzip func [
{Decompresses a zip archive to a directory or a block.
     Only works with compression methods 'store and 'deflate.}
            where  [file! url! any-block!]  "Where to decompress it"
            source [file! url! any-string!] "Archive to decompress"
            /verbose "Lists files while decompressing (default)"
            /quiet "Don't lists files while decompressing"
    /local
        flags method compressed-size uncompressed-size
        name-length name extrafield-length data time date
        uncompressed-data nb-entries path file info errors
    ][
        errors: 0
        info: func [value] either all [quiet not verbose][
            [none]
        ][
            [prin join "" value]
        ]
        if any-file? where [where: dirize where]
        if all [any-file? where not exists? where][
            make-dir/deep where
        ]
        if any-file? source [source: read/binary source]
        nb-entries: 0

        parse/all source [
            to local-file-sig
            some [
                thru local-file-sig
                (nb-entries: nb-entries + 1)
                2 skip ; version
                copy flags 2 skip
                    (if not zero? flags/1 and 1 [return false])
                copy method 2 skip
                    (method: get-ishort method)
                copy time 2 skip (time: get-msdos-time time)
                copy date 2 skip (
                    date: get-msdos-date date
                    date/time: time
                    date: date - now/zone
                )
                4 skip ; crc-32
                copy compressed-size 4 skip
                    (compressed-size: get-ilong compressed-size)
                copy uncompressed-size 4 skip
                    (uncompressed-size: get-ilong uncompressed-size)
                copy name-length 2 skip
                    (name-length: get-ishort name-length)
                copy extrafield-length 2 skip
                    (extrafield-length: get-ishort extrafield-length)
                copy name name-length skip (
                    name: to-file name
                    info name
                )
                extrafield-length skip
                data: compressed-size skip
                (
                    switch/default method [
                        0 [
                            uncompressed-data:
                                copy/part data compressed-size
                            info "^- -> ok [store]^/"
                        ]
                        8 [
                            data: either zero? uncompressed-size [
                                copy #{}
                            ][
                                to-binary rejoin [
                                    #{89504E47} #{0D0A1A0A} ; signature
                                    #{0000000D} ; IHDR length
                                    "IHDR" ; type: header
                                    ; width = uncompressed size
                                    to-long uncompressed-size
                                    #{00000001} ; height = 1 line
                                    #{08} ; bit depth
                                    #{00} ; color type = grayscale
                                    #{00} ; compression method
                                    #{00} ; filter method = none
                                    #{00} ; no interlace
                                    #{00000000} ; no checksum
                                    ; length
                                    to-long 2 + 6 + compressed-size
                                    "IDAT" ; type: data
                                    #{789C} ; zlib header
                                    ; 0 = no filter for scanline
                                    #{00 0100 FEFF 00}
                                    copy/part data compressed-size
                                    #{00000000} ; no checksum
                                    #{00000000} ; length
                                    "IEND" ; type: end
                                    #{00000000} ; no checksum
                                ]
                            ]

                            either error? try [data: load data][
                                info "^- -> failed [deflate]^/"
                                errors: errors + 1
                                uncompressed-data: none
                            ][
                                uncompressed-data:
                                    make binary! uncompressed-size
                                repeat i uncompressed-size [
                                    insert tail uncompressed-data
                                        to-char pick pick data i 1
                                ]
                                info "^- -> ok [deflate]^/"
                            ]
                        ]
                    ][
                        info ["^- -> failed [method " method "]^/"]
                        errors: errors + 1
                        uncompressed-data: none
                    ]
                    either any-block? where [
                        where: insert where name
                        where: insert where either all [
                            #"/" = last name
                            empty? uncompressed-data
                        ][none][uncompressed-data]
                    ][
                        ; make directory and / or write file
                        either #"/" = last name [
                            if not exists? where/:name [
                                make-dir/deep where/:name
                            ]
                        ][
                            set [path file] split-path name
                            if not exists? where/:path [
                                make-dir/deep where/:path
                            ]
                            if uncompressed-data [
                                write/binary where/:name
                                    uncompressed-data
                                set-modes where/:name [
                                    modification-date: date
                                ]
                            ]
                        ]
                    ]
                )
            ]
            to end
        ]
        info ["^/"
            "Files/Dirs unarchived: " nb-entries "^/"
            "Decompression errors: " errors "^/"
        ]
        zero? errors
    ]
]

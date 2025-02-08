Red/System [
    Note: "Auto-generated lexical scanner transitions table"
]
#enum lex-states! [
    S_START
    S_LINE_CMT
    S_LINE_STR
    S_SKIP_STR
    S_M_STRING
    S_SKIP_MSTR
    S_FILE_1ST
    S_FILE
    S_FILE_STR
    S_HDPER_ST
    S_HERDOC_ST
    S_HDPER_C0
    S_HDPER_CL
    S_SLASH_1ST
    S_SLASH
    S_SLASH_N
    S_SHARP
    S_BINARY
    S_LINE_CMT2
    S_CHAR
    S_SKIP_CHAR
    S_CONSTRUCT
    S_ISSUE
    S_NUMBER
    S_DOTNUM
    S_DECIMAL
    S_DECEXP
    S_DECX
    S_DEC_SPECIAL
    S_TUPLE
    S_DATE
    S_TIME_1ST
    S_TIME
    S_PAIR_1ST
    S_PAIR
    S_POINT
    S_MONEY_1ST
    S_MONEY
    S_MONEY_DEC
    S_INT_HEX
    S_HEX
    S_HEX_END
    S_HEX_END2
    S_LESSER
    S_TAG
    S_TAG_STR
    S_TAG_STR2
    S_SIGN
    S_DOTWORD
    S_DOTDEC
    S_WORD_1ST
    S_WORD
    S_WORDSET
    S_PERCENT
    S_URL
    S_EMAIL
    S_REF
    S_EQUAL
    S_PATH
    S_PATH_NUM
    S_PATH_W1ST
    S_PATH_WORD
    S_PATH_SHARP
    S_PATH_SIGN
    --EXIT_STATES--
    T_EOF
    T_ERROR
    T_BLK_OP
    T_BLK_CL
    T_PAR_OP
    T_PAR_CL
    T_MSTR_OP
    T_MSTR_CL
    T_MAP_OP
    T_PATH
    T_CONS_MK
    T_CMT
    T_COMMA
    T_STRING
    T_WORD
    T_ISSUE
    T_INTEGER
    T_REFINE
    T_CHAR
    T_FILE
    T_BINARY
    T_PERCENT
    T_FLOAT
    T_FLOAT_SP
    T_TUPLE
    T_DATE
    T_PAIR
    T_POINT
    T_TIME
    T_MONEY
    T_TAG
    T_URL
    T_EMAIL
    T_HEX
    T_RAWSTRING
    T_REF
]
skip-table: #{
0100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000
}
type-table: #{
000007070707080808080707070F130F1429000A0A00140B0C0C0C0C0C272F2B
2B252533313131000B0F0B2C2C2C2C0F0F0C0F0F100F092D320F190B0F0F140F
0000220000000000070000000000070F140B130A0829260C0C272F25332B312C
092D0B0732
}
transitions: #{
0000171743444546474202103232333333332833280D422B3339064D01383024
2F2F330042334241014C01010101010101010101010101010101010101010101
0101010101010101010101010101424C024202020202020202024E0202020202
0202020202020202020202020202020202020302020242420202020202020202
0202020202020202020202020202020202020202020202020202020202024242
0404040404040404474804040404040404040404040404040404040404040404
0404050404044242040404040404040404040404040404040404040404040404
040404040404040404040404040442424F4F07074F4F4F4F0A4F080707350707
0707070707070707070709074F4F07070707074F0707424F5454070754545454
5454420707540707070707070707070707070707545407070707070707074254
0842080808080808080854080808080808080808080808080808080808080808
08080808080842424F4F07074F4F4F4F0A4F4F07070707070707070707074F07
070709074F0707070707074F0707424F0A0A0A0A0A0A0A0A0A0B0A0A0A0A0A0A
0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A42420A0A0A0A0A0A0A0A
0A0B0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0C0A0A0A0A0A0A0A0A0A0A0A4242
63634242636363636342634242424242424242424242426342420C4263424242
42424263424242634F4F0E0E4F4F4F4F4F4F4F4F0E340E0E0E0E0E0E0E0F0E0E
0E0E0E424F4F0E0E0E0E0E4F0E0E424F52520E0E525252525252520E0E420E0E
0E0E0E0E0E520E0E0E0E0E4252520E0E0E0E0E520E0E42524F4F33334F4F4F4F
4F4F4F4F3333333333333333330F3333333342424F4F33423333334F3333424F
4242161649421542114213161642161616161616161616424216164250501616
1616165016164250111111114242424242554242424211111111111111114242
4211424212424242114242424211424212111212121212121212121212121212
1212121212121212121212121212121212121212121242421313131313131313
1313531313131313131313131313131313131313131313131313141313134242
1313131313131313131313131313131313131313131313131313131313131313
1313131313134242151515151515154B15151515151515151515151515151515
1515151515151515151515151515424250501616505050505050501616421616
1616161616421616161616165050161616161650161642505151171751515151
51515110171F211E2A1A1B42271E42514242565151371842421E425142424251
57571919575757575757571C19422142421A1A42425742574242565757424242
424242574242425757571919575757575757574219572142421A1A4242574257
4242565757371D42424242574242425757571A1A575757575757574242574242
424242424257425742424257573742421A1A42574242425757571B1B57575757
57575742425742422A422842285742574242565742371D421A1A425742424257
58585758585858585858584242421C1C1C1C1C1C1C5858581C1C425858421C42
1C1C42581C1C425859591D1D5959595959595942425942424242424242594259
4242424259421D4242424259424242595A5A1E1E5A5A5A5A5A5A5A1E1E1E1E1E
1E1E1E1E1E1E1E5A1E1E42425A421E5A1E1E425A421E425A4242202042424242
4242424242424242424242424242424242424242424242424242424242424242
5D5D20205D5D5D5D5D5D5D424220424242424242425D425D424242425D422042
4242425D4242425D424222224242424242424242424242424242424242424242
424242424237424222224242424242425B5B22225B5B5B5B5B5B5B42425B4242
42222242425B425B424242425B3722424242425B4242425B234223234223425C
4242422342424242422323232342424242424223424223422323424242234242
4242252542424242424242424242424242424242424242424242424242424242
42424242424242425E5E25255E5E5E5E5E5E5E5E255E424242424242425E425E
424242425E4226424242425E4242425E5E5E26265E5E5E5E5E5E5E5E265E4242
42424242425E425E424242425E4242424242425E4242425E4242272742424242
4242424242424242294227422742424242424242423742424242424242424242
4F4F28284F4F4F4F4F4F4F4F3334333329332833284A4F33333342424F373325
3333334F3333424F6262333362626262626262423334333333333333334A6233
3333424262373325333333623333426262624242626262626262624242424242
42424242424A6262424242426237422542424262424242624F4F2C2C4F4F4F4F
4F4F4F2C2E342C2C2C2C2C2C2C2C2C2B33332C2C4F2C2C2C2C332C4F2C2C424F
2C2C2C2C2C2C2C2C2C2C2D2C2E2C2C2C2C2C2C2C2C2C2C2C5F2C2C2C2C2C2C2C
2C2C2C2C2C2C42422D2D2D2D2D2D2D2D2D2D2C2D2D2D2D2D2D2D2D2D2D2D2D2D
2D2D2D2D2D2D2D2D2D2D2D2D2D2D42422E2E2E2E2E2E2E2E2E2E2E2E2C2E2E2E
2E2E2E2E2E2E2E2E2E2E2E2E2E2E2E2E2E2E2E2E2E2E42424F4F17174F4F4F4F
4F4F4F4F4233333333333333334A4F33333342334F3330253333424F3333424F
4F4F31314F4F4F4F4F4F4F4F3334333333333333334A4F33333342424F373342
3131334F3333424F575731315757575757575742425721424231314242574257
4242564242374242313142574242425742424242424242424242424242423333
33333333330D422B333935424242334233333342333342424F4F33334F4F4F4F
4F4F4F4F3334333333333333334A4F4F333342424F3733243333334F3333424F
4F4F36364F4F4F4F4F4F4F36363636363636363636364F42363636364F363636
3636364F3636424F4F4F42424F4F4F4F4F4F4242424242424242424242424F42
424235424F4242424242424F4242424F60603636606060606060603636363636
3636363636366060423636366036363636364260363642606161373761616161
6161614242423737373737373761616142423742614237423737426137374261
6464383864646464646464424238383838383838383842644242384264423842
38384264383842644F4F33334F4F4F4F4F4F4F42334F333333333333334F4F33
333342424F4233423333334F3333424F42423B3B424245464242023E3C3C3D3D
3D3D3D3D3D42422B3D3D424242383D243F3F42423D3D424251513B3B51515151
515151423B512142421A1A424251425142425642513718424242425142424251
42424242424242424242424242423D3D3D3D3D3D3D42423D3D3D424242423D42
3D3D42423D3D42424F4F3D3D4F4F4F4F4F4F4F423D4F3D3D3D3D3D3D3D4F4F3D
3D3D42424F373D243D3D3D4F3D3D424F42421616154242424242131616421616
1616161616421642424216424242161616161642161642424F4F3B3B4F4F4F4F
4F4F4F42424F3D3D3D3D3D3D3D4F4F423D3D42424F373D243F3F424F3D3D424F
}
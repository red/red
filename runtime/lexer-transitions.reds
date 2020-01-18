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
        S_FILE_HEX1 
        S_FILE_HEX2 
        S_FILE_STR 
        S_SLASH 
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
        S_DECX 
        S_DEC_SPECIAL 
        S_TUPLE 
        S_DATE 
        S_TIME_1ST 
        S_TIME 
        S_PAIR_1ST 
        S_PAIR 
        S_MONEY_1ST 
        S_MONEY 
        S_MONEY_DEC 
        S_HEX 
        S_HEX_END 
        S_LESSER 
        S_TAG 
        S_TAG_STR 
        S_SKIP_STR2 
        S_TAG_STR2 
        S_SKIP_STR3 
        S_SIGN 
        S_DOTWORD 
        S_DOTDEC 
        S_WORD_1ST 
        S_WORD 
        S_WORDSET 
        S_URL 
        S_EMAIL 
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
        T_WORD 
        T_REFINE 
        T_ISSUE 
        T_STRING 
        T_FILE 
        T_BINARY 
        T_CHAR 
        T_PERCENT 
        T_INTEGER 
        T_FLOAT 
        T_FLOAT_SP 
        T_TUPLE 
        T_DATE 
        T_PAIR 
        T_TIME 
        T_MONEY 
        T_TAG 
        T_URL 
        T_EMAIL 
        T_HEX
    ] 
    type-table: #{
0000070707070808080808131429000A0A00140B0C0C0C0C272F2B2B25253333
330B0F2C2C2C2C2C2C0F0F0C0F0F10092D190B0F0F140F000000000000000007
000000000000140708290A26000C0C272F252B332C092D0B
} 
    transitions: #{
000013133A3B3C3D3E39020C2C2C2D2D2D2D212D210B39232D2D063901392A1E
2929392D2D393801430101010101010101010101010101010101010101010101
0101010101010101010101013938020202020202020202024702020202020202
0202020202020202020202020202020203020239390202020202020202020202
0202020202020202020202020202020202020202020202020202393804040404
040404043E3F0404040404040404040404040404040404040404040404040504
0439390404040404040404040404040404040404040404040404040404040404
04040404040404043938444407074444444444440A0707440707070707070707
0707070707074444070707070707073944484807074848484848483907074807
0707070707070707070707080748480707070707070739480707090939393939
3939393939393939390909090939393939393939393939393939393939393907
0707073939393939393939393939393909090707393939393939393939393939
3939393939480A0A0A0A0A0A0A0A0A0A480A0A0A0A0A0A0A0A0A0A0A0A0A0A0A
0A0A0A0A0A0A0A0A0A0A0A393945450B0B454545454545450B0B0B0B0B0B0B0B
0B0B2D0B0B0B0B0B0B45450B0B0B0B0B0B0B394546461212113940390D390F12
1239121212121212121212393939123946461212121212121239460D0D0D0D39
3939393949393939390D0D0D0D0D0D0D0D3939390D39390E3939390D3939390D
39390E0D0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E
0E0E0E0E0E0E0E39380F0F0F0F0F0F0F0F0F0F4A0F0F0F0F0F0F0F0F0F0F0F0F
0F0F0F0F0F0F0F0F0F0F0F100F0F394A0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F3939111111111142111111
1111111111111111111111111111111111111111111111111111111139394646
1212464646464646461212121212121212121212121212121212464612121212
12121239464C4C13134C4C4C4C4C4C4C0C131A1C19571516392119394C39394B
144C3014393919393939394C4D4D15154D4D4D4D4D4D4D1715391C3939151539
394D394D39394B394D3939393939393939394D4D4D15154D4D4D4D4D4D4D3939
4D393939151539394D394D39394B39393018391515393939394D4D4D16164D4D
4D4D4D4D4D39394D393957152139214D394D39394B3939301839151539393939
4D4D4D4D4E4E4E4E4E4E4E4E174E4E171717171717174E4E4E17174E4E4E4E17
4E17174E1717394E4F4F18184F4F4F4F4F4F4F39394F393939393939394F394F
39393939393918393939393939394F5050191950505050505050191919191919
1919191919195019195019505019501919503919395039391B1B393939393939
393939393939393939393939393939393939393939393939393939393952521B
1B5252525252525239391B393939393939395239523939393952391B39393939
3939395239391D1D393939393939393939393939393939393939393939393939
393039391D1D393939393951511D1D515151515151513939513939391D1D3939
5139513939393951301D393939393939395139391F1F39393939393939393939
3939393939393939393939393939393939393939393939393953531F1F535353
53535353531F5339393939393939533953393939395339203939393939393938
5353202053535353535353532053393939393939395339533939393953393939
393939393939384444212144444444444444392D2E2D2D222D212D2141442D2D
2D393944302D1F2D2D2D2D2D394457572D2D57575757575757392D2E2D2D2D2D
2D2D2D41572D2D2D393957302D1F2D2D2D2D2D39574444242444444444444444
2424442424242424242424242D2D2D2424444424242424242424394424242424
2424242424242524242724242424242424242424542424242424242424242424
2439392525252525252525252524252525252525252525252525252525252525
2525252525262525393925252525252525252525252525252525252525252525
2525252525252525252525252525253939272727272727272727272727272427
2727272727272727272727272727272727272727272739392727272727272727
2727272727272727272727272727272727272727272727272727272727393944
4413134444444444444439392D2D2D2D2D2D2D2D2D44392D2D392D442D2A2D2D
2D392D2D394444442B2B44444444444444392D2E2D2D2D2B2B2D2D41442D2D2D
393944302D392B2B2D2D2D39444D4D2B2B4D4D4D4D4D4D4D39394D1C39392B2B
39394D394D39394B39393939392B2B393939394D393939393939393939393939
39392D2D2D2D2D2D2D0B392D2D2D393939392D392D2D392D2D393944442D2D44
444444444444392D2E2D2D2D2D2D2D2D41442D2D2D393944302D1F2D2D2D2D2D
394444442F2F444444444444442F2F2F2F2F2F2F2F2F2F2F44392F2F2F2F442F
2F2F2F2F2F2F2F394455552F2F555555555555552F392F2F2F2F2F2F2F2F2F55
55392F2F55552F2F392F2F392F2F395556563030565656565656563939393030
30303030305656563939303956393039303039303039563939323239393C3D39
3902353333343434343434343939233434393939303439363639343439394C4C
32324C4C4C4C4C4C4C39134C1C3939151539394C394C39394B144C3014393939
393939394C393939393939393939393939393934343434343434393934343439
3939393439343439343439394444343444444444444444393444343434343434
34444434343439394430343934343434343944464612121139393939390F1212
3912121212121212121239393912394646121212121212123946444432324444
444444444439392D2D2D2D2D2D2D2D2D44392D2D392D442D2D2D2D2D392D2D39
44
}
Red [Needs: View]

view [
    below
    style fi: field 30 on-focus [face/color: red] on-unfocus [face/color: white]
    style pan: panel 127.114.98
    style grp: group-box 127.114.98
    fi "1" focus fi "2" fi "3"
    pan [fi "4" fi "5" panel [f6: fi "6"] fi "6.1" panel [fi "7" fi "7.1" panel [fi "8"]]]
    fi "8.1"
    grp [f9: fi "9" fi "10" grp [fi "11"] fi "11.1" grp [fi "12" fi "12.1" grp [fi "13"]]]
    fi "14"
    button "dump" [dump-face face/parent]
    button "link 6 to 9, 9 to 6" [
    	unless find f6/options 'next [append f6/options compose [next: (f9)]]
    	unless find f9/options 'prev [append f9/options compose [prev: (f6)]]
    ]
    across
    fi "17" button "18" t: tab-panel ["19" [] "19.1" [fi "19.2"] "20" [fi "21" button "22"]]
    area "navigatable area" return
    fi "23" button "24" tab-panel ["25" [fi "26" button "27"]]
    area "not navigatable" with [flags: none] return
]
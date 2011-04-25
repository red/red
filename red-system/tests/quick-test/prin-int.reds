Red/System [
	Title:   "Prin an integer"
	Author:  "Peter W A Wood"
	File: 	 %prin-int.reds
	Rights:  "Public Domain"
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

prin-int: func [
  i [integer!]
  /local
  divisor [integer!]
  digit [integer!]
  rem [integer!]
  non-zero-printed [integer!]
][
  divisor: 1000000000
  non-zero-printed: 0
  ;; an internal function which print single
  prin-digit: func [
    digit [integer!]
  ][
    either digit = 1 [prin "1"] [
      either digit = 2  [prin "2"] [
        either digit = 3 [prin "3"] [
          either digit = 4 [prin "4"] [
            either digit = 5 [prin "5"] [
              either digit = 6 [prin "6"] [
                either digit = 7 [prin "7"] [
                  either digit = 8 [prin "8"] [
                    either digit = 9 [prin "9"] [prin "0"]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]

  either i = 0 [
    prin "0"
  ][
    rem: i
    if rem < 0 [
      prin "-"
      rem: rem * -1
    ]
    until [
      digit: rem / divisor
      either non-zero-printed = 0 [
        if digit <> 0 [
          prin-digit digit
          non-zero-printed: 1
        ]
      ][
        prin-digit digit
      ]
      rem: rem - (digit * divisor)
      divisor: divisor / 10
      divisor = 0
    ]  
  ]
  
]


  
  

  
  
  
    
  
    


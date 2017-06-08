Red/System [
    Title:    "MT19973 testprogram"
    File:     %random-mt19937_reds_test.reds
	Author:	  "Arnold van Hofwegen"
	Rights:	  "Copyright (c) 2013 Arnold van Hofwegen. All rights reserved."
	License:  {
		Redistribution and use in source and binary forms, with or without modification,
		are permitted provided that the following conditions are met:

		    * Redistributions of source code must retain the above copyright notice,
		      this list of conditions and the following disclaimer.
		    * Redistributions in binary form must reproduce the above copyright notice,
		      this list of conditions and the following disclaimer in the documentation
		      and/or other materials provided with the distribution.

		THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
		ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
		WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
		DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
		FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
		DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
		SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
		CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
		OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
		OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	}
]   

#include %random-mt19937.reds

debug-print: func [
    num [integer!]
    description [c-string!]
    /local u
][  
    u: 1 
    print [description lf]
    until [
        print ["state-array/" u ": " random-mt19937/state-array/u lf]
        u: u + 1
        u > num
    ]   
]

; declaration 
real-random: 1.0

;; declare initialisation array
init: as int-ptr! allocate 4 * size? integer! 

test-MT19937: func [
	 /local i length
][
    print ["Test program Mersenne Twister random-mt19937.reds" lf
           "------------------------------------------" lf]
    print ["--- Test 1 init-genrand 19650218 ---" lf
           "------------------------------------" lf]
    random-mt19937/init-genrand 19650218
    debug-print 20 "init-genrand 19650218"

    print ["--- Test 2 init-by-array [291 564 837 1110] ---" lf
           "-----------------------------------------------" lf]
    
    init/1: 00000123h ;; 291
    init/2: 00000234h ;; 564
    init/3: 00000345h ;; 837
    init/4: 00000456h ;; 1110
    length: 4
    print ["init-array values: " init/1 " " init/2 " " init/3 " " init/4 lf]
    
    random-mt19937/init-by-array init length 
    debug-print 20 "init-by-array"
    
    print ["--- Test 3 1000 outputs of genrand-int32 ---" lf
           "--------------------------------------------" lf]
    i: 0
    ;while [i < 1000][ 
    ;while [i < 10][ 
    while [i < 9][ 
        print [random-mt19937/genrand-int32 " "]
        if ((i % 5) = 4) [print newline]
        i: i + 1
    ]

; temporarily out of order
    print ["--- Test 4 1000 outputs of genrand-real2 ---" lf
           "--------------------------------------------" lf]
;    real-random: 1.0	
    i: 0
    while [i < 10][ 
      real-random: random-mt19937/genrand-real2
      ;print ">" print i + 1 print newline
      print real-random
      ;print [real-random " "]
      ;print [random-mt19937/genrand-real2 " "]
      if ((i % 5) = 4) [print newline ]
      i: i + 1
    ]

    print ["----------------------------------" lf
           "--- End of testprogram MT19937 ---" lf]

     random-mt19937/ran_arr_free
     
]

test-MT19937
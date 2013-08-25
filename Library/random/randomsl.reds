Red/System [
    Title:   "Random from taocp as shared library"
    Author:  "Arnold van Hofwegen"
    File:    %randomsl.reds
    Rights:  "Copyright (c) 2011-2013 Arnold van Hofwegen. All rights reserved."
    License: {
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
    Needs:   {
        Red/System >= 0.3.3
    }
    Tabs:    4
    About:   {This program is completely based on the random algorythm by Knuth
      It has been translated to Red/System language. It has been tested to give 
      the same results in the seeded array and the first 111 random numbers.
      Usage in everyday life is first seeding with the ran_start function, then 
      set a variable using the ran_arr_next function.
    }
]

;; Globally defined variables
KK:  100                        ;; the long lag
KKP: 101
LL:  37                         ;; the short lag
LLP: 38
MM:  1 << 30                    ;; the modulus 
QUALITY: 1009                   ;; recommended quality level for high-res use

#define mod_diff(x y) [((x) - (y)) and (MM - 1)] ;; subtraction mod MM 

ran_x: as int-ptr! allocate 100 * size? integer! ;; the generator state

;; Declarations at root level
;; Compilation Error: variable has to be initialized at root level
idx1:   1                 
idx2:   1
twoj:   1
twoj-1: 1
j-1:    1

;; ran_array fills the array from the generator state
ran_array: function [
	aa [pointer! [integer!]]
	n  [integer!]                ;; array length n has to be at least as big as KK
	/local i j
][
	j: 1
	while [j <= KK][
		aa/j: ran_x/j
		j: j + 1
	]
	while [j <= n][            ;; In the C version j < n, but there j starts at 0 not at 1
		idx1: j - KK 
		idx2: j - LL 
		aa/j: mod_diff(aa/idx1 aa/idx2);
		j: j + 1
	]
	i: 1
	while [i <= LL][
		idx1: j - KK 
		idx2: j - LL 
		ran_x/i: mod_diff(aa/idx1 aa/idx2)
		i: i + 1
		j: j + 1
	]
	while [i <= KK][
		idx1: j - KK
		idx2: i - LL
		ran_x/i: mod_diff(aa/idx1 ran_x/idx2)
		i: i + 1
		j: j + 1
	] 
]

;; Declarations for the initialisation/seed function ran_start and the function 
;; ran_arr_next to get the next random value
ran_arr_dummy: -1 
ran_arr_started: -1
ran_arr_buf: as int-ptr! allocate QUALITY * size? integer!
sav_arr_buf: declare pointer! [integer!]       
ran_arr_ptr: declare pointer! [integer!]       ;; indicator for seeding 
sav_arr_buf: ran_arr_buf                       ;; save start location of buffer in memory
ran_arr_ptr: :ran_arr_dummy                    ;; not started

TT: 70

#define odd?(x) [(as-logic (x) and 1)]         ;; Kaj's improved suggestion

ra: as int-ptr! allocate 199 * size? integer!  ;; 100 + 100 - 1

;; the seed function
ran_start: function [seed [integer!]
	/local t [integer!]
	j [integer!]
	;x ;;array We use the array ra 
	ss [integer!]
][
	ss: ((seed + 2) and (MM - 2))
	j: 1
	while [j <= KK][
		ra/j: ss
		ss: ss << 1
		if  ss >= MM [
			ss: ss - (MM - 2)
		]
		j: j + 1        
	]
	ra/2: ra/2 + 1                      ;; Make only ra/2 odd

	ss: (seed and (MM - 1))
	t: TT - 1
	while [t > 0][
		j: KK                           
		while [j > 1][                  
			; C source comment: "square"
			twoj: j + j - 1
			twoj-1: twoj - 1
			ra/twoj: ra/j
			ra/twoj-1: 0
			j: j - 1
		] 
		j: KK + KK - 1
		while [j >= KKP][
			idx1: j - (KK - LL)         
			ra/idx1: mod_diff(ra/idx1 ra/j)
			idx2: j - KK 
			ra/idx2: mod_diff(ra/idx2 ra/j)
			j: j - 1
		]
		if  odd? (ss) [
			j: KKP                    
			while [j > 1][
				j-1: j - 1
				ra/j: ra/j-1
				j: j - 1
			]
			ra/1: ra/KKP                ;; shift buffer cyclically
			ra/LLP: mod_diff(ra/LLP ra/KKP)
		]
		either ss > 0 [
			ss: ss >> 1
		][
			t: t - 1
		]
	]

	j: 1
	while [j <= LL][
		idx1: j + KK - LL
		ran_x/idx1: ra/j
		j: j + 1
	]

	while [j <= KK][
		idx1: j - LL
		ran_x/idx1: ra/j
		j: j + 1
	]

	j: 1
	while [j <= 10][
		ran_array ra (KK + KK - 1)      ;; Warm things up
		j: j + 1
	]

	ran_arr_ptr: :ran_arr_started       ;; random seed done
]

ran_arr_buf_idx: 0

ran_arr_next: function [return: [integer!] /local result [integer!]][
	ran_arr_buf_idx: ran_arr_buf_idx + 1
	either ran_arr_buf/value > 0 [
		result: ran_arr_buf/value
		ran_arr_ptr: ran_arr_ptr + 1
		ran_arr_buf: ran_arr_buf + 1
		return result
	][
		ran_arr_cycle
	]
]

ran_arr_cycle: function [return: [integer!] /local result [integer!]][
	if  ran_arr_ptr = :ran_arr_dummy [
		ran_start 314159 ;; User forgot to initialize, 
						 ;; this uses pi (we could use tau here)
	]
	ran_arr_buf: sav_arr_buf 
	ran_array ran_arr_buf 1009
	if  ran_arr_buf_idx > KK [ran_arr_buf_idx: 0]
	ran_arr_buf/KKP: -1
	ran_arr_ptr: ran_arr_buf
	result: ran_arr_buf/value
	ran_arr_buf: ran_arr_buf + 1
	return result
]

;; test windows clean buffer
ran_clean_arr_buf: function [/local i [integer!]][
	i: 1
	until [
		ran_arr_buf/i: 0
		i: i + 1
		i > 1009
	]
]

;; init the buffer for any OS.
ran_clean_arr_buf

;; Free the memory
ran_arr_free: function [][
	free as byte-ptr! ran_x
	free as byte-ptr! ra
	ran_arr_buf: sav_arr_buf
	free as byte-ptr! ran_arr_buf
]

;; it is not yet possible to use the modulo // function in Red
ran_integer: function [n [integer!] return: [integer!] /local retval][
	retval: ((ran_arr_next // n) + 1)
	return retval
]

#export [ran_array]
#export [ran_start]
#export [ran_arr_next]
#export [ran_arr_cycle]
#export [ran_arr_free]
#export [ran_integer]
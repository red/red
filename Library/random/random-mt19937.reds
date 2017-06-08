Red/System [
    Title:    "MT19973 Mersenne Twister Pseudo Random Number Generator"
    Version:  0.0.1
	File:     %random-mt19937.reds
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
	Note:     {This program is based on the random algorythm for MT19937, 
	    with initialization improved 2002/1/26, coded by Takuji Nishimura and 
	    Makoto Matsumoto.
        Before using, initialize the state by using init-genrand seed   
        or init-by-array init-key, key-length.
        The functions for generating PR real numbers, genrand-real1 genrand-real2
        genrand-real3 and genrand-res53 are untested.
    }
    Thanks:   {
        Kaj de Vos for reminder unsigned shift and debugging advice 
        XieQ for structure and more elegant style, 
        Rebolek for creating user.reds,
        DocKimbel for debugging advice (and creating Red).
	}
	Needs: "%user.reds"
]   

#include %user.reds

random-mt19937: context [

	;; Period parameters  
	#define STATE-SIZE      624       ;; length of the state-array 
	#define STATE-HALF-SIZE 397       ;; half state-array length
	#define MATRIX_A        9908B0DFh ;; constant vector a 
	#define UPPER_MASK      80000000h ;; most significant w-r bits 
	#define LOWER_MASK      7FFFFFFFh ;; least significant r bits 

	;; the array for the state vector  
	state-array: as int-ptr! allocate STATE-SIZE * size? integer!
	idx: STATE-SIZE + 2  ;; index for state-array results
	                     ;; idx = STATE-SIZE + 2 means array mt is not initialized

	;; initialize array state-array with a seed
	init-genrand: func [ 
		  seed [integer!] 
		  /local i j
	][
		state-array/1: seed and FFFFFFFFh 
		i: 1
		j: 1
		until [
			i: i + 1
			state-array/i: state-array/j >>> 30 xor state-array/j * 1812433253 + j
			;; See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier.
			;; In the previous versions, MSBs of the seed affected  
			;; only MSBs of the array.                        
			;; 2002/01/09 modified by Makoto Matsumoto   
			state-array/i: state-array/i and FFFFFFFFh ;; for >32 bit machines 
			j: j + 1 
			i = STATE-SIZE
		]
		idx: STATE-SIZE + 1
	]

	;; initialize by an array with array-length 
	init-by-array: func [
		init-key [int-ptr!]   ;; the array for initializing keys 
		key-length [integer!] ;; key-length is its length 
		/local h i j k 
	][
		init-genrand 19650218   
		i: 1  
		h: 1 
		j: 1
		k: either STATE-SIZE > key-length [STATE-SIZE][key-length]
		while [k > 0][ 
			i: i + 1
			state-array/i: ((state-array/h >>> 30 xor state-array/h) * 1664525) xor state-array/i 
						   + init-key/j + j - 1          ;; non linear 
			state-array/i: state-array/i and FFFFFFFFh   ;; for WORDSIZE > 32 machines 
			h: h + 1 ;; h is one behind i
			j: j + 1 ;; j is independent of i
			if  (i >= STATE-SIZE) [
				;state-array/1: append "state-array/" STATE-SIZE
				state-array/1: state-array/624         ;; work-around for issue #504
				i: 1
				h: 1
			]
			if  j > key-length [j: 1]
			k: k - 1 
		]
		k: STATE-SIZE
		while [k > 1][
			i: i + 1
			state-array/i: (((state-array/h >>> 30) xor state-array/h) * 1566083941) xor state-array/i - h
														 ;; non linear 
			state-array/i: state-array/i and FFFFFFFFh   ;; for WORDSIZE > 32 machines 
			h: h + 1
			if  i >= STATE-SIZE [
				;state-array/1: state-array/:STATE-SIZE
				state-array/1: state-array/624
				i: 1
				h: 1
			]
			k: k - 1
		]
		state-array/1: 80000000h ;; MSB is 1; assuring non-zero initial array 
	]

	magic-array: as int-ptr! allocate 2 * size? integer! 
	magic-idx:   1 

	;; generates a random number on [0,FFFFFFFF]-interval
	genrand-int32: func [
		return: [integer!] 
		/local p r s y 
	][
		magic-array/1: 00000000h 
		magic-array/2: MATRIX_A

		if  idx > STATE-SIZE [            ;; generate STATE-SIZE words at one time 
			if  idx = (STATE-SIZE + 2) [  ;; if init-genrand has not been called,
				init-genrand 5489         ;; then a default initial seed is used
			]
			p: 1 
			r: 1 
			while [p < (STATE-SIZE - STATE-HALF-SIZE + 1)][ 
				p: p + 1
				y: (state-array/r and UPPER_MASK) or (state-array/p and LOWER_MASK) 
				s: r + STATE-HALF-SIZE
				magic-idx: (y and 00000001h) + 1
				state-array/r: (state-array/s xor (y >>> 1)) xor magic-array/magic-idx
				r: r + 1 ;; r follows p 
			]
		
			while [p < STATE-SIZE][            
				p: p + 1
				y: (state-array/r and UPPER_MASK) or (state-array/p and LOWER_MASK)
				s: r + STATE-HALF-SIZE - STATE-SIZE
				magic-idx: (y and 00000001h) + 1
				state-array/r: state-array/s xor (y >>> 1) xor magic-array/magic-idx
				r: r + 1
			]
		
			;y: (state-array/STATE-SIZE and UPPER_MASK) or (state-array/1 and LOWER_MASK) 
			y: (state-array/624 and UPPER_MASK) or (state-array/1 and LOWER_MASK) 
			magic-idx: (y and 00000001h) + 1
			;state-array/STATE-SIZE: state-array/STATE-HALF-SIZE xor (y >>> 1) xor magic-array/magic-idx
			state-array/624: state-array/397 xor (y >>> 1) xor magic-array/magic-idx

			idx: 1
		]
  
		y: state-array/idx
		idx: idx + 1

		;; Tempering 
		y: y xor (y >>> 11)
		y: y xor ((y <<  7) and 9D2C5680h)
		y: y xor ((y << 15) and EFC60000h)
		y: y xor (y >>> 18)

		return y
	]

	;; generates a random number on [0,7FFFFFFF]-interval
	genrand-int31: func [return: [integer!]][
		return genrand-int32 >>> 1
	]

	;; generates a random number on [0,1]-real-interval
	genrand-real1: func [
		return: [float!] 
		/local result [float!]
	][
		result: int-to-float genrand-int32
		result: ((1.0 / 4294967295.0) * result) ;; divided by 2^32 -1 
		return result
	]

	;; generates a random number on [0,1)-real-interval
	genrand-real2: func [
		return: [float!] 
		/local result [float!] betw [float!] intermediate [integer!]
	][  print "genrand-real2" 
	    ;result: 1.5
	    ;betw: 1.5
	    ;;intermediate: genrand-int32
	    betw: int-to-float genrand-int32
	    ;print "-->" print intermediate
	    ;result: int-to-float genrand-int32
	    ;result: int-to-float intermediate
	    ;print result
		;result: ((1.0 / 4294967296.0) * result) ;; divided by 2^32 
		result: ((1.0 / 4294967296.0) * betw) ;; divided by 2^32 
		return result
	]

	;; generates a random number on (0,1)-real-interval
	genrand-real3: func [
		return: [float!] 
		/local result [float!]
	][
		result: int-to-float genrand-int32
		result: ((0.5 + result) * (1.0 / 4294967296.0)) ;; divided by 2^32 
		return result
	]

	; generates a random number on [0,1) with 53-bit resolution
	genrand-res53: func [return: [float!] /local a b][
		a: int-to-float (genrand-int32 >>> 5)
		b: int-to-float (genrand-int32 >>> 6)
		return (67108864.0 * a + b) * (1.0 / 9007199254740992.0) 
	] 
	;; These real versions are due to Isaku Wada, 2002/01/09 added

    ;; Free the memory
    ran_arr_free: function [][
        free as byte-ptr! state-array
        free as byte-ptr! magic-array
    ]
    
]  ;; End of context random-mt19937
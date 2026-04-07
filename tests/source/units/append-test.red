Red [
	Title:   "Red append test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %append-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "append"

===start-group=== "append"
  --test-- "append-1"	--assert 6 = last append [1 2 3 4 5] 6
  --test-- "append-2"	
  		--assert 6 = last append [1 2 3 4] [5 6]
  		--assert 4 = fourth append [1 2 3 4] [5 6]
  		--assert 5 = fifth append [1 2 3 4] [5 6]
  --test-- "append-3"	--assert 55 = last append "12345" "67"
  --test-- "append-4"	--assert 233 = last append "abcde" "é" ;; utf-8 C3 A9
  --test-- "append-5"	--assert 49 = last append "abcdeé" "1" ;; utf-8 C3 A9
  --test-- "append-6"	--assert 10000 = last append "abcde" "✐"
  --test-- "append-7"	--assert 48 = last append "abcde^(2710)" "0"
  --test-- "append-8"	--assert 10000 = last append "abcdeé" "^(2710)"
  --test-- "append-9"	--assert 233 = last append "abcde^(2710)" "é"
  --test-- "append-10"	--assert 65536 = last append "abcde" "^(010000)"   
  --test-- "append-11"	--assert 48 = last append "abcde^(010000)" "0"
  --test-- "append-12"	--assert 65536 = last append "abcde^(2710)é" "^(010000)" 
  
  --test-- "append-13"
	blk: make block! 1
	append blk 'x/y
	append/only blk  'r/s
	--assert "[x y r/s]" = mold blk

  --test-- "append-14"
	blk: [1 2]
	append/dup/part blk [4 5 6] 3 2
	--assert "[1 2 4 5 4 5 4 5]" = mold blk
	
  --test-- "append-15"
	blk: [1 2]
	append/dup/part blk [4 5 6] 2 3
	--assert "[1 2 4 5 6 4 5 6]" = mold blk	

  --test-- "append-16"
	str: "12"
	append/dup/part str "456" 3 2 
	--assert str = "12454545"

  --test-- "append-17"
	str: "12"
	append/part/dup str "456" 3 2 
	--assert str = "12456456"

  --test-- "append-18"
	str: "12"
	append/part/dup str ["4" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "124567ab4567ab"
	
  --test-- "append-18.1"
	str: "12"
	append/part/dup/only str ["4ABCDEF" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "124ABCDE4ABCDE"
	
  --test-- "append-19"
	str: "12é"
	append/part/dup str ["4" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "12é4567ab4567ab"

  --test-- "append-19.1"
	str: "12é"
	append/part/dup/only str ["4AB" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "12é4AB5674AB567"

  --test-- "append-20"
	str: "12"
	append/part/dup str ["4" #"5" #"6" 7 é 'b x] 6 2
	--assert str = "124567éb4567éb"

  --test-- "append-20.1"
	str: "12"
	append/part/dup/only str ["ABCDé" #"5" #"6" 7 é 'b x] 6 2
	--assert str = "12ABCDé5ABCDé5"
	
  --test-- "append-21"
	str: "12"
	append/part/dup str ["4" #"5" #"é" 7 a 'b x] 6 2
	--assert str = "1245é7ab45é7ab"

  --test-- "append-21.1"
	str: "12"
	append/part/dup/only str ["ABCD" #"5" #"é" 7 a 'b x] 6 2
	--assert str = "12ABCD5éABCD5é"

  --test-- "append-22"
	str: "12"
	append/part/dup str ["4" #"5" #"^(010000)" 7 a 'b x] 6 2
	--assert str = "1245^(010000)7ab45^(010000)7ab"

  --test-- "append-22.1"
	str: "12"
	append/part/dup/only str ["4AB" #"5" #"^(010000)" 7 a 'b x] 6 2
	--assert str = "124AB5^(010000)74AB5^(010000)7"

  --test-- "append-23"
	str: "12é"
	append/part/dup str ["4" #"5" #"^(010000)" 7 a 'b x] 6 2
	--assert str = "12é45^(010000)7ab45^(010000)7ab"
	
  --test-- "append-23.1"
	str: "12é"
	append/part/dup/only str ["4AB" #"5" #"^(010000)" 7 a 'b x] 6 2
	--assert str = "12é4AB5^(010000)74AB5^(010000)7"
	
  --test-- "append-24"
	str: "12^(010000)"
	append/part/dup str ["44" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "12^(010000)44567ab44567ab"

  --test-- "append-24.1"
	str: "12^(010000)"
	append/part/dup/only str ["4ABC" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "12^(010000)4ABC564ABC56"

  --test-- "append-24.1"
	str: "12"
	append/part/dup str next ["4" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "12567abx567abx"
	
  --test-- "append-24.2"
	str: "12é"
	append/part/dup str next next ["4" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "12é67abx67abx"

  --test-- "append-24.3"
	str: "12"
	append/part/dup str next next ["4" #"5" #"6" 7 é 'b x] 4 2
	--assert str = "1267éb67éb"
	
  --test-- "append-24.4"
	str: "12"
	append/part/dup str next next ["4" #"5" #"é" 7 a 'b x] 4 2
	--assert str = "12é7abé7ab"

  --test-- "append-24.5"
	str: "12"
	append/part/dup str next next ["4" #"5" #"^(010000)" 7 a 'b x] 4 2
	--assert str = "12^(010000)7ab^(010000)7ab"

  --test-- "append-24.6"
	str: "12é"
	append/part/dup str next next ["4" #"5" #"^(010000)" 7 a 'b x] 4 2
	--assert str = "12é^(010000)7ab^(010000)7ab"
	
  --test-- "append-24.7"
	str: "12^(010000)"
	append/part/dup str next next ["4" #"5" #"6" 7 a 'b x] 5 2
	--assert str = "12^(010000)67abx67abx"

  --test-- "append-24.8"
	str: "12^(010000)"
	append/part/dup/only str next next ["4AB" #"5" #"6" 7 a 'b x] 5 2
	--assert str = "12^(010000)67abx67abx"

  --test-- "append-24.9"
	str: "12^(010000)"
	append/part/dup/only str next next ["4AB" #"5" "6CDE" 7 a 'b x] 5 2
	--assert str = "12^(010000)6CDE76CDE7"

  --test-- "append-25"
    str: "12"
    append/part str "456" 0
    --assert str = "12"

  --test-- "append-26"
    str: "12"
    append/dup/part str "456" 3 0
    --assert str = "12"

  --test-- "append-26.1"
    str: "12"
    append/dup/part str "456" 0 0
    --assert str = "12"
 
  --test-- "append-27"
    str: "12"
    append/part str "456" -1
    --assert str = "12"

  --test-- "append-28"
    str: "12"
    append/dup/part str "456" 3 -1
    --assert str = "12"

  --test-- "append-29"
    str: "12"
    append/dup str "456" -1
    --assert str = "12"

  --test-- "append-30"
    str: "12"
    append/dup/part str "456" -1 -1
    --assert str = "12"

  --test-- "append-31"
    str: "12"
    append/part str "456" 1
    --assert str = "124"
  
  --test-- "append-32"
    str: "12"
    append/part str "456" 100000
    --assert str = "12456"

  --test-- "append-33"
    str: "12"
    append/part str <456> 0
    --assert str = "12"

  --test-- "append-34"
    str: "12"
    append/part str <456> 1
    --assert str = "12<"

  --test-- "append-35"
    str: "12"
    append/part str <456> 2
    --assert str = "12<4"

  --test-- "append-36"
    str: "12"
    append/part str <456> 4
    --assert str = "12<456"

  --test-- "append-37"
    str: "12"
    append/part str <456> 5
    --assert str = "12<456>"

  --test-- "append-38"
    str: "12"
    append/part str <456> 10
    --assert str = "12<456>"
    
  --test-- "append-39"
    str: "12"
    append/part str next <456> 10
    --assert str = "12<56>"
    
  --test-- "append-40"
    str: "12"
    append/part str next <456> 2
    --assert str = "12<5"

  --test-- "append-41"
    str: "12"
    append/part/dup str next <456> 10 3
    --assert str = "12<56><56><56>"
    
  --test-- "append-42"
    str: "12"
    append/part/dup str next <456> 2 3
    --assert str = "12<5<5<5"

  --test-- "append-50"
  	v: make vector! [1 2 3]
  	append v 4
  	--assert v = make vector! [1 2 3 4]

  --test-- "append-51"
  	v: make vector! [1 2 3]
  	append v [4 5]
  	--assert v = make vector! [1 2 3 4 5]

  --test-- "append-52"
  	v: make vector! []
  	append v []
  	--assert v = make vector! []

  --test-- "append-52.1"
	v: make vector! [1 2 3]
	append/part v []  0
	append/part v []  1
	append/part v [] -1
	append/dup  v []  0
	append/dup  v []  1
	append/dup  v [] -1
	append/dup/part v [] 1 1
	--assert v = make vector! [1 2 3]

  --test-- "append-53"
  	v: next next make vector! [1 2 3 4]
  	append v [5 6]
  	--assert v = make vector! [3 4 5 6]
  	--assert 3 = index? v
  	--assert (head v) = make vector! [1 2 3 4 5 6]

  --test-- "append-54"
  	v: make vector! [1 2 3 4]
  	append/part v [5 6 7] 0
  	--assert v = make vector! [1 2 3 4]

  --test-- "append-55"
  	v: make vector! [1 2 3 4]
  	append/part v [5 6 7] -1
  	--assert v = make vector! [1 2 3 4]

  --test-- "append-56"
  	v: make vector! [1 2 3 4]
  	append/part v [5 6 7] 1
  	--assert v = make vector! [1 2 3 4 5]

  --test-- "append-57"
  	v: make vector! [1 2 3 4]
  	append/part v [5 6 7] 2
  	--assert v = make vector! [1 2 3 4 5 6]

  --test-- "append-58"
  	v: make vector! [1 2 3 4]
  	append/part v [5 6 7] 3
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-59"
  	v: make vector! [1 2 3 4]
  	append/part v [5 6 7] 4
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-60"
  	v: make vector! [1 2 3 4]
  	append/part v [5 6 7] 1000000
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-61"
  	v: make vector! [1 2 3 4]
  	append/dup v -1 3
  	--assert v = make vector! [1 2 3 4 -1 -1 -1]

  --test-- "append-62"
  	v: make vector! [1 2 3 4]
  	append/dup v -1 0
  	--assert v = make vector! [1 2 3 4]

  --test-- "append-63"
  	v: make vector! [1 2 3 4]
  	append/dup v -1 -1
  	--assert v = make vector! [1 2 3 4]

  --test-- "append-64"
  	v: make vector! [1 2 3 4]
  	append/dup v [5 6] 0
  	--assert v = make vector! [1 2 3 4]

  --test-- "append-65"
  	v: make vector! [1 2 3 4]
  	append/dup v [5 6] -1
  	--assert v = make vector! [1 2 3 4]

  --test-- "append-66"
  	v: make vector! [1 2 3 4]
  	append/dup v [5 6] 1
  	--assert v = make vector! [1 2 3 4 5 6]

  --test-- "append-67"
  	v: make vector! [1 2 3 4]
  	append/dup v [5 6] 2
  	--assert v = make vector! [1 2 3 4 5 6 5 6]

  --test-- "append-68"
  	v: make vector! [1 2 3 4]
  	append/dup v [5 6] 10
  	--assert v = make vector! [1 2 3 4 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6]

  --test-- "append-69"
  	v: make vector! [1 2 3 4]
  	append/dup/part v [5 6 7 8 9] 1 1
  	--assert v = make vector! [1 2 3 4 5]

  --test-- "append-70"
  	v: make vector! [1 2 3 4]
  	append/dup/part v [5 6 7 8 9] 2 2
  	--assert v = make vector! [1 2 3 4 5 6 5 6]

  --test-- "append-71"
  	v: make vector! [1 2 3 4]
  	append/dup/part v [5 6 7 8 9] 2 3
  	--assert v = make vector! [1 2 3 4 5 6 7 5 6 7]

  --test-- "append-72"
  	v: make vector! [1 2 3 4]
  	append/dup/part v [5 6 7 8 9] 2 4
  	--assert v = make vector! [1 2 3 4 5 6 7 8 5 6 7 8]

  --test-- "append-73"
  	v: make vector! [1 2 3 4]
  	append/dup/part v [5 6 7 8 9] 2 5
  	--assert v = make vector! [1 2 3 4 5 6 7 8 9 5 6 7 8 9]

  --test-- "append-74"
  	v: make vector! [1 2 3 4]
  	append/dup/part v [5 6 7 8 9] 2 6
  	--assert v = make vector! [1 2 3 4 5 6 7 8 9 5 6 7 8 9]

  --test-- "append-75"
  	v: make vector! [1 2 3 4]
  	append/part/dup v [5 6 7 8 9] 1 2
  	--assert v = make vector! [1 2 3 4 5 5]

   --test-- "append-76"
   	v: make vector! [1 2 3 4]
   	append/part/dup v [5 6 7 8 9] 2 2
   	--assert v = make vector! [1 2 3 4 5 6 5 6]


  --test-- "append-150"
  	v: make vector! [integer! 8 [1 2 3]]
  	append v 4
  	--assert v = make vector! [integer! 8 [1 2 3 4]]

  --test-- "append-151"
  	v: make vector! [integer! 8 [1 2 3]]
  	append v [4 5]
  	--assert v = make vector! [integer! 8 [1 2 3 4 5]]

  --test-- "append-152"
  	v: make vector! [integer! 8 []]
  	append v []
  	--assert v = make vector! [integer! 8 []]

  --test-- "append-153"
  	v: next next make vector! [integer! 8 [1 2 3 4]]
  	append v [5 6]
  	--assert v = make vector! [integer! 8 [3 4 5 6]]
  	--assert 3 = index? v
  	--assert (head v) = make vector! [integer! 8 [1 2 3 4 5 6]]

  --test-- "append-154"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/part v [5 6 7] 0
  	--assert v = make vector! [integer! 8 [1 2 3 4]]

  --test-- "append-155"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/part v [5 6 7] -1
  	--assert v = make vector! [integer! 8 [1 2 3 4]]

  --test-- "append-156"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/part v [5 6 7] 1
  	--assert v = make vector! [integer! 8 [1 2 3 4 5]]

  --test-- "append-157"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/part v [5 6 7] 2
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6]]

  --test-- "append-158"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/part v [5 6 7] 3
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-159"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/part v [5 6 7] 4
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-160"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/part v [5 6 7] 1000000
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-161"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup v -1 3
  	--assert v = make vector! [1 2 3 4 -1 -1 -1]

  --test-- "append-162"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup v -1 0
  	--assert v = make vector! [integer! 8 [1 2 3 4]]

  --test-- "append-163"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup v -1 -1
  	--assert v = make vector! [integer! 8 [1 2 3 4]]

  --test-- "append-164"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup v [5 6] 0
  	--assert v = make vector! [integer! 8 [1 2 3 4]]

  --test-- "append-165"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup v [5 6] -1
  	--assert v = make vector! [integer! 8 [1 2 3 4]]

  --test-- "append-166"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup v [5 6] 1
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6]]

  --test-- "append-167"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup v [5 6] 2
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6 5 6]]

  --test-- "append-168"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup v [5 6] 10
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6]]

  --test-- "append-169"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 1 1
  	--assert v = make vector! [integer! 8 [1 2 3 4 5]]

  --test-- "append-170"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 2
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6 5 6]]

  --test-- "append-171"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 3
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6 7 5 6 7]]

  --test-- "append-172"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 4
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6 7 8 5 6 7 8]]

  --test-- "append-173"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 5
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6 7 8 9 5 6 7 8 9]]

  --test-- "append-174"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 6
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 6 7 8 9 5 6 7 8 9]]

  --test-- "append-175"
  	v: make vector! [integer! 8 [1 2 3 4]]
  	append/part/dup v [5 6 7 8 9] 1 2
  	--assert v = make vector! [integer! 8 [1 2 3 4 5 5]]

   --test-- "append-176"
   	v: make vector! [integer! 8 [1 2 3 4]]
   	append/part/dup v [5 6 7 8 9] 2 2
   	--assert v = make vector! [integer! 8 [1 2 3 4 5 6 5 6]]
   	

  --test-- "append-250"
  	v: make vector! [integer! 16 [1 2 3]]
  	append v 4
  	--assert v = make vector! [integer! 16 [1 2 3 4]]

  --test-- "append-251"
  	v: make vector! [integer! 16 [1 2 3]]
  	append v [4 5]
  	--assert v = make vector! [integer! 16 [1 2 3 4 5]]

  --test-- "append-252"
  	v: make vector! [integer! 16 []]
  	append v []
  	--assert v = make vector! [integer! 16 []]

  --test-- "append-253"
  	v: next next make vector! [integer! 16 [1 2 3 4]]
  	append v [5 6]
  	--assert v = make vector! [integer! 16 [3 4 5 6]]
  	--assert 3 = index? v
  	--assert (head v) = make vector! [integer! 16 [1 2 3 4 5 6]]

  --test-- "append-254"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/part v [5 6 7] 0
  	--assert v = make vector! [integer! 16 [1 2 3 4]]

  --test-- "append-255"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/part v [5 6 7] -1
  	--assert v = make vector! [integer! 16 [1 2 3 4]]

  --test-- "append-256"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/part v [5 6 7] 1
  	--assert v = make vector! [integer! 16 [1 2 3 4 5]]

  --test-- "append-257"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/part v [5 6 7] 2
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6]]

  --test-- "append-258"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/part v [5 6 7] 3
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-259"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/part v [5 6 7] 4
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-260"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/part v [5 6 7] 1000000
  	--assert v = make vector! [1 2 3 4 5 6 7]

  --test-- "append-261"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup v -1 3
  	--assert v = make vector! [1 2 3 4 -1 -1 -1]

  --test-- "append-262"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup v -1 0
  	--assert v = make vector! [integer! 16 [1 2 3 4]]

  --test-- "append-263"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup v -1 -1
  	--assert v = make vector! [integer! 16 [1 2 3 4]]

  --test-- "append-264"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup v [5 6] 0
  	--assert v = make vector! [integer! 16 [1 2 3 4]]

  --test-- "append-265"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup v [5 6] -1
  	--assert v = make vector! [integer! 16 [1 2 3 4]]

  --test-- "append-266"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup v [5 6] 1
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6]]

  --test-- "append-267"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup v [5 6] 2
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6 5 6]]

  --test-- "append-268"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup v [5 6] 10
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6]]

  --test-- "append-269"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 1 1
  	--assert v = make vector! [integer! 16 [1 2 3 4 5]]

  --test-- "append-270"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 2
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6 5 6]]

  --test-- "append-271"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 3
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6 7 5 6 7]]

  --test-- "append-272"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 4
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6 7 8 5 6 7 8]]

  --test-- "append-273"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 5
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6 7 8 9 5 6 7 8 9]]

  --test-- "append-274"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/dup/part v [5 6 7 8 9] 2 6
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 6 7 8 9 5 6 7 8 9]]

  --test-- "append-275"
  	v: make vector! [integer! 16 [1 2 3 4]]
  	append/part/dup v [5 6 7 8 9] 1 2
  	--assert v = make vector! [integer! 16 [1 2 3 4 5 5]]

   --test-- "append-276"
   	v: make vector! [integer! 16 [1 2 3 4]]
   	append/part/dup v [5 6 7 8 9] 2 2
   	--assert v = make vector! [integer! 16 [1 2 3 4 5 6 5 6]]


  --test-- "append-450"
  	b: #{010203}
  	append b 4
	append b #"A"
	append b #{1122334455}
	append b "A"
	append b "abc"
	append b red
	append b #"é"
	append b "é"
	append b "AéB"
  	--assert b = #{0102030441112233445541616263FF0000C3A9C3A941C3A942}

  --test-- "append-450.1"
	b: #{010203}
	append append append append append append append append append b 4 #"A" #{1122334455} "A" "abc" red #"é" "é" "AéB"
	--assert b = #{0102030441112233445541616263FF0000C3A9C3A941C3A942}

  --test-- "append-451"
  	b: #{010203}
  	append b [4 5]
  	--assert b = #{0102030405}
  	
  --test-- "append-452"
  	b: #{}
  	append b []
  	--assert b = #{}

  --test-- "append-452.1"
	b: #{010203}
	append/part b []  0
	append/part b []  1
	append/part b [] -1
	append/dup  b []  0
	append/dup  b []  1
	append/dup  b [] -1
	append/dup/part b [] 1 1
	--assert b = #{010203}

  --test-- "append-453"
  	b: next next #{01020304}
  	append b [5 6]
  	--assert b = #{03040506}
  	--assert 3 = index? b
  	--assert (head b) = #{010203040506}

  --test-- "append-454"
  	b: #{01020304}
  	append/part b [5 6 7] 0
  	--assert b = #{01020304}

  --test-- "append-455"
  	b: #{01020304}
  	append/part b [5 6 7] -1
  	--assert b = #{01020304}

  --test-- "append-456"
  	b: #{01020304}
  	append/part b [5 6 7] 1
  	--assert b = #{0102030405}

  --test-- "append-457"
  	b: #{01020304}
  	append/part b [5 6 7] 2
  	--assert b = #{010203040506}

  --test-- "append-458"
  	b: #{01020304}
  	append/part b [5 6 7] 3
  	--assert b = #{01020304050607}

  --test-- "append-459"
  	b: #{01020304}
  	append/part b [5 6 7] 4
  	--assert b = #{01020304050607}

  --test-- "append-460"
  	b: #{01020304}
  	append/part b [5 6 7] 1000000
  	--assert b = #{01020304050607}

  --test-- "append-461"
  	b: #{01020304}
  	append/dup b -1 3
  	--assert b = #{01020304FFFFFF}

  --test-- "append-462"
  	b: #{01020304}
  	append/dup b -1 0
  	--assert b = #{01020304}

  --test-- "append-463"
  	b: #{01020304}
  	append/dup b -1 -1
  	--assert b = #{01020304}

  --test-- "append-464"
  	b: #{01020304}
  	append/dup b [5 6] 0
  	--assert b = #{01020304}

  --test-- "append-465"
  	b: #{01020304}
  	append/dup b [5 6] -1
  	--assert b = #{01020304}

  --test-- "append-466"
  	b: #{01020304}
  	append/dup b [5 6] 1
  	--assert b = #{010203040506}

  --test-- "append-467"
  	b: #{01020304}
  	append/dup b [5 6] 2
  	--assert b = #{0102030405060506}

  --test-- "append-468"
  	b: #{01020304}
  	append/dup b [5 6] 10
  	--assert b = #{010203040506050605060506050605060506050605060506}

  --test-- "append-469"
  	b: #{01020304}
  	append/dup/part b [5 6 7 8 9] 1 1
  	--assert b = #{0102030405}

  --test-- "append-470"
  	b: #{01020304}
  	append/dup/part b [5 6 7 8 9] 2 2
  	--assert b = #{0102030405060506}

  --test-- "append-471"
  	b: #{01020304}
  	append/dup/part b [5 6 7 8 9] 2 3
  	--assert b = #{01020304050607050607}

  --test-- "append-472"
  	b: #{01020304}
  	append/dup/part b [5 6 7 8 9] 2 4
  	--assert b = #{010203040506070805060708}

  --test-- "append-473"
  	b: #{01020304}
  	append/dup/part b [5 6 7 8 9] 2 5
  	--assert b = #{0102030405060708090506070809}

  --test-- "append-474"
  	b: #{01020304}
  	append/dup/part b [5 6 7 8 9] 2 6
  	--assert b = #{0102030405060708090506070809}

  --test-- "append-475"
  	b: #{01020304}
  	append/part/dup b [5 6 7 8 9] 1 2
  	--assert b = #{010203040505}

  --test-- "append-476"
   	b: #{01020304}
   	append/part/dup b [5 6 7 8 9] 2 2
   	--assert b = #{0102030405060506}

  --test-- "append-477"
	values: [#"A" #{1122334455} "A" "abc" 123 255.0.0 #"é" "é" "AéB"]
	;results: [#{41} #{1122334455} #{41} #{616263} #{7B} #{FF0000} #{C3A9} #{C3A9} #{41C3A942}]
	results: #{411122334455416162637BFF0000C3A9C3A941C3A942}
	
	b: #{01020304}
	append/part b values 0
	--assert b = #{01020304}

  --test-- "append-478"
  	b: #{01020304}
  	append/part b values 1
  	--assert b = #{0102030441}

  --test-- "append-479"
  	b: next next #{01020304}
  	append b values
  	--assert b = #{0304411122334455416162637BFF0000C3A9C3A941C3A942}
  	--assert 3 = index? b
  	--assert (head b) = #{01020304411122334455416162637BFF0000C3A9C3A941C3A942}

  --test-- "append-480"
  	b: #{01020304}
  	append/part b values 0
  	--assert b = #{01020304}

  --test-- "append-481"
  	b: #{01020304}
  	append/part b values -1
  	--assert b = #{01020304}

  --test-- "append-482"
  	b: #{01020304}
  	append/part b values 1
  	--assert b = #{0102030441}

  --test-- "append-483"
  	b: #{01020304}
  	append/part b values 2
  	--assert b = #{01020304411122334455}
  	
  --test-- "append-483.1"
  	b: #{01020304}
  	append/part/only b values 2
  	--assert b = #{010203044111}

  --test-- "append-484"
  	b: #{01020304}
  	append/part b values 3
  	--assert b = #{0102030441112233445541}

  --test-- "append-484.1"
  	b: #{01020304}
  	append/part/only b values 3
  	--assert b = #{01020304411122}

  --test-- "append-485"
  	b: #{01020304}
  	append/part b values 4
  	--assert b = #{0102030441112233445541616263}

  --test-- "append-485.1"
  	repeat i length? results [
		b: copy #{01020304}
		append/part/only b values i
		--assert #{01020304} == copy/part b 4
		--assert (skip b 4) == copy/part results i
	]

  --test-- "append-486"
  	b: #{01020304}
  	append/part b values 1000000
  	--assert b = #{01020304411122334455416162637BFF0000C3A9C3A941C3A942}

  --test-- "append-487"
  	b: #{01020304}
  	append/dup b values 0
  	--assert b = #{01020304}

  --test-- "append-488"
  	b: #{01020304}
  	append/dup b values -1
  	--assert b = #{01020304}

  --test-- "append-489"
  	b: #{01020304}
  	append/dup b values 1
  	--assert b = #{01020304411122334455416162637BFF0000C3A9C3A941C3A942}

  --test-- "append-490"
  	b: #{01020304}
  	append/dup b values 2
  	--assert b = #{01020304411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942}

  --test-- "append-491"
  	b: #{01020304}
  	append/dup b values 10
  	--assert b = #{01020304411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942}

  --test-- "append-492"
  	b: #{01020304}
  	append/dup/part b values 1 1
  	--assert b = #{0102030441}

  --test-- "append-493"
  	b: #{01020304}
  	append/dup/part b values 2 2
  	--assert b = #{01020304411122334455411122334455}

  --test-- "append-493.1"
  	b: #{01020304}
  	append/dup/part/only b values 2 2
  	--assert b = #{0102030441114111}

  --test-- "append-494"
  	b: #{01020304}
  	append/dup/part b values 2 3
  	--assert b = #{010203044111223344554141112233445541}
  	
  --test-- "append-494.1"
  	b: #{01020304}
  	append/dup/part/only b values 2 3
  	--assert b = #{01020304411122411122}

  --test-- "append-495"
  	b: #{01020304}
  	append/dup/part b values 2 4
  	--assert b = #{010203044111223344554161626341112233445541616263}

  --test-- "append-495.1"
  	b: #{01020304}
  	append/dup/part/only b values 2 4
  	--assert b = #{010203044111223341112233}
  	
  --test-- "append-496"
  	b: #{01020304}
  	append/dup/part b values 2 5
  	--assert b = #{01020304411122334455416162637B411122334455416162637B}

  --test-- "append-496.1"
  	b: #{01020304}
  	append/dup/part/only b values 2 5
  	--assert b = #{0102030441112233444111223344}

  --test-- "append-497"
  	b: #{01020304}
  	append/dup/part b values 2 6
  	--assert b = #{01020304411122334455416162637BFF0000411122334455416162637BFF0000}

  --test-- "append-497.1"
  	b: #{01020304}
  	append/dup/part/only b values 2 6
  	--assert b = #{01020304411122334455411122334455}

  --test-- "append-498"
  	b: #{01020304}
  	append/part/dup b values 1 2
  	--assert b = #{010203044141}

  --test-- "append-498.1"
  	b: #{01020304}
  	append/part/dup/only b values 1 2
  	--assert b = #{010203044141}

  --test-- "append-499"
   	b: #{01020304}
   	append/part/dup b values 2 2
   	--assert b = #{01020304411122334455411122334455}
 
   --test-- "append-499.1"
	b: #{01020304}
	append/part/dup/only b values 2 2
   	--assert b = #{0102030441114111}
   	
    --test-- "append-500"
    b: #{01020304}
    append b b
    --assert b == #{0102030401020304}

    --test-- "append-501"
    b: #{01020304}
    append/part b b 1  
    --assert b == #{0102030401}
    
    --test-- "append-502"
    b: #{01020304}
    append/part b b 2   
    --assert b == #{010203040102}

    --test-- "append-503"
    b: #{01020304}
    append/part/dup b b 2 2 
    --assert b == #{0102030401020102}

    --test-- "append-504"
    b: #{01020304}
    append/part/dup b b 10 2   
    --assert b == #{010203040102030401020304}

    --test-- "append-505"
    b: #{01020304}
    append/part/dup/only b b 2 2   
    --assert b == #{0102030401020102}

    --test-- "append-506"
    b: #{01020304}
    append/part/dup/only b b 10 2   
    --assert b == #{010203040102030401020304}

	--test-- "append-507"							;@@ undefined semantics, just checks that it doesn't crash
	b: #{01020304}
	append/part/dup b reduce [b b b] 2 2
	;--assert b == #{010203040102030401020304}

	--test-- "append-508"							;@@ undefined semantics, just checks that it doesn't crash
	b: #{01020304}
	append/part/dup/only b reduce [b b b] 10 2
	;--assert b == #{010203040102030401020304}

===end-group===

===start-group=== "append/dup"
	
	--test-- "append/dup1"
		ad1-s: copy ""
		append/dup ad1-s #" " 10
		--assert 10 = length? ad1-s
		--assert "          " = ad1-s
	
	--test-- "append/dup2"
		ad2-s: copy ""
		append/dup ad2-s #"1" 9
		--assert 9 = length? ad2-s
		--assert "111111111" = ad2-s
	
	--test-- "append/dup2"
		ad3-s: copy []
		append/dup ad3-s 1 8
		--assert 8 = length? ad3-s
		--assert [1 1 1 1 1 1 1 1] = ad3-s
	
	--test-- "append/dup4"
		ad4-s: copy " "
		append/dup ad4-s #" " 10
		--assert 11 = length? ad4-s
		--assert "           " = ad4-s
	--test-- "append/dup5"
		ad5-s: copy ""
		append/dup ad5-s #" " 1'000'000
		--assert 1'000'000 = length? ad5-s

===end-group===


===start-group=== "big strings" 
	
	--test-- "bg1"
		bg1-s: copy ""
		loop 1'000'000 [
			append bg1-s #"a"
		]
		--assert 1'000'000 = length? bg1-s
		clear bg1-s
	
	--test-- "bg2"
		bg2-s: copy ""
		loop 1'000'000 [
			append bg2-s #"é"
		]
		--assert 1'000'000 = length? bg2-s
		clear bg2-s
	
	--test-- "bg3"
		bg3-s: copy ""
		loop 1'000'000 [
			append bg3-s #"✐"
		]
		--assert 1'000'000 = length? bg3-s
		clear bg3-s
	
		--test-- "bg4"
		bg4-s: copy ""
		loop 1'000'000 [
			append bg4-s #"^(2710)"
		]
		--assert 1'000'000 = length? bg4-s
		clear bg4-s
		
===end-group===


~~~end-file~~~

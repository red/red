Red [
	Title:	 "Red money! datatype test script"
	Author:	 "Vladimir Vasilyev"
	File:	 %money-test.red
	Tabs:	 4
	Rights:	 "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "money"

system/options/money-digits: 5						;-- enforce molding of the whole fractional part

===start-group=== "zero?"
	--test-- "zero-1" --assert zero? -$0
	--test-- "zero-2" --assert zero? +$0
	--test-- "zero-3" --assert not zero? $0.1
	--test-- "zero-4" --assert not zero? -$2
===end-group===

===start-group=== "negative?"
	--test-- "negative-1" --assert negative? -$1
	--test-- "negative-2" --assert not negative? +$0
	--test-- "negative-3" --assert not negative? -$0
	--test-- "negative-4" --assert not negative? +$1
===end-group===

===start-group=== "positive?"
	--test-- "positive-1" --assert positive? +$1
	--test-- "positive-2" --assert not positive? +$0
	--test-- "positive-3" --assert not positive? -$0
	--test-- "positive-4" --assert not positive? -$1
===end-group===

===start-group=== "even?"
	--test-- "even-1" --assert even? $0
	--test-- "even-2" --assert even? $2.345
	--test-- "even-3" --assert even? -$4.678
	--test-- "even-4" --assert not even? $5
===end-group===

===start-group=== "odd?"
	--test-- "odd-1" --assert odd? $1.234
	--test-- "odd-2" --assert odd? -$3.456
	--test-- "odd-3" --assert odd? $12345678901234567.12345
	--test-- "odd-4" --assert not odd? $0.12345
===end-group===

===start-group=== "equal?"
	--test-- "equal-1" --assert equal? $0 $0
	--test-- "equal-2" --assert equal? $0.12345 $0.12345
	--test-- "equal-3" --assert equal? +$0 -$0
	--test-- "equal-4" --assert equal? -$000123.45 -$123.45000
	--test-- "equal-5" --assert equal? $123.456 123.456
	--test-- "equal-6" --assert equal? -$2147483648 -2147483648
===end-group===

===start-group=== "not-equal?"
	--test-- "not-equal-1" --assert not-equal? +$1 -$1
	--test-- "not-equal-2" --assert not-equal? $0.00001 $0.0001
	--test-- "not-equal-3" --assert not-equal? $123.456 $12.3456
	--test-- "not-equal-4" --assert not-equal? -$1 -$2
	--test-- "not-equal-5" --assert not-equal? $123.45 123
	--test-- "not-equal-6" --assert not-equal? $123.45 123.456
===end-group===

===start-group=== "strict-equal?"
	--test-- "strict-equal-1" --assert strict-equal? $12345678901234567.12345 $12345678901234567.12345
	--test-- "strict-equal-2" --assert not strict-equal? $123.456 123.456
	--test-- "strict-equal-3" --assert not strict-equal? $123 123
	--test-- "strict-equal-4" --assert strict-equal? -$0 +$0
	--test-- "strict-equal-5" --assert strict-equal? -$1 -$1
	--test-- "strict-equal-6" --assert strict-equal? +$1 +$1
	--test-- "strict-equal-7" --assert strict-equal? +USD$1 +USD$1
	--test-- "strict-equal-8" --assert not strict-equal? +$1 +USD$1
	--test-- "strict-equal-9" --assert not strict-equal? +EUR$1 +$1
===end-group===

===start-group=== "same?"
	--test-- "same-1"  --assert same? $12345678901234567.12345 $12345678901234567.12345
	--test-- "same-2"  --assert not same? $123.456 123.456
	--test-- "same-3"  --assert not same? $123 123
	--test-- "same-4"  --assert same? -$0 +$0
	--test-- "same-5"  --assert same? -$1 -$1
	--test-- "same-6"  --assert same? +$1 +$1
	--test-- "same-7"  --assert same? +USD$1 +USD$1
	--test-- "same-8"  --assert not same? +USD$1 +$1
	--test-- "same-9"  --assert not same? +$1 +USD$1
	--test-- "same-10" --assert same? -$0 +$0
	--test-- "same-11" --assert not same? $0 USD$0
	--test-- "same-12" --assert same? USD$0 USD$0
	--test-- "same-13" --assert not same? USD$0 EUR$0
	--test-- "same-14" --assert same? +USD$0 -USD$0
===end-group===

===start-group=== "lesser?"
	--test-- "lesser-1" --assert lesser? $0 1
	--test-- "lesser-2" --assert lesser? 1 $2
	--test-- "lesser-3" --assert lesser? -$1 $2
	--test-- "lesser-4" --assert lesser? -$1 $0
	--test-- "lesser-5" --assert lesser? $1 1.00001
	--test-- "lesser-6" --assert lesser? -1.00001 -$1
	--test-- "lesser-7" --assert not lesser? -$0 +$0
===end-group===

===start-group=== "greater?"
	--test-- "greater-1" --assert greater? $1 0
	--test-- "greater-2" --assert greater? 2 $1
	--test-- "greater-3" --assert greater? $2 -1
	--test-- "greater-4" --assert greater? $0 -$1
	--test-- "greater-5" --assert greater? -$1 -1.00001
	--test-- "greater-6" --assert greater? 1.00001 $1
	--test-- "greater-7" --assert not greater? +$0 -$0
===end-group===

===start-group=== "lesser-or-equal?"
	--test-- "lesser-or-equal-1" --assert lesser-or-equal? $0 0
	--test-- "lesser-or-equal-2" --assert lesser-or-equal? 0 $1
	--test-- "lesser-or-equal-3" --assert lesser-or-equal? $1 $1
	--test-- "lesser-or-equal-4" --assert lesser-or-equal? $1 2.0
	--test-- "lesser-or-equal-5" --assert lesser-or-equal? -1.0 $1
	--test-- "lesser-or-equal-6" --assert lesser-or-equal? -$2 -1
	--test-- "lesser-or-equal-7" --assert lesser-or-equal? -$2 -$2
===end-group===

===start-group=== "greater-or-equal?"
	--test-- "greater-or-equal-1" --assert greater-or-equal? $0 0
	--test-- "greater-or-equal-2" --assert greater-or-equal? 1 $0
	--test-- "greater-or-equal-3" --assert greater-or-equal? $1 1.0
	--test-- "greater-or-equal-4" --assert greater-or-equal? 2.0 $1
	--test-- "greater-or-equal-5" --assert greater-or-equal? $1 -1
	--test-- "greater-or-equal-6" --assert greater-or-equal? -$1 -2.0
	--test-- "greater-or-equal-7" --assert greater-or-equal? -$2 -$2
===end-group===

===start-group=== "min"
	--test-- "min-1" --assert $0 == min $0 $0
	--test-- "min-2" --assert $1 == min 2 $1
	--test-- "min-3" --assert -$1 == min -$1 0
	--test-- "min-4" --assert -$2 == min -$1 -$2
	--test-- "min-5" --assert $1.99999 == min $1.99999 $2
===end-group===

===start-group=== "max"
	--test-- "max-1" --assert $0 == max $0 $0
	--test-- "max-2" --assert $2 == max $2 1
	--test-- "max-3" --assert -$1 == max -2 -$1
	--test-- "max-4" --assert $2 == max $2 -$1
	--test-- "max-5" --assert -$1 == max -$1.99999 -$1
===end-group===

===start-group=== "negate"
	--test-- "negate-1" --assert $0 == negate $0
	--test-- "negate-2" --assert -$1 == negate $1
	--test-- "negate-3" --assert $1 == negate -$1
===end-group===

===start-group=== "absolute"
	--test-- "absolute-1" --assert $0 == absolute $0
	--test-- "absolute-2" --assert $1 == absolute $1
	--test-- "absolute-3" --assert $1 == absolute -$1
===end-group===

===start-group=== "to"
	--test-- "to-1"  --assert $123.456 == to money! $123.456
	--test-- "to-2"  --assert $123.456 == to money! 123.456
	--test-- "to-3"  --assert $123 == to money! 123
	--test-- "to-4"  --assert 123 == to integer! to money! 123
	--test-- "to-5"  --assert 123.456 == to float! to money! 123.456
	--test-- "to-6"  --assert 2147483647 == to integer! $2147483647
	--test-- "to-7"  --assert -2147483648 == to integer! -$2147483648
	--test-- "to-8"  --assert error? try [to integer! $9999999999]
	--test-- "to-9"  --assert 0.00001 == to float! to money! 0.00001
	--test-- "to-10" --assert error? try [to float! to money! 0.000001]
	--test-- "to-11" --assert error? try [to money! 0 / 0.0]  ;-- 1.#NaN
	--test-- "to-12" --assert error? try [to money! 1 / 0.0]  ;-- 1.#INF
	--test-- "to-13" --assert error? try [to money! -1 / 0.0] ;-- -1.#INF
	--test-- "to-14" --assert "$123.00000" == to string! $123
	--test-- "to-15" --assert "-$12'345'678'901'234'567.12345" == to string! -$12345678901234567.12345
	--test-- "to-16" --assert $12'345'678'901'234'567.12345 == to money! <12345678901234567.12345>
	--test-- "to-17" --assert error? try [to money! "123456789O123456.12345"]
	--test-- "to-18" --assert error? try [to money! "123456789O12345.123456"]
	--test-- "to-19" --assert error? try [to money! "$123456789O'12345'6.12345"]
	--test-- "to-20" --assert error? try [to money! "$123456789O'12345.123456"]
	--test-- "to-21" --assert $12345678901234567.12345 == to money! "$000'000'1234567890'1234567.12345"
	--test-- "to-22" --assert $12345678901234568 == to money! 12345678901234567.12345	;-- loosing a wee bit of precision in least significant digit and fractional part (rounding up)
	--test-- "to-23" --assert error? try [to money! 123456789012345678.0]
	--test-- "to-24" --assert error? try [to money! 0.123456]
	--test-- "to-25" --assert "EUR$1'234.56789" == to string! EUR$1234.56789
	--test-- "to-26" --assert USD$123.45678 == to money! "+USD$123.45678"
	--test-- "to-27" --assert error? try [to money! "CCC$123"]
	--test-- "to-28" --assert error? try [to money! "123$456"]
	--test-- "to-29" --assert error? try [to money! "EUR123"]
	--test-- "to-30" --assert error? try [to money! "EUR123"]
	--test-- "to-31"
		--assert error? try [to money! "$"]
		--assert error? try [to money! "$."]
		--assert error? try [to money! "-$."]
		--assert error? try [to money! "+$."]
		--assert error? try [to money! "EUR$0."]
		--assert error? try [to money! "EUR$,"]
		--assert error? try [to money! "-USD$.0"]
		--assert error? try [to money! "."]
		--assert error? try [to money! "+."]
		--assert error? try [to money! "-."]
		--assert error? try [to money! ",0"]
		--assert error? try [to money! "0,"]
		--assert error? try [to money! "$.0"]
		--assert error? try [to money! "$0."]
		--assert error? try [to money! "$'1"]
		--assert error? try [to money! "$1'"]
		--assert error? try [to money! "$1''2"]
		--assert error? try [to money! "$1'.2"]
		--assert error? try [to money! "$1',2"]
		--assert error? try [to money! "$1234.45'678"]
	--test-- "to-32"								;-- implicit conversion from float to money
		--assert error? try [to money! 1e17]
		--assert error? try [to money! 1e-6]
		--assert $1 > 1e-6
		--assert $2 < 1e17
		--assert 1e-5 > $0
		--assert 1e17 > $3
	--test-- "to-33"
		--assert $1234 == to money! "$1'2'3'4"
		--assert $1234 == to money! "$1'234"
		--assert $1234.56789 == to money! "$1'234.56789"
		--assert $1234.56789 == to money! "$000'00'0'1234.56789"
		
	--test-- "#5415"
		--assert error? try [to money! "_1"]
		--assert error? try [to money! "/1"]
		--assert error? try [to money! "a1"]
		--assert error? try [to money! "$a1"]
		--assert error? try [to money! "$-1"]
		--assert error? try [to money! "-$-1"]
		
===end-group===

===start-group=== "make"
	--test-- "make-1"  --assert error? try [make money! []]
	--test-- "make-2"  --assert error? try [make money! [CCC]]
	--test-- "make-3"  --assert error? try [make money! [CCC 1 2 3]]
	--test-- "make-4"  --assert error? try [make money! [0 123456]]
	--test-- "make-5"  --assert -$123.00456 == make money! [-123 456]
	--test-- "make-6"  --assert -$123.456 == make money! [-123.456]
	--test-- "make-7"  --assert "-EUR$123.45600" == mold/all make money! [EUR -123.456]
	--test-- "make-8"  --assert "-USD$123.00000" == mold/all make money! [USD -123]
	--test-- "make-9"  --assert "-EUR$123.00000" == mold/all make money! [EUR -123 0]
	--test-- "make-10" --assert "-EUR$456.78900" == mold/all make money! [EUR -456 78900]
	--test-- "make-11" --assert "USD$0.00000" == mold/all make money! 'usd
	--test-- "make-12" --assert "EUR$0.00000" == mold/all make money! 'EUR
	--test-- "make-13" --assert error? try [make money! 'foo]
	--test-- "make-14" --assert error? try [make money! [123.45 6789]]
	--test-- "make-15"
		--assert not error? try [foreach c system/locale/currencies/list [make money! c]]
===end-group===

===start-group=== "form/mold"
	--test-- "form/mold-1" --assert "" == form/part $123.45678 0
	--test-- "form/mold-2" --assert "" == mold/part $123.45678 0
	--test-- "form/mold-3" --assert "$" == form/part $123 1
	--test-- "form/mold-4" --assert "$123.45678" == form/part $123.45678 12345678
	--test-- "form/mold-5" --assert "$1'" == form/part +$1234 3
	--test-- "form/mold-6" --assert "-$1" == mold/part -$1234 3
	--test-- "form/mold-7" --assert "USD" == form/part +USD$0 3
	--test-- "form/mold-8" --assert "-EU" == mold/part -EUR$1 3
	--test-- "form/mold-9"
		system/options/money-digits: -1
		--assert "$123" == mold $123.45678
		--assert "$123.45678" == mold/all $123.45678
		system/options/money-digits: 1
		--assert "-$123.4" == mold -$123.45678
		--assert "-$123.45678" == mold/all -$123.45678
		system/options/money-digits: 10
		--assert "$123.45678" == mold +$123.45678
		--assert "$123.45678" == mold/all +$123.45678
===end-group===

===start-group=== "currencies"
	--test-- "currencies-1"  --assert 1 + USD$1 == USD$2 
	--test-- "currencies-2"  --assert USD$2 + 1 == USD$3
	--test-- "currencies-3"  --assert USD$4 - USD$4 == USD$0
	--test-- "currencies-4"  --assert $1 * -1 == -$1
	--test-- "currencies-5"  --assert -2.0 * $1 == -$2
	--test-- "currencies-6"  --assert error? try [USD$1 + EUR$1]
	--test-- "currencies-7"  --assert error? try [EUR$2 - USD$2]
	--test-- "currencies-8"  --assert USD$1 == USD$1
	--test-- "currencies-9"  --assert -USD$2 == -USD$2
	--test-- "currencies-10" --assert EUR$123 <> USD$123
	--test-- "currencies-11" --assert $1 < EUR$2
	--test-- "currencies-12" --assert USD$3 <= $3
	--test-- "currencies-13" --assert error? try [USD$1 > EUR$1]
	--test-- "currencies-14" --assert error? try [USD$0 >= EUR$0]
	--test-- "currencies-15"
		block: [EUR$1]
		--assert error? try [block < [USD$1]]
		--assert "[...]" <> mold block
===end-group===

===start-group=== "arithmetic"
	--test-- "arithmetic-1"  --assert error? try [$1 * $1]
	--test-- "arithmetic-2"  --assert $2 * 3 == $6
	--test-- "arithmetic-3"  --assert $4 * 0.5 == $2
	--test-- "arithmetic-4"  --assert 4 * $0.25 == $1
	--test-- "arithmetic-5"  --assert 0.5 * $8 == $4
	--test-- "arithmetic-6"  --assert $8 / $4 == 2.0
	--test-- "arithmetic-7"  --assert $8 / 4 == $2
	--test-- "arithmetic-8"  --assert $4 / 0.5 == $8
	--test-- "arithmetic-9"  --assert error? try [4 / $2]
	--test-- "arithmetic-10" --assert error? try [8.0 / $4]
	--test-- "arithmetic-11" --assert $8 % $3 == $2
	--test-- "arithmetic-12" --assert $10 % 3  == $1
	--test-- "arithmetic-13" --assert $4 % 4.0 == $0
	--test-- "arithmetic-14" --assert error? try [8 % $8]
	--test-- "arithmetic-15" --assert error? try [3.0 % $2]
===end-group===

===start-group=== "add"
	max-money: $99999999999999999.99999
	min-money: negate max-money
	--test-- "add-1"  --assert $0 == add $0 $0
	--test-- "add-2"  --assert $0 == add $1 -$1
	--test-- "add-3"  --assert $0 == add -$1 $1
	--test-- "add-4"  --assert -$2 == add -$1 -$1
	--test-- "add-5"  --assert error? try [add max-money 1]
	--test-- "add-6"  --assert error? try [add min-money -1]
	--test-- "add-7"  --assert max-money == add max-money 0
	--test-- "add-8"  --assert min-money == add min-money 0
	--test-- "add-9"  --assert $2 == add $1 $1
	--test-- "add-10" --assert $444.444 == add $123.321 $321.123
	--test-- "add-11" --assert $1000.01998 == add $1000.00999 $0.00999
	--test-- "add-12" --assert $1111.11111 == add $1010.10101 $0101.01010
	--test-- "add-13" --assert $0 == add min-money max-money
	--test-- "add-14" --assert $1000.00999 == add $999.99999 $0.01
	--test-- "add-15" --assert $198 == add $321 -$123
===end-group===

===start-group=== "subtract"
	max-money: $99999999999999999.99999
	min-money: negate max-money
	--test-- "subtract-1"  --assert $0 == subtract $0 $0
	--test-- "subtract-2"  --assert $0 == subtract $1 $1
	--test-- "subtract-3"  --assert $0 == subtract -$1 -$1
	--test-- "subtract-4"  --assert $1 == subtract $4 $3
	--test-- "subtract-5"  --assert -$1 == subtract $3 $4
	--test-- "subtract-6"  --assert -$7 == subtract -$4 $3
	--test-- "subtract-7"  --assert $1 == subtract -$3 -$4
	--test-- "subtract-8"  --assert -$1 == subtract -$4 -$3
	--test-- "subtract-9"  --assert $0 == subtract max-money max-money
	--test-- "subtract-10" --assert $0 == subtract min-money min-money
	--test-- "subtract-11" --assert error? try [subtract max-money min-money]
	--test-- "subtract-12" --assert error? try [subtract min-money max-money]
	--test-- "subtract-13" --assert $090.909 == subtract $989.898 $898.989
	--test-- "subtract-14" --assert $998001 == subtract $999000 $000999
	--test-- "subtract-15" --assert $1985654.32092 == subtract $997999.99992 -$987654.3210
===end-group===

===start-group=== "multiply"
	max-money: $99999999999999999.99999
	min-money: negate max-money
	--test-- "multiply-1"  --assert $0 == multiply $0 0
	--test-- "multiply-2"  --assert $0 == multiply $0 1
	--test-- "multiply-3"  --assert $2 == multiply $2 1
	--test-- "multiply-4"  --assert $1 == multiply $0.001 1000
	--test-- "multiply-5"  --assert -$8 == multiply -$4 2
	--test-- "multiply-6"  --assert -$4 == multiply $8 -0.5
	--test-- "multiply-7"  --assert -$4 == multiply -$0.00025 16000
	--test-- "multiply-8"  --assert $2.02016 == multiply $8 0.25252
	--test-- "multiply-9"  --assert $72.05088 == multiply $9.00123 8.00456
	--test-- "multiply-10" --assert $1303030.30302 == multiply $434343.43434 3
	--test-- "multiply-11" --assert error? try [multiply $0.12345 0.00001]
	--test-- "multiply-12" --assert error? try [multiply max-money 1.1]
	--test-- "multiply-13" --assert $999999999999.99999 == multiply -$33333333333333333.33333 -0.00003
	--test-- "multiply-14" --assert min-money == multiply $33333333333333333.33333 -3
	--test-- "multiply-15" --assert error? try [multiply $1 $1]
===end-group===

===start-group=== "divide"
	max-money: $99999999999999999.99999
	min-money: negate max-money
	--test-- "divide-1"  --assert 0.0 == divide $0 $1
	--test-- "divide-2"  --assert $0 == divide $0 1
	--test-- "divide-3"  --assert error? try [divide $0 0]
	--test-- "divide-4"  --assert error? try [divide 0 $1]
	--test-- "divide-5"  --assert 1.0 == divide -$12345 -$12345
	--test-- "divide-6"  --assert $2407581171 == divide $4815162342 2
	--test-- "divide-7"  --assert -$4815162342 == divide $2407581171 -0.5
	--test-- "divide-8"  --assert -0.25 == divide -$1 $4
	--test-- "divide-9"  --assert error? try [divide $1234567890123.45678 0.00001]
	--test-- "divide-10" --assert $123.45678 == divide $123.45678 1
	--test-- "divide-11" --assert 123.0 == divide $0.00123 $0.00001
	--test-- "divide-12" --assert error? try [divide $123 100000000]
	--test-- "divide-13" --assert $33333333333333333.33333 == divide max-money 3
	--test-- "divide-14" --assert -1.0 == divide max-money min-money
	--test-- "divide-15" --assert $00000000000000009.99999 == divide max-money 1e16
===end-group===

===start-group=== "remainder"
	max-money: $99999999999999999.99999
	min-money: negate max-money
	--test-- "remainder-1"  --assert error? try [remainder $0 0]
	--test-- "remainder-2"  --assert $0 == remainder $0 1
	--test-- "remainder-3"  --assert $0.456 == remainder $123.456 1
	--test-- "remainder-4"  --assert error? try [remainder 123.456 $1]
	--test-- "remainder-5"  --assert $5.856 == remainder $321.456 $7.89
	--test-- "remainder-6"  --assert $2 == remainder $8 3
	--test-- "remainder-7"  --assert $2 == remainder $8 -3
	--test-- "remainder-8"  --assert -$2 == remainder -$8 3
	--test-- "remainder-9"  --assert -$2 == remainder -$8 -3
	--test-- "remainder-10" --assert $000000000999999.99999 == remainder max-money 1e6
	--test-- "remainder-11" --assert $0 == remainder max-money min-money
	--test-- "remainder-12" --assert $0.006 == remainder $123.456 0.01
	--test-- "remainder-13" --assert $0.00001 == remainder $0.00009 0.00004
	--test-- "remainder-14" --assert $0.2 == remainder $9 0.4
	--test-- "remainder-15" --assert $0.56789 == remainder $0.56789 123.456
===end-group===

===start-group=== "rounding"
	max-money: +$99'999'999'999'999'999.9999
	min-money: -$99'999'999'999'999'999.9999
	
	--test-- "round"
		--assert -$4.0 == round -$3.5
		--assert -$3.0 == round -$2.9
		--assert -$3.0 == round -$2.5
		--assert -$2.0 == round -$1.9
		--assert -$1.0 == round -$1.1
		--assert -$1.0 == round -$0.5
		--assert -$0.0 == round -$0.1
		--assert -$0.0 == round -$0.0
		--assert +$0.0 == round +$0.0
		--assert +$0.0 == round +$0.1
		--assert +$1.0 == round +$0.5
		--assert +$1.0 == round +$1.1
		--assert +$2.0 == round +$1.9
		--assert +$3.0 == round +$2.5
		--assert +$3.0 == round +$2.9
		--assert +$4.0 == round +$3.5
		--assert error? try [round max-money]
		--assert error? try [round min-money]
	
	--test-- "round/to"
		--assert $0     == round/to $0 123
		--assert $123   == round/to $123.45 -$1.0
		--assert -$68   == round/to -$67.89 1.0
		--assert $3.0   == round/to/floor $4.5 3.0
		--assert -$6.0  == round/to/floor -$4.5 3
		--assert $6.0   == round/to/ceiling $4.5 -3.0
		--assert -$3.0  == round/to/ceiling -$4.5 3
		--assert -$6.0  == round/to -$4.5 3.0
		--assert +$6.0  == round/to +$4.5 3
		--assert EUR$4.998 == round/to EUR$5 0.357
		--assert $3.8   == round/to $3.75 0.1
		--assert $1.375 == round/to $1.333 -$0.125
		--assert $1.33  == round/to $1.333 0.01
		--assert -USD$3.0  == round/to/floor -USD$2.4 $1.0
		--assert -$2.0  == round/to/ceiling -$2.4 1.0
		--assert -$4.0  == round/to/floor -$2.4 2.0
		--assert -$1.0  == round/to -$0.50 1
		--assert $0.0   == round/to -$0.49 1
		--assert $123.4 == round/to  $123.4 0
		--assert error? try [round/to $123 1e-10]	;-- out of money's representation range
		--assert error? try [round/to $123 100%]
		--assert error? try [round/to $123 1:2:3]

	--test-- "round/even"
		--assert -$4.0 == round/even -$3.5
		--assert -$3.0 == round/even -$2.9
		--assert -$2.0 == round/even -$2.5
		--assert -$2.0 == round/even -$1.9
		--assert -$1.0 == round/even -$1.1
		--assert -$0.0 == round/even -$0.5
		--assert -$0.0 == round/even -$0.1
		--assert -$0.0 == round/even -$0.0
		--assert +$0.0 == round/even +$0.0
		--assert +$0.0 == round/even +$0.1
		--assert +$0.0 == round/even +$0.5
		--assert +$1.0 == round/even +$1.1
		--assert +$2.0 == round/even +$1.9
		--assert +$2.0 == round/even +$2.5
		--assert +$3.0 == round/even +$2.9
		--assert +$4.0 == round/even +$3.5
		--assert error? try [round/even max-money]
		--assert error? try [round/even min-money]

	--test-- "round/down"
		--assert -$3.0 == round/down -$3.5
		--assert -$2.0 == round/down -$2.9
		--assert -$2.0 == round/down -$2.5
		--assert -$1.0 == round/down -$1.9
		--assert -$1.0 == round/down -$1.1
		--assert -$0.0 == round/down -$0.5
		--assert -$0.0 == round/down -$0.1
		--assert -$0.0 == round/down -$0.0
		--assert +$0.0 == round/down +$0.0
		--assert +$0.0 == round/down +$0.1
		--assert +$0.0 == round/down +$0.5
		--assert +$1.0 == round/down +$1.1
		--assert +$1.0 == round/down +$1.9
		--assert +$2.0 == round/down +$2.5
		--assert +$2.0 == round/down +$2.9
		--assert +$3.0 == round/down +$3.5
		--assert +$99'999'999'999'999'999 == round/down max-money
		--assert -$99'999'999'999'999'999 == round/down min-money
	
	--test-- "round/half-down"
		--assert -$3.0 == round/half-down -$3.5
		--assert -$3.0 == round/half-down -$2.9
		--assert -$2.0 == round/half-down -$2.5
		--assert -$2.0 == round/half-down -$1.9
		--assert -$1.0 == round/half-down -$1.1
		--assert -$0.0 == round/half-down -$0.5
		--assert -$0.0 == round/half-down -$0.1
		--assert -$0.0 == round/half-down -$0.0
		--assert +$0.0 == round/half-down +$0.0
		--assert +$0.0 == round/half-down +$0.1
		--assert +$0.0 == round/half-down +$0.5
		--assert +$1.0 == round/half-down +$1.1
		--assert +$2.0 == round/half-down +$1.9
		--assert +$2.0 == round/half-down +$2.5
		--assert +$3.0 == round/half-down +$2.9
		--assert +$3.0 == round/half-down +$3.5
		--assert error? try [round/half-down max-money]
		--assert error? try [round/half-down min-money]
	
	--test-- "round/floor"
		--assert -$4.0 == round/floor -$3.5
		--assert -$3.0 == round/floor -$2.9
		--assert -$3.0 == round/floor -$2.5
		--assert -$2.0 == round/floor -$1.9
		--assert -$2.0 == round/floor -$1.1
		--assert -$1.0 == round/floor -$0.5
		--assert -$1.0 == round/floor -$0.1
		--assert -$0.0 == round/floor -$0.0
		--assert +$0.0 == round/floor +$0.0
		--assert +$0.0 == round/floor +$0.1
		--assert +$0.0 == round/floor +$0.5
		--assert +$1.0 == round/floor +$1.1
		--assert +$1.0 == round/floor +$1.9
		--assert +$2.0 == round/floor +$2.5
		--assert +$2.0 == round/floor +$2.9
		--assert +$3.0 == round/floor +$3.5
		--assert +$99'999'999'999'999'999 == round/floor max-money
		--assert error? try [round/floor min-money]
	
	--test-- "round/ceiling"
		--assert -$3.0 == round/ceiling -$3.5
		--assert -$2.0 == round/ceiling -$2.9
		--assert -$2.0 == round/ceiling -$2.5
		--assert -$1.0 == round/ceiling -$1.9
		--assert -$1.0 == round/ceiling -$1.1
		--assert -$0.0 == round/ceiling -$0.5
		--assert -$0.0 == round/ceiling -$0.1
		--assert -$0.0 == round/ceiling -$0.0
		--assert +$0.0 == round/ceiling +$0.0
		--assert +$1.0 == round/ceiling +$0.1
		--assert +$1.0 == round/ceiling +$0.5
		--assert +$2.0 == round/ceiling +$1.1
		--assert +$2.0 == round/ceiling +$1.9
		--assert +$3.0 == round/ceiling +$2.5
		--assert +$3.0 == round/ceiling +$2.9
		--assert +$4.0 == round/ceiling +$3.5
		--assert error? try [round/ceiling max-money]
		--assert -$99'999'999'999'999'999 == round/ceiling min-money

	--test-- "round/half-ceiling"
		--assert -$3.0 == round/half-ceiling -$3.5
		--assert -$3.0 == round/half-ceiling -$2.9
		--assert -$2.0 == round/half-ceiling -$2.5
		--assert -$2.0 == round/half-ceiling -$1.9
		--assert -$1.0 == round/half-ceiling -$1.1
		--assert -$0.0 == round/half-ceiling -$0.5
		--assert -$0.0 == round/half-ceiling -$0.1
		--assert -$0.0 == round/half-ceiling -$0.0
		--assert +$0.0 == round/half-ceiling +$0.0
		--assert +$0.0 == round/half-ceiling +$0.1
		--assert +$1.0 == round/half-ceiling +$0.5
		--assert +$1.0 == round/half-ceiling +$1.1
		--assert +$2.0 == round/half-ceiling +$1.9
		--assert +$3.0 == round/half-ceiling +$2.5
		--assert +$3.0 == round/half-ceiling +$2.9
		--assert +$4.0 == round/half-ceiling +$3.5
		--assert error? try [round/half-ceiling max-money]
		--assert error? try [round/half-ceiling min-money]
===end-group===

===start-group=== "random"
	--test-- "random-1"
		--assert unset? random/seed RED$92.14
	--test-- "random-2"
		loop 100 [--assert $0 == random $0]
	--test-- "random-3"
		loop 100 [--assert $1 >= random $1]
	--test-- "random-4"
		loop 100 [--assert -$1 <= random -$1]
	--test-- "random-5"
		a: average collect [loop 1'000 [keep random $1'000]]
		--assert to logic! all [a - 9 <= $500 a + 9 >= $500]
	--test-- "random-6"
		loop 100 [--assert not-equal? random $1 random $1]
	--test-- "random-7"
		--assert 'RED = pick random RED$123.456 'code
===end-group===

===start-group=== "sort"
	--test-- "sort-1"
		block:  [9 2.0 $4 5.0 $8 7 $3 6.0 2.0 $1 5]
		result: [$1 2.0 2.0 $3 $4 5 5.0 6.0 7 $8 9]
		--assert result == sort block
	--test-- "sort-2"
		block:  [-1 -$8 2 3.0 -4.0 $7 2 $5 -$6 9]
		result: [-$8 -$6 -4.0 -1 2 2 3.0 $5 $7 9]
		--assert result == sort block
	--test-- "sort-3"
		block:  [USD$1 -EUR$2 $3 USD$4 -USD$5 $6 EUR$7 EUR$8 -$9]
		result: [-$9 $3 $6 -EUR$2 EUR$7 EUR$8 -USD$5 USD$1 USD$4]
		--assert result == sort block
===end-group===

===start-group=== "find"
	--test-- "find-1" --assert none == find [] $123
	--test-- "find-2" --assert none == find [123 123.0 12300%] $123
	--test-- "find-3" --assert none == find [$0.00001] 0.00001
	--test-- "find-4" --assert none == find [$1] 1
	--test-- "find-5" --assert 3 = index? find [a b $1 c d] $1
	--test-- "find-6" --assert last? find [a b c d $0.00001] $0.00001
	--test-- "find-7" --assert head? find [USD$1 EUR$1] USD$1
	--test-- "find-8" --assert head? find [USD$1 EUR$1] $1
	--test-- "find-9" --assert none == find [$1 $2] EUR$2
===end-group===

===start-group=== "money?"
	--test-- "money?-1" --assert money? $123.45678
	--test-- "money?-2" --assert not money? 123.45678
	--test-- "money?-3" --assert money? -USD$123.45678
	--test-- "money?-4" --assert not money? -123
===end-group===

===start-group=== "transcode money"
	--test-- "transcode-money-1" --assert money? load "$123"
	--test-- "transcode-money-2" --assert money? first load "$123 $456"
	--test-- "transcode-money-3" --assert money? last load "$123 -USD$456"
	--test-- "transcode-money-4" --assert money! == transcode/scan "+EUR$123.456 1 2 3"
	--test-- "transcode-money-5" --assert "AED$123.45678" == mold/all AED$123.45678
	--test-- "transcode-money-6" --assert "-ZMW$123.45678" == mold/all -ZMW$123.45678
	--test-- "transcode-money-7"
		--assert "RED$0.00000" == mold/all red$0
		--assert "RED$0.00000" == mold/all RED$0
		--assert "RED$0.00000" == mold/all Red$0
		--assert "RED$0.00000" == mold/all transcode/one "red$0"
		--assert "RED$0.00000" == mold/all transcode/one "RED$0"
		--assert "RED$0.00000" == mold/all transcode/one "Red$0"
		--assert "RED$0.00000" == mold/all make money! 'red
		--assert "RED$0.00000" == mold/all make money! 'RED
		--assert "RED$0.00000" == mold/all make money! 'Red
		--assert "RED$0.00000" == mold/all make money! [red 0]
		--assert "RED$0.00000" == mold/all make money! [RED 0]
		--assert "RED$0.00000" == mold/all make money! [Red 0]
		--assert "RED$0.00000" == mold/all make money! "red$0"
		--assert "RED$0.00000" == mold/all make money! "RED$0"
		--assert "RED$0.00000" == mold/all make money! "Red$0"
	--test-- "transcode-money-8"
		--assert error! == transcode/scan "$123456789012345678"
		--assert error! == transcode/scan "$12345678901234567.123456"
		--assert error! == transcode/scan "$'1"
		--assert error! == transcode/scan "$1'"
		--assert error! == transcode/scan "$1''2"
		--assert $12345678901234567.12345 == transcode/one "$12345678901234567.12345"
		--assert $12345678901234567.12345 == transcode/one "$00000000000000000012345678901234567.12345"
		--assert $12345678901234567.12345 == transcode/one "+$12'345'678'901'234'567.12345"
		--assert -$12345678901234567.12345 == transcode/one "-$0'00'000'000012345678901234567.12345"
	--test-- "transcode-money-9"
		--assert error! == transcode/scan "-$.1"
		--assert error! == transcode/scan "+$,2"
		--assert error! == transcode/scan "$3."
		--assert error! == transcode/scan "$4,"
		--assert error! == transcode/scan "$"
		--assert error! == transcode/scan "$."
		--assert error! == transcode/scan "-$."
		--assert error! == transcode/scan "+$."
		--assert error! == transcode/scan "EUR$0."
		--assert error! == transcode/scan "EUR$,"
		--assert error! == transcode/scan "-USD$.0"
		--assert error! == transcode/scan "$.0"
		--assert error! == transcode/scan "$0."
		--assert error! == transcode/scan "$'1"
		--assert error! == transcode/scan "$1'"
		--assert error! == transcode/scan "$1''2"
		--assert error! == transcode/scan "$1'.2"
		--assert error! == transcode/scan "$1',2"
		--assert error! == transcode/scan "$1.2'3"
		--assert error! == transcode/scan "$1.'23"
		--assert error! == transcode/scan "$1.23'"
		--assert error! == transcode/scan "$1.2''3"
===end-group===

===start-group=== "as-money"
	--test-- "as-money-1" --assert "USD$123.00000" == mold/all as-money 'USD 123
	--test-- "as-money-2" --assert "-EUR$123.45678" == mold/all as-money 'EUR -123.45678
	--test-- "as-money-3" --assert "USD$0.00000" == mold/all as-money 'USD 0
===end-group===

===start-group=== "hashing"
	--test-- "hashing-1"
		hash: make hash! [-$123.45 +$123.45 -USD$123.45 +USD$123.45]
		--assert "make hash! [-$123.45000 $123.45000 -USD$123.45000 USD$123.45000]" == mold/flat hash
		--assert -USD$123.45 == first find hash -USD$123.45
		--assert $123.45 == first find hash $123.45
		--assert USD$123.45 == select hash -USD$123.45
===end-group===

===start-group=== "accessors"
	money: -USD$123.45678
	--test-- "accessors-1" --assert 'USD == pick money 1
	--test-- "accessors-2" --assert "-$123.45678" == mold/all pick money 2
	--test-- "accessors-3" --assert 'USD == pick money 'code
	--test-- "accessors-4" --assert "-$123.45678" == mold/all pick money 'amount
	--test-- "accessors-5" --assert 'USD == money/1
	--test-- "accessors-6" --assert "-$123.45678" == mold/all money/2
	--test-- "accessors-7" --assert 'USD == money/code
	--test-- "accessors-8" --assert "-$123.45678" == mold/all money/amount
	--test-- "accessors-9"
		money: -$123.45678
		--assert none == pick money 'code
		--assert none == pick money 1
		--assert none == money/code
		--assert none == money/1
	--test-- "accessors-10"
		--assert error? try [pick money 0]
		--assert error? try [pick money -1]
		--assert error? try [pick money 5]
		--assert error? try [pick money 1.0]
		--assert error? try [pick money #"^C"]
		--assert error? try [pick money 'foo]
		--assert error? try [money/foo]
		--assert error? try [money/0]
		--assert error? try [money/-1]
		--assert error? try [money/5]
===end-group===

===start-group=== "currency list"
	cur: system/locale/currencies
	--test-- "custom-1"
		--assert error? try [clear cur/list]
		--assert error? try [reverse cur/list]
		--assert error? try [random cur/list]
		--assert error? try [cur/list: none]
		--assert error? try [cur/list/1: none]
		--assert error? try [put cur/list 'usd 'eur]
	--test-- "custom-2"
		--assert error? try [append cur/list none]
		--assert error? try [append cur/list quote :foo]
		--assert error? try [append cur/list 'foo!]
		--assert error? try [append cur/list 'usd]
		--assert error? try [cur/list: none]
		--assert error? try [cur/list/1: none]
	--test-- "custom-3"
		--assert error? try [make money! 'bar]
		append cur/list 'bar
		--assert money? make money! 'bar
		--assert "BAR$0.00000" == mold/all make money! 'bar
		--assert error? try [make money! 'qux]
		append cur/list 'QUX
		--assert "-QUX$123.45678" == mold/all make money! [QUX -123 45678]
	--test-- "custom-4"
		--assert error? try [append cur/list 'bar]
		--assert error? try [append cur/list 'qux]
		--assert error? try [clear cur/list]
		--assert error? try [reverse cur/list]
		--assert error? try [random cur/list]
		--assert (pick tail cur/list -2) = 'bar
		--assert (pick tail cur/list -1) = 'qux
===end-group===

===start-group=== "generated"
	--test-- "generated-1-+" --assert -$46256738.73641 + -$382909867.62517 == -$429166606.36158
	--test-- "generated-2-+" --assert -$861608569.91149 + -$385303837.42661 == -$1246912407.33810
	--test-- "generated-3-+" --assert $406101726.18464 + $451878314.11690 == $857980040.30154
	--test-- "generated-4-+" --assert -$924194595.27552 + 818047457.75555 == -$106147137.51997
	--test-- "generated-5-+" --assert $343313757.49004 + -500051462.32435 == -$156737704.83431
	
	--test-- "generated-1--" --assert $697707660.35546 - -$784908132.06177 == $1482615792.41723
	--test-- "generated-2--" --assert $0.00000 - $478883852.93952 == -$478883852.93952
	--test-- "generated-3--" --assert -$906981959.43001 - $707098374.93816 == -$1614080334.36817
	--test-- "generated-4--" --assert $578714290.90327 - $357084565.49657 == $221629725.40670
	--test-- "generated-5--" --assert -$681046219.85975 - $912477347.02772 == -$1593523566.88747
	
	--test-- "generated-1-*" --assert $362973781.93725 * 47800116.26323 == $17350188977104843.34034
	--test-- "generated-2-*" --assert $156244716.21412 * -55410156.51794 == -$8657544180525506.91866
	--test-- "generated-3-*" --assert $14354088.35036 * 520106887.22138 == $7465660210806413.00832
	--test-- "generated-4-*" --assert $198848883.24832 * -168188266.06878 == -$33444048883248214.40293
	--test-- "generated-5-*" --assert -$77543792.35093 * -259182608.34141 == $20098002362198714.77197
	
	--test-- "generated-1-/" --assert $230432974.28192 / -$789641370.89886 == -0.29181
	--test-- "generated-2-/" --assert -$63871490.79883 / -$527109821.57248 == 0.12117
	--test-- "generated-3-/" --assert $759773312.95598 / $133309383.93869 == 5.69932
	--test-- "generated-4-/" --assert -$854685410.78952 / $195492505.65259 == -4.37195
	--test-- "generated-5-/" --assert -$751138200.40185 / -$112696153.62989 == 6.66516
	
	--test-- "generated-1-%" --assert -$957563788.14463 % $779532506.49362 == -$178031281.65101
	--test-- "generated-2-%" --assert $132314569.37841 % $76536801.67930 == $55777767.69911
	--test-- "generated-3-%" --assert $963775501.56961 % -$282119043.76843 == $117418370.26432
	--test-- "generated-4-%" --assert -$178534509.23158 % $717081736.64150 == -$178534509.23158
	--test-- "generated-5-%" --assert -$208895940.89653 % -$659465734.68830 == -$208895940.89653
	
	--test-- "generated-1-//" --assert $565109371.00513 // -$402218239.56920 == $162891131.43593
	--test-- "generated-2-//" --assert $199006393.17883 // -$54347604.07281 == $35963580.96040
	--test-- "generated-3-//" --assert -$214794486.39545 // -$706261607.68151 == $491467121.28606
	--test-- "generated-4-//" --assert -$462802999.86842 // -$786203480.22607 == $323400480.35765
	--test-- "generated-5-//" --assert -$720945595.63367 // $994421652.98126 == $273476057.34759
	
	--test-- "generated-1-=" --assert -$638863945.67734 = $99554975.09779 == false
	--test-- "generated-2-=" --assert $394800340.47495 = $386906189.09285 == false
	--test-- "generated-3-=" --assert $27392364.58548 = -$817914108.19529 == false
	--test-- "generated-4-=" --assert $857418370.83240 = $849162471.41042 == false
	--test-- "generated-5-=" --assert -$123616631.20035 = -$825913311.36687 == false
	
	--test-- "generated-1->" --assert $782775981.25057 > -$439229823.38779 == true
	--test-- "generated-2->" --assert -$771057614.48435 > $365815091.11719 == false
	--test-- "generated-3->" --assert -$147504274.80205 > -$878620700.38849 == true
	--test-- "generated-4->" --assert -$813063470.09402 > $920014728.28909 == false
	--test-- "generated-5->" --assert -$876986659.07465 > -134834604.40059 == false
	
	--test-- "generated-1-<" --assert -$544867101.84479 < -$46940005.40624 == true
	--test-- "generated-2-<" --assert $479498603.13883 < $562156187.63218 == true
	--test-- "generated-3-<" --assert $411283579.38084 < $365425110.49910 == false
	--test-- "generated-4-<" --assert -$756771806.51424 < -$554513646.08225 == true
	--test-- "generated-5-<" --assert $0.00000 < 222266816.63760 == true
	
	--test-- "generated-1->=" --assert -$880521171.67064 >= -$964203733.93417 == true
	--test-- "generated-2->=" --assert $645425207.28214 >= -$474653873.81363 == true
	--test-- "generated-3->=" --assert $205025497.91942 >= $724002546.03660 == false
	--test-- "generated-4->=" --assert $582886748.75296 >= 920936930.42216 == false
	--test-- "generated-5->=" --assert -$885142156.80077 >= 828554261.86161 == false
	
	--test-- "generated-1-<=" --assert $116818469.07214 <= -$928374897.65526 == false
	--test-- "generated-2-<=" --assert $431016918.93814 <= $581463247.34271 == true
	--test-- "generated-3-<=" --assert $220037805.01896 <= -$686523818.26495 == false
	--test-- "generated-4-<=" --assert $35305992.25093 <= -$609764191.14030 == false
	--test-- "generated-5-<=" --assert $761650628.29928 <= -$188013192.81943 == false
===end-group===

system/options/money-digits: 2						;-- put it back where it was

~~~end-file~~~

[
	red/boot
	red/get-build-date
	red/copy-cell
	;red/get-root
	red/get-root-node2
	red/type-check-alt
	red/type-check
	red/eval-path*
	red/select-key*
	red/alloc-bytes
	red/alloc-cells
	red/get-cmdline-args
	red/set-opt-refinement*
	red/call-with-array*
	red/get-libRedRT-bitarray

	red/redbin/boot-load

	red/platform/prin*
	red/platform/prin-int*
	red/platform/prin-hex*
	red/platform/prin-2hex*
	red/platform/prin-float*
	red/platform/prin-float32*

	red/stack/mark
	red/stack/mark-native
	red/stack/mark-func
	red/stack/mark-loop
	red/stack/mark-try
	red/stack/mark-try-all
	red/stack/mark-catch
	red/stack/mark-func-body
	red/stack/unwind
	red/stack/unwind-last
	red/stack/reset
	red/stack/keep
	red/stack/push
	red/stack/unroll
	red/stack/unroll-loop
	red/stack/revert
	red/stack/adjust-post-try
	red/stack/pop
	red/stack/set-last

	red/interpreter/eval-path
	red/lexer/scan
	red/lexer/scan-alt

	red/none/push-last

	red/logic/false?
	red/logic/true?

	;*/push-local
	red/refinement/push-local
	red/lit-word/push-local

	red/binary/push
	red/block/push
	red/char/push
	red/datatype/push
	red/date/push
	;red/event/push
	red/email/push
	red/file/push
	red/float/push
	red/_function/push
	red/get-path/push
	red/get-word/push
	red/integer/push
	red/issue/push
	red/lit-path/push
	red/lit-word/push
	red/logic/push
	red/map/push
	red/money/push
	red/none/push
	red/object/push
	red/pair/push
	red/paren/push
	red/path/push
	red/percent/push
	red/point2D/push
	red/point3D/push
	red/ref/push
	red/refinement/push
	red/routine/push
	red/set-path/push
	red/set-word/push
	red/string/push
	red/tag/push
	red/time/push
	red/tuple/push
	red/typeset/push
	red/unset/push
	red/url/push
	red/vector/push
	red/word/push

	red/block/push-only*
	red/block/insert-thru
	red/block/append-thru

	red/percent/push64
	red/float/push64

	red/word/get
	red/word/get-local
	red/word/get-any
	red/word/get-in
	red/word/set-in
	red/word/set-in-ctx
	red/word/set
	red/word/replace
	red/word/from
	red/word/load
	red/word/push-local
	red/word/duplicate

	red/get-word/get
	red/get-word/push-local
	red/set-word/push-local

	red/_context/get
	red/_context/clone-words
	red/_context/set-integer

	red/object/clone-series
	red/object/transfer
	red/object/init-push
	red/object/init-events
	red/object/loc-fire-on-set*
	red/object/loc-ctx-fire-on-set*
	red/object/fire-on-set*
	red/object/get-values

	red/integer/get-any*
	red/integer/get*
	red/integer/get
	red/integer/make-at
	red/integer/form-signed
	red/logic/get
	red/float/get

	red/integer/box
	red/logic/box
	red/float/box
	
	red/vector/rs-head
	red/vector/rs-tail
	red/vector/rs-tail?
	red/vector/rs-length?
	red/vector/rs-skip
	red/vector/rs-next
	red/vector/rs-clear
	red/vector/rs-append
	red/vector/rs-append-int
	red/vector/rs-overwrite
	red/vector/rs-insert
	red/vector/get-value
	red/vector/get-value-int
	red/vector/get-value-float
	red/vector/set-value
	
	red/binary/rs-head
	red/binary/rs-tail
	red/binary/rs-length?
	
	red/handle/box

	red/_function/init-locals

	;-- console.red dependencies
	red/block/rs-head
	red/block/rs-next
	red/block/rs-tail?
	red/block/rs-length?
	red/block/rs-abs-at
	red/block/rs-append
	red/string/rs-head
	red/string/rs-tail?
	red/string/equal?
	red/string/rs-make-at
	red/string/get-char
	red/string/rs-reset
	red/string/concatenate
	red/string/rs-length?
	red/string/concatenate-literal
	red/string/append-char
	red/string/insert-char
	red/string/rs-abs-length?
	red/string/remove-char
	red/string/poke-char
	red/string/remove-part
	red/_series/copy
	;--
	
	red/symbol/make

	red/unicode/load-utf8
	red/unicode/decode-utf8-char

	red/object/unchanged?
	red/object/unchanged2?

	red/natives/remove-each-init
	red/natives/remove-each-next
	red/natives/foreach-next-block
	red/natives/foreach-next
	red/natives/forall-next?
	red/natives/forall-end
	red/natives/forall-end-adjust
	red/natives/coerce-counter*
	red/natives/inc-counter

	red/actions/make*
	red/actions/random*
	red/actions/reflect*
	red/actions/to*
	red/actions/form*
	red/actions/mold*
	red/actions/eval-path*
	red/actions/compare
	red/actions/absolute*
	red/actions/add*
	red/actions/divide*
	red/actions/multiply*
	red/actions/negate*
	red/actions/power*
	red/actions/remainder*
	red/actions/round*
	red/actions/subtract*
	red/actions/even?*
	red/actions/odd?*
	red/actions/and~*
	red/actions/complement*
	red/actions/or~*
	red/actions/xor~*
	red/actions/append*
	red/actions/at*
	red/actions/back*
	red/actions/change*
	red/actions/clear*
	red/actions/copy*
	red/actions/find*
	red/actions/head*
	red/actions/head?*
	red/actions/index?*
	red/actions/insert*
	red/actions/move*
	red/actions/length?*
	red/actions/next*
	red/actions/pick*
	red/actions/poke*
	red/actions/put*
	red/actions/remove*
	red/actions/reverse*
	red/actions/select*
	red/actions/sort*
	red/actions/skip*
	red/actions/swap*
	red/actions/tail*
	red/actions/tail?*
	red/actions/take*
	red/actions/trim*

	red/actions/create*
	red/actions/close*
	red/actions/delete*
	red/actions/modify*
	red/actions/open*
	;red/actions/open?*
	red/actions/query*
	red/actions/read*
	red/actions/rename*
	red/actions/update*
	red/actions/write*
	
	red/natives/if*
	red/natives/unless*
	red/natives/either*
	red/natives/any*
	red/natives/all*
	red/natives/while*
	red/natives/until*
	red/natives/loop*
	red/natives/repeat*
	red/natives/forever*
	red/natives/foreach*
	red/natives/forall*
	red/natives/func*
	red/natives/function*
	red/natives/does*
	red/natives/has*
	red/natives/switch*
	red/natives/case*
	red/natives/do*
	red/natives/get*
	red/natives/set*
	red/natives/print*
	red/natives/prin*
	red/natives/equal?*
	red/natives/not-equal?*
	red/natives/strict-equal?*
	red/natives/lesser?*
	red/natives/greater?*
	red/natives/lesser-or-equal?*
	red/natives/greater-or-equal?*
	red/natives/same?*
	red/natives/not*
	red/natives/type?*
	red/natives/reduce*
	red/natives/compose*
	red/natives/stats*
	red/natives/bind*
	red/natives/in*
	red/natives/parse*
	red/natives/union*
	red/natives/intersect*
	red/natives/unique*
	red/natives/difference*
	red/natives/exclude*
	red/natives/complement?*
	red/natives/dehex*
	red/natives/enhex*
	red/natives/negative?*
	red/natives/positive?*
	red/natives/max*
	red/natives/min*
	red/natives/shift*
	red/natives/to-hex*
	red/natives/sine*
	red/natives/cosine*
	red/natives/tangent*
	red/natives/arcsine*
	red/natives/arccosine*
	red/natives/arctangent*
	red/natives/arctangent2*
	red/natives/NaN?*
	red/natives/log-2*
	red/natives/log-10*
	red/natives/log-e*
	red/natives/exp*
	red/natives/square-root*
	red/natives/construct*
	red/natives/value?*
	red/natives/try*
	red/natives/uppercase*
	red/natives/lowercase*
	red/natives/as-pair*
	red/natives/break*
	red/natives/continue*
	red/natives/exit*
	red/natives/return*
	red/natives/throw*
	red/natives/catch*
	red/natives/extend*
	red/natives/debase*
	red/natives/to-local-file*
	red/natives/wait*
	red/natives/checksum*
	red/natives/unset*
	red/natives/new-line*
	red/natives/new-line?*
	red/natives/enbase*
	red/natives/handle-thrown-error
	red/natives/now*
	red/natives/get-env*
	red/natives/set-env*
	red/natives/list-env*
	red/natives/sign?*
	red/natives/as*
	red/natives/call*
	red/natives/zero?*
	red/natives/size?*
	red/natives/browse*
	red/natives/context?*
	red/natives/compress*
	red/natives/decompress*
	red/natives/recycle*
	red/natives/transcode*
	red/natives/as-money*
	red/natives/apply*
	red/natives/spawn*
	red/natives/as-point2D*
	red/natives/as-point3D*

	;-- for view backend
	red/symbol/resolve
	red/object/get-word
	red/fire
	red/datatype/register
	red/block/rs-tail
	red/stack/push*
	red/word/push*
	red/block/rs-clear
	red/object/rs-find
	red/block/make-at
	red/handle/make-in
	red/unicode/to-utf8
	red/string/to-hex
	red/integer/make-in
	red/logic/make-in
	red/string/make-at
	red/unicode/load-utf8-buffer
	red/ownership/bind
	red/string/load
	red/set-type
	red/unicode/load-utf8-stream
	red/word/make-at
	red/word/push-in
	red/block/select-word
	red/block/find
	red/_series/remove
	red/image/init-image
	red/OS-image/lock-bitmap
	red/OS-image/get-data
	red/OS-image/unlock-bitmap
	red/ownership/check
	red/report
	red/_context/set
	red/string/load-at
][
	red/root				red-block!
	red/stk-bottom			int-ptr!
	red/stack/arguments		cell!
	red/stack/top			cell!
	red/stack/bottom		cell!
	red/unset-value			cell!
	red/none-value			cell!
	red/true-value			cell!
	red/false-value			cell!
	red/boot?				logic!
	red/collector/active?	logic!
	red/natives/buffer-blk	red-block!
]
Red/System [
    Title:   "Red/System test of struct containing bytes! values"
    Author:  "Oldes"
    File:    %bytes-struct.reds
    Rights:  "Copyright (C) 2017 David 'Oldes' Oliva. All rights reserved."
    License: "BSD-3 - https:;//github.com/red/red/blob/master/BSD-3-License.txt"
]

s!: alias struct! [
    a [integer!]
    b [bytes! 2]
    c [bytes! 2]
    d [bytes! 10]
    e [integer!] ;note that this value will be aligned
]
s: declare s!
p: as int-ptr! s

s/a: 42
s/e: 24

print-line ["Test struct size: " size? s]
if 24 <> size? s [
    print-line "Invalid test struct size! Should be 16."
]
print-line ["Value pointers:"]
print-line ["^-s/a: " :s/a " offset: " as integer! (:s/a - p) " value: " s/a]
print-line ["^-s/b: " :s/b " offset: " as integer! (:s/b - p) " value: " s/b]
print-line ["^-s/c: " :s/c " offset: " as integer! (:s/c - p) " value: " s/c]
print-line ["^-s/d: " :s/d " offset: " as integer! (:s/d - p) " value: " s/d]
print-line ["^-s/e: " :s/e " offset: " as integer! (:s/e - p) " value: " s/e #" " (s/e = 24)]

print-line size? s/a
print-line size? s/b

print-line ["s/b + 1 = " s/b + 1]

s/b/1: #"X"
print-line "^/Accessing bytes:"
print-line ["s/b/1 = " s/b/1]

pp: p + 1
pp/value: 64636261h ;this sets values in s/b and s/c bytes at once
print-line ["s/c/1 = " s/c/1]
print-line ["s/c/2 = " s/c/2]

print-line [as c-string! pp " <- should be: abcd"]

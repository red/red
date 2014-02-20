Red [
   Title: "Help function for Red"
   Author: "Ingo Hohmann"
]

help: function [
   "Get help for functions"
   'func-name "Word you are looking for" 
][
   argument-rule: [
      [set word word! (pre: "") | set word lit-word! (pre: "'") | set word get-word! (pre: ":")]
      opt [ set annotation block! (prin [ " " mold annotation])]
      opt [ set info string! (prin [ " =>" info])]
      (print [ ])
   ]
   either all [ word? func-name any [ action? get func-name function? get func-name native? get func-name]][
;      print ["^/" func-name "is of type" type? get :func-name newline]
 
      prin ["^/USAGE:^/" func-name ]
      parse spec-of get func-name [ any [ /local to end | set w word! (prin[" " w]) | set w [ lit-word! | refinement! ] (prin [" " mold w]) | skip ]] 
      parse spec-of get func-name [
	 opt [set annotation block! (prin ["^/^/ANNOTATIONS:^/" mold annotation])]
	 opt [set info string! (print ["^/^/DESCRIPTION:^/" info])]
	 (print "^/ARGUMENTS:")
	 any [
	    argument-rule
	    (print "")
	 ]
	 (print "^/REFINEMENTS:")
	 any [
	    [/local [ to set-word! | to end ] ]
	    |
	    [
	       set ref refinement! (prin mold ref)
	       opt [ set info string! (prin [ " =>" info])]
	       (print "")
	       any [argument-rule (print "")]
	    ]
	 ]
	 opt [
	    set-word! set block block! 
	    (print ["^/RETURN:^/" mold block])
	 ]
      ]
   ][
      print [func-name "is of type" either word? func-name [type? get func-name][type? func-name] "."]
      print "No more help available."
   ]
   exit
]

what: function [
   "Lists all functions, or words of a given type"
][
   foreach w system/words [
      if any [ function? get w native? get w action? get w][ 
	 print w
      ]
   ]
]

source: function [
   "print the source of a function"
   func-name [lit-word!] "The name of the function as lit-word!"
][
   either function? get func-name [
      print mold body-of :func-name
   ][
      print ["Sorry," func-name "is a" type? :func-name "so no source is available"]
   ]
]

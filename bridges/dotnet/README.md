Red/.NET Bridge
------------------------

This is a prototype of a higher-level Red to .NET bridge. 

* Red  -> .NET  (Implemented)
* .Net -> Red   (Not Implemented)

Red/.NET bridge current API
----------------------------

* clr-start: start the default CLR runtime.
* clr-stop:  close the default CRL runtime.
* clr-load:  load assembly into CLR.
* clr-new:   instantiate a CLR class, returns a CLR object.
* clr-do:    invoke an object's method with arguments.

## clr-load

	clr-load file! : load an external assembly.
	clr-load path! : load an assembly from .NET framework.

## clr-new

	clr-new [word! arg1 arg2 ...]

	word!: fullname of the class (including namespace)

	e.g.
		btn: clr-new [System.Windows.Controls.Button]

## clr-do

	clr-do [path! arg1 arg2 ...]     : call instance method
	clr-do [lit-path! arg1 arg2 ...] : call static method
	clr-do [set-path! arg]           : set a property
	clr-do [get-path!]               : get a property

	e.g.
	    clr-do ['System/Console/WriteLine "Hello!"]   ;-- static method
	    clr-do [win/Show]                             ;-- instance method
	    clr-do [btn/Width: 100]                       ;-- set a property
	    probe clr-do [:btn/Width]                     ;-- get a property
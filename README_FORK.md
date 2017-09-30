# Implementation of a dynamic prototype-based programming in Red

Red implement a prototype-based programming (*value-share*), i.e., the clones will be created from a prototype, but after creation they stand on their own feet (*creation-time sharing*). 

See the [paper][1] of this link.

[1]: [http://www.idt.mdh.se/kurser/cd5130/msl/2003lp4/reports/prototypebased.pf]

This addon of Red tries to implement a dynamic prototype-based programming (*property-share*), transparent to users and usual rules of Red.

This implementation following the concepts of the Self implementation of the object oriented programming language. Then, it uses *objects* and *slots* concept, i.e., it does not distinct variables from methods to be more flexible. Thus it also follow the philosophy of Red.

However, to explain the implementation, the difference between variables (properties) and methods (functions) is necessary.

## Properties (variables)

### Delegation (1): to share the value of a property

The delegation is clean and follow the rules of Red. The only difference is the slot `_proto` (or any other name decided by the main contributors of Red as `_is`) to clone an object when we declare as prototype-based object from any other `object!` (with or whithout prototype). 

	a: make object! [x: 1 y: 2 z: 3]	  ; any object can be a prototype
	
	; clone (child) creation
	b: make object! [_proto: a x: 10]  
	
	b/x ; => 10
	b/y ; => 2
	
	a/y: 20
	b/y ; => 20

It is not necessary the slot `_proto` to clone a _siblind_ prototype following the rules of Red, but copy all other variables of the siblind object, if this conduct is not desirable then the user can use the usual creation of a prototype-based object.

	a: make object! [x: 1 y: 2 z: 3]	  ; any object could be a prototype
	b: make object! [_proto: a x: 10]  
	
	; clone (siblind) creation
	c: make b [z: 30]  
	
	c/x ; => 10  ; copy of b
	c/y ; => 2   ; from a
	b/x: 20
	c/x ; => 10
	
	; or
	c: make object! [_proto: a x: 300] ; override x from b
	
	c/x ; => 300  ; from c
	c/y ; => 2    ; from a
	
#### CPU cost	

The cpu cost of this implementation to other users of `object!` is zero. However, a bad programming conduct could lead to crash the system


	b: make object! [_proto: 5 x: 10]
	
	b/x ; => 10
	b/y
	*** Runtime Error 1: access violation
	*** at: 000370EAh

To avoid it, is necessary check `_proto` as a valid `object!`. There are two possibilities:

1. _Zero cost for object users and high cost for prototype users._
	It is possible checking the validity of `_proto` in the delegation process, but the pay for the prototype users is in all delegations (variable access) of a prototype-based object.
	
2. _Cost sharing for all users._
	The checking of validity of `_proto` is placed in the creation of `object!`. 
	
	I implement this option because the cost for all users is low only when `make` the object. After that, no aditional cost for any users at this moment.

### Delegation (2): new value of a property

Logically, any object can change the values of their properties but the question is if an object can modify the value of a prototype property or if can add new properties. This feature could be resolve with three mechanisms, from low to high cpu cost:

1. _Objects can modify the slot values of the prototypes but no add new properties._

	It is the more easy to implement without any aditional cost to the users. However, I think, this is a very risky option.  

2. _Objects can not add or modify properties of theirs prototypes._

	This could be the default mechanism when the objects are static after creation. An object only can modify their properties. This idea is nowdays in the background of Red because a `extend` function is not posible to add properties to the objects.	

3. _Objects can override properties of the prototypes, creating property if it is necessary._
	An object can add properties presents in their prototypes but can no add new properties (when `extend` will be implemented in Red, they will can althought the implementation is easy!).
	
I implement this last option because is safe, flexible and the cpu cost is the same as the previous option.

	a: make object! [x: 1 y: 2 z: 3]
	b: make object! [_proto: a x: 10]  
	
	b/y: 20  ; b now is object! [_proto: a x: 10 y: 20]

	b/w: 30
	*** Script Error: cannot access w in path b/w:
	*** Where: set-path
	*** Stack:
	

### Remove properties

In this moment Red does not implement a function to remove slots of an object. Then, it is not implemented but when it will be implemented to `object!`, it could be used in prototype-based programming with any change.

> The mechanism of *property-share* uses about 20 lines of code and with very low cpu cost to the object users without prototype-based programming.

## Methods (functions)

**To be implemented**

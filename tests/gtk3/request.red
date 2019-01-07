Red []
a: request-file
print a

wait 3
a: none
view [
	button "toto" [a: request-file print a]
	button "toti" [a: request-dir print a]
]

print a
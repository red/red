Red [
	Title: "Simple HTTP client"
	Notes: {
		The compiler is not able to compile it.
	}
]

client: open tls://172.217.163.238:443
client/awake: func [event /local port] [
    port: event/port
    switch event/type [
        connect [
	        probe "connect"
	        insert port "GET / HTTP/1.1^M^/Hostname:rblk.eu^M^/Connection:close^M^/^M^/"
        ]
        read [
	        probe to-string port/data
	        ;@@ TBD use Content-Length in the response header
	        copy port			;-- until peer close it
	        ;@@ close port
        ]
        wrote [probe "wrote" copy port]
        close [probe "closed"]
    ]
]

if unset? :gui-console-ctx [
	wait client
	print "1st Done"
	repeat n 2 [
		?? n
        wait 0.1
		open client
		wait client
	]
]

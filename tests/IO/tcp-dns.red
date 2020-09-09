Red [
	Title: "TCP with DNS built-in"
	Notes: {
		The compiler is not able to compile it.
	}
]

client: open tcp://www.baidu.com:80

client/awake: func [event /local port] [
    print ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [insert port "GET / HTTP/1.1^M^/Hostname:www.baidu.com^M^/Connection:close^M^/^M^/"]
        read [
			probe to-string port/data
		    copy port
        ]
        wrote [copy port]
        close [close port]
    ]
]

wait client
Red [
	Title: "Simple HTTP server"
	Notes: {
		The compiler is not able to compile it.
	}
]

httpd: context [

	debug: :print
	;debug: :comment
	
	server: open tcp://:8081

	http-ok: func [port [port!] ctype [string!]][
		insert port rejoin [
			"HTTP/1.0 200 OK^M^/Content-Type: " ctype
			"^M^/^M^/"
		]
	]

	parse-header: func [data /local method uri][
		parse data [
			copy method to space skip
			copy uri to space
		]
		to-string method
	]

	process-request-get: function [port][
		http-ok port "text/html"
		data: make string! 5000
		files: read what-dir
		foreach file files [
			repend data [
				{<a href="/} file {">} file "</a><br />"
			]
		]
		insert port data
	]

	process-request: function [port] [
		debug ["port data:" to-string port/data]

		method: parse-header port/data
		switch/default method [
			"GET"  [process-request-get port]
			"POST" []
		][debug ["Httpd: cannot handle method: " method]]
		close port
	]

	client-handler: function [event] [
	    debug ["=== client event:" event/type]
	    client: event/port
	    switch event/type [
	        read  [process-request client]
	        close [close client]
	    ]
	]

	server/awake: function [event] [
	    if event/type = 'accept [
			debug ["=== New client ==="]
			client: event/port
		    client/awake: :client-handler
		    copy client							;-- read from the client
	    ]
	]

	start: does [
		;browse http://127.0.0.1:8081
		wait server
	]
]

httpd/start
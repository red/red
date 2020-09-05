Red [
	Title: "Simple GUI HTTP client"
	Needs: View
	Notes: {
		The compiler is not able to compile it.
	}
]

open-url: func [face event /local client port][
	client: open rejoin [tcp:// widget-url/text]
	client/awake: func [event /local port] [
	    port: event/port
	    switch event/type [
	        connect [
		        insert port "GET / HTTP/1.1^M^/Hostname:www.baidu.com^M^/Connection:close^M^/^M^/"
	        ]
	        read [
		        append widget-area/text to-string port/data
		        ;@@ TBD use Content-Length in the response header
		        copy port
		        ;@@ close port
	        ]
	        wrote [copy port]
	    ]
	]
]

view [
	text middle 30 "IP: " widget-url: field 330 "183.232.231.174:80"
	button "Open" :open-url return
	widget-area: area "" 440x400
]
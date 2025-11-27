Red [
	Title: "Simple HTTPS server"
	Notes: {
		The compiler is not able to compile it.
	}
]

httpd: context [

	debug: :print
	;debug: :comment

	cert: {
	-----BEGIN CERTIFICATE-----
	MIICqTCCAk6gAwIBAgIIAlPHPJeDDOcwCgYIKoZIzj0EAwIwgYQxCzAJBgNVBAYT
	AkNOMRUwEwYDVQQKEwxiaXRiZWdpbi5jb20xHTAbBgNVBAsTFGJpdGJlZ2luIHRl
	c3QgY2EgZWNjMRwwGgYDVQQDExNlY2MuY2EuYml0YmVnaW4uY29tMSEwHwYJKoZI
	hvcNAQkBDBJiaXRiZWdpbkBnbWFpbC5jb20wHhcNMjAwNzI5MTAxODI1WhcNMjEw
	NzI5MTAxODI1WjCBgzELMAkGA1UEBhMCQ04xFTATBgNVBAoTDGJpdGJlZ2luLmNv
	bTEaMBgGA1UECxMRYml0YmVnaW4gdGVzdCBlY2MxHjAcBgNVBAMTFWVjYy50ZXN0
	LmJpdGJlZ2luLmNvbTEhMB8GCSqGSIb3DQEJAQwSYml0YmVnaW5AZ21haWwuY29t
	MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEdpVlebb9Ytkyh+S7jt9PU/3Wgoce
	n8ow6uGdkTXndztsdVRsa3xWoXZZNPoHyZTEX+OsRo8EKY59XsIadNpNmaOBqDCB
	pTAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMC
	MB0GA1UdDgQWBBRwmvJWNz8OWyQFgksfTdZE7jXEYjAfBgNVHSMEGDAWgBRDtn96
	EtUZvjCPdDe7aKuFM4YPJDA0BgNVHREELTArghVlY2MudGVzdC5iaXRiZWdpbi5j
	b22BEmJpdGJlZ2luQGdtYWlsLmNvbTAKBggqhkjOPQQDAgNJADBGAiEApk0PGmEn
	M52Jj9AM4ADUdYIoITAgTb5ufXdMnTKK56wCIQD1fvB03WdEj5jtNTJ1dtNP36s/
	fyxJfdmh3D4m87j0lA==
	-----END CERTIFICATE-----
	}

	chain: {
	-----BEGIN CERTIFICATE-----
	MIICvDCCAmKgAwIBAgIIXTWd8+wMzG8wCgYIKoZIzj0EAwIwgYgxCzAJBgNVBAYT
	AkNOMRUwEwYDVQQKEwxiaXRiZWdpbi5jb20xHzAdBgNVBAsTFmJpdGJlZ2luIHRl
	c3QgZWNjIHJvb3QxHjAcBgNVBAMTFWVjYy5yb290LmJpdGJlZ2luLmNvbTEhMB8G
	CSqGSIb3DQEJAQwSYml0YmVnaW5AZ21haWwuY29tMB4XDTIwMDcyOTEwMTYwMVoX
	DTIxMDcyOTEwMTYwMVowgYQxCzAJBgNVBAYTAkNOMRUwEwYDVQQKEwxiaXRiZWdp
	bi5jb20xHTAbBgNVBAsTFGJpdGJlZ2luIHRlc3QgY2EgZWNjMRwwGgYDVQQDExNl
	Y2MuY2EuYml0YmVnaW4uY29tMSEwHwYJKoZIhvcNAQkBDBJiaXRiZWdpbkBnbWFp
	bC5jb20wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASW1UJm0UuBTkr3ZPd3W0CC
	LrDS7WU7UAvDxVvK9RC2buvU7sXnM57HBJVOZeC+QTbbufgGmUnI7RwNb7lrktSs
	o4G3MIG0MA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYB
	BQUHAwIwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUQ7Z/ehLVGb4wj3Q3u2ir
	hTOGDyQwHwYDVR0jBBgwFoAUUtg1u5Mb9YcgyF8UwVWkXK17lLwwMgYDVR0RBCsw
	KYITZWNjLmNhLmJpdGJlZ2luLmNvbYESYml0YmVnaW5AZ21haWwuY29tMAoGCCqG
	SM49BAMCA0gAMEUCIGvs3zEAWlmGjDvzc5wCCsX/M4RoMmud+nqKVsKVnR65AiEA
	7gYFJIVIPt7a04oCb9LCvzYU6Fsp7YoJ5OgWYptO5Eo=
	-----END CERTIFICATE-----
	}

	key: {
	-----BEGIN EC PRIVATE KEY-----
	MHcCAQEEIO+S0fDqSIa59vOh+AJGtAYdmg87JujJb9cM5MjdzVQCoAoGCCqGSM49
	AwEHoUQDQgAEdpVlebb9Ytkyh+S7jt9PU/3Wgocen8ow6uGdkTXndztsdVRsa3xW
	oXZZNPoHyZTEX+OsRo8EKY59XsIadNpNmQ==
	-----END EC PRIVATE KEY-----
	}
	
	server: open tls://:8082

	server/extra: compose [
		cert: (cert)
		chain-cert: (chain)
		key: (key)
	]

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
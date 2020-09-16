Red [
    title: "Basic Secure TCP test server"
]

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

do [

debug: :print
;debug: :comment

total: 0.0
count: 0

process-data: func [port /local len] [
	;debug ["port data:" port/data]
	debug "process-data enter"
    unless empty? port/data [
        len: length? port/data
        debug ["--- packet:" length? port/data "of" len]
        probe to-string port/data
        insert port to-binary "hello Red from server"
    ]
	debug "process-data exit"
]

new-event: func [event] [
    debug ["=== Subport event:" event/type]
    switch event/type [
        read  [process-data event/port]
        wrote [copy event/port]
        close [close event/port return true]
    ]
    false
]

new-client: func [port /local data] [
	debug ["=== New client ==="]
    port/awake: :new-event
    copy port
]

server: open tls://:8123

comment {
server/extra: [
    cert: load %cert.pem
    ;chain-cert: load %chain.pem
    key: load %key.pem
    ;password: "mypass"
    protocol: [tls1.2 tls1.1]
]
}

server/extra: compose [
    cert: (cert)
    chain-cert: (chain)
    key: (key)
    ;password: "mypass"
    ;-- temporary
    min-protocol: 0302h             ;-- min protocol sslv3,
    max-protocol: 0303h             ;-- max protocol tls1.2
]

server/awake: func [event] [
    if event/type = 'accept [new-client event/port]
    false
]

print "Secure TCP server: waiting for client to connect"
if none? system/view [
	wait server
	print "done"
	close server
]

]


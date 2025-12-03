Red [
    title: "Basic Secure TCP test server"
]

cert: {
-----BEGIN CERTIFICATE-----
MIIDrzCCApegAwIBAgIIFrCtVbriQqIwDQYJKoZIhvcNAQELBQAwezELMAkGA1UE
BhMCQ04xFzAVBgNVBAoTDktleU1hbmFnZXIub3JnMTEwLwYDVQQLEyhLZXlNYW5h
Z2VyIFRlc3QgUm9vdCAtIEZvciBUZXN0IFVzZSBPbmx5MSAwHgYDVQQDExdLZXlN
YW5hZ2VyIFRlc3QgUm9vdCBDQTAeFw0yMDEwMjYwODEyNDhaFw0yMTEwMjYwODEy
NDhaMCUxCzAJBgNVBAYTAkNOMRYwFAYDVQQDEw1iaXRiZWdpbjIuY29tMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA9JjLa68LRuwjcOLEtizP+ZKkBErh
dOvsmJ1bLB8FlEnVUis1mjSE+g1jkFhmUOnNMpX7V7rAqDyO/O02RjpDEJGwb7iS
gyQcWeHFscue5g7ldBvcoAwX3xoJWqLqVYujkeCguXRKd62cEwWGpOZ1xWLAmwcg
nKP2huzORWRbfzXFPjv12L/uQQ1gO0XBl1n9wzv9luh0KH/xfvd8999jmfT36eNB
gUEL8tY1ovo2u08B35CasFJdA/gw9Ajl/81KAAzn+hsd1VgGHuOMoDT/tXE9FKcs
OOz7yrslxRa4hmoK813zOpByn5cfWX4DvugMo1MInJbpeBhSLqd29RO41QIDAQAB
o4GMMIGJMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYB
BQUHAwIwHQYDVR0OBBYEFE5m1UX2QJEopsVrskzzlQHIKmzFMB8GA1UdIwQYMBaA
FE0pWmEs883SzQ/jokpP2qcnnzg9MBgGA1UdEQQRMA+CDWJpdGJlZ2luMi5jb20w
DQYJKoZIhvcNAQELBQADggEBAFNntBX0Lmid8CyBhI7cNAiuGHRhAUH37ZpIu3Ng
07HEloGHp7sx3JdZXk7UtiAMfyHWXHcEYjQFdJKTZyQRjL7+AX+wWZr1xDRJcyOf
s71Tb9D8oXoywlsZBKb7gV42Qc5aRdQB+phDmf7KOsJ0d3/Dizod16pxztnUjkJ/
zF2em55GV7U1khkZXfHwZn0ZhaGwnnDEIGTvH1MyVbD8bPDlb1Dt4IWEEL48XTUW
CV9xihh/zr1dDy3BHQ7LCONrdDuvC1scQxqWRL8CIeC28zH0OJLvRGDMdnut2kJn
pWNrDI9rtTxkbhevuv4E60erTyC8y5SjT/FLeWiUIFvPx0c=
-----END CERTIFICATE-----
}

chain: {
-----BEGIN CERTIFICATE-----
MIIESDCCAzCgAwIBAgIIJoJioe5Xq7gwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNV
BAYTAkNOMRUwEwYDVQQKEwxiaXRiZWdpbi5jb20xHzAdBgNVBAsTFmJpdGJlZ2lu
IHRlc3QgcnNhIHJvb3QxHjAcBgNVBAMTFXJzYS5yb290LmJpdGJlZ2luLmNvbTEh
MB8GCSqGSIb3DQEJAQwSYml0YmVnaW5AZ21haWwuY29tMB4XDTIwMDczMDAzMzYy
MVoXDTIxMDczMDAzMzYyMVowgYQxCzAJBgNVBAYTAkNOMRUwEwYDVQQKEwxiaXRi
ZWdpbi5jb20xHTAbBgNVBAsTFGJpdGJlZ2luIHRlc3QgcnNhIGNhMRwwGgYDVQQD
ExNyc2EuY2EuYml0YmVnaW4uY29tMSEwHwYJKoZIhvcNAQkBDBJiaXRiZWdpbkBn
bWFpbC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC1F909bb1a
vnxSKIx+vFrDAXKB79Y+OT2XZLUCpYRRrTJpVTv/yfyRuEtYg7SsUDsdBVrebF9M
LVd6bowe7qekkSCDdhzBeDkyQVMbHZODz6GLW9cPOivWGFjPfChjroOX6L36x78P
4XvlqAka8+rWRteNre+fRnHbB443QDNI2zV0iY6pD9OioqNXZ1sAvTf9ruK8hwR2
GSMnG2SUtUvD70UQF/m9RNTok9jZVmes1rwW68nkqJBa2wCy2E9VpoX72fjnR2eU
OxLLkBpqc6EtpieWkvQQ4BGy0YoVAdLr6/pbWzOZqIg3pnGNwnQbyLSFWH+P0Lp/
PZFZSRPUcMx1AgMBAAGjgbcwgbQwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQG
CCsGAQUFBwMBBggrBgEFBQcDAjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSp
/mmonOZQiS1WB1roOvL9jSC2HzAfBgNVHSMEGDAWgBRKsjiyxs0LKPSUGChglCC/
EFb28TAyBgNVHREEKzApghNyc2EuY2EuYml0YmVnaW4uY29tgRJiaXRiZWdpbkBn
bWFpbC5jb20wDQYJKoZIhvcNAQELBQADggEBAB9JLHIWFnCsqogxZ4dRkyXEtGDF
dsefaLtUf+R1mjOQd7ns4L9oPap3f+n9drw4pokxXL3+HOC9pkzaU3bCajmOYhl2
K+OJefC6E+rCrh/9FhvRn09Jt8WUDrHZ7+hXAa9pUS6Shl6v/LSTay9GBpudidgy
FQowC5nRDmdI08yBHlSlblg7zw8PRnANcvJbZScpHNEPsJsE8mxvxiAJqWrTL+dD
zX9R1ROr5EWbnXV6Tm+FWR352isyWIcmye0FZ9PzhETJ4WaT2KowJ0bbsHS+GGTV
oCBWtJdAzVvXJqOqJ4tQj+izJODndGXI9LQ4Sfga8h94oDeb8otlAmlP+6k=
-----END CERTIFICATE-----
}

key: {
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA9JjLa68LRuwjcOLEtizP+ZKkBErhdOvsmJ1bLB8FlEnVUis1
mjSE+g1jkFhmUOnNMpX7V7rAqDyO/O02RjpDEJGwb7iSgyQcWeHFscue5g7ldBvc
oAwX3xoJWqLqVYujkeCguXRKd62cEwWGpOZ1xWLAmwcgnKP2huzORWRbfzXFPjv1
2L/uQQ1gO0XBl1n9wzv9luh0KH/xfvd8999jmfT36eNBgUEL8tY1ovo2u08B35Ca
sFJdA/gw9Ajl/81KAAzn+hsd1VgGHuOMoDT/tXE9FKcsOOz7yrslxRa4hmoK813z
OpByn5cfWX4DvugMo1MInJbpeBhSLqd29RO41QIDAQABAoIBAQDxke5mHe1PUGz4
Up7hJYUKAfAHZUUiStfTKqYe/0xtVjZe/tnjwLcMlyicKRJ0G1VT/pjL3l/kSFsY
JdeSqHwP4zOUQ4BAEOwHQVoU7Pu0T0YC1HmjgA4bhAV1BK3XayBTNLzILLhXVpls
l+qQ9iOenJeJBRMKYU1bmIloM2PCT5Rj0eQ7z5NTEs9LWC+zN5dGaLcPvq28JU78
St/7Gu5z6OKLco/tQ6ud+Sh/c7WOBhLDp6Kl6eSlTGJeKvFRp43LRVnxxMWmTw4H
fdpYKsF9Ow/2jV5J9nq+TbFqrsfPa+Hp8LnRI2Os6mZs74BYsF29jAbkYC0pQo/N
7ZjRRVvJAoGBAPSbnUQafVmnMvVgq9t4vSYSTjX4XBNNRSTp7MF/6EUw6sQ/U6wd
rHhhj/INoiRRnzVetX58v6goIxmG15YZuw5UFNfHCv8myuLkN4nntn/XX1/bAqTJ
P88zV8WW+wHtObcILez0YDm446ZLnFosX9aAoS2czrj3N1RnaOMKW80/AoGBAP/9
DIk8Y9q/JkqOQNlQsgQxvVruMKETmh8OZNZK23tocv7I6H9YAFeqGATKDKCyJW/u
OMAu30qeffof7Yfy0bIFnI1wNN2HUk6/02+hEUae85pIN08D0ygQR3IWZHpWUQwc
KFQqyE1G3as5SRF5Fv994p7bFP//+Wf2u242jbDrAoGBALClMI1eE+gKtuI9Td7Q
8sfrsE+Ja/UEeEqQJEoY9MQC74eJtAM36rWEv08uSUmxKCiCnM8bh80IL1Df8BCV
xGA0mFi7hVV9zkbMSM9uZn0sK9QtdVtLeqlHirtGrT5W8rcbUQ8t68/DlaMiN2dn
ZE6j1cH62873uR1bEIPllyZBAoGBAI42zhUb+LmZAjPfTcWtYAiWfYUb2OZT1oa0
X27xzXeE8oX7pbbBdAc/1vIqMdPAxK2nYd3a7HAvFvuzayngy4CkP3IQST5dJGvd
hCB7Efby7ZDj195M2K1kRdzq9c1FUOdyaTFBR2AvI40xWRec9xrfm9v3CHakhbGt
UDmNkzAbAoGAZpct0dl6Nnm3ut3p2vHMk5oJurA3BqcW1SubmHjJSGdn46rrKMdM
ZWqklxg06oVxZ9YHdrjcbFad/t0Q85OkSC8VsuGkegSOGkgtOhzJpS8Jl+GiqFnn
iq00+vnB3e/tBCV/0JPRJecJ/mP3JGJZrdruGfEdXCFkhmqd6a9mwhU=
-----END RSA PRIVATE KEY-----
}

protos: [
	sslv3	0300h
	tls1.0	0301h
	tls1.1	0302h
	tls1.2	0303h
	tls1.3	0304h
]

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

server/extra: compose/deep [
    certs: [(cert)]
    key: (key)
    ;password: "mypass"
    min-protocol: (protos/tls1.2)
    max-protocol: (protos/tls1.2)
]

server/awake: func [event] [
    if event/type = 'accept [new-client event/port]
    false
]

print "Secure TCP server: waiting for client to connect"
if unset? :gui-console-ctx [
	wait server
	print "done"
	close server
]

]


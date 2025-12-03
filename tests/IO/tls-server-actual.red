Red [
    title: "Basic Secure TCP test server"
]

cert: {
-----BEGIN CERTIFICATE-----
MIIFSjCCBDKgAwIBAgISAxtBt8gnLL/HI1/ZohEkiYABMA0GCSqGSIb3DQEBCwUA
MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD
ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMzAeFw0yMDEwMjYwNTM2NTBaFw0y
MTAxMjQwNTM2NTBaMBQxEjAQBgNVBAMTCXJlYm9sLnRvcDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBALCTXddsOoMuNuYQvz9xrpedSKpOZlqCJB1v/XQx
Sz89BT5mJ/2kZUHYjgqOfe9WnX4p7BfWbnwSUiUNdgSF8L+USS3vIi9uC1jps4vz
ZAbOlOuLiAEl4RXn8uxtiE6t1usqT2G1C+nXBft0vlDMLGGG/HGLZ2gbGb893ST1
gMouixteumgMSLOiv+Pfm5xHTmbFZIYtq+i0qu2pzwDC+jVlThLCUziYrshFLaQL
Vr4ymj80q4Ahj/jqyMglGTTdIygpIVg590xwWKos/ik06HiQG84hktr0Fc/q8j1e
iAUYYKX1sf/cQgHjZKtmVT/mJBoKWNfCESWvSNpvjAZEZScCAwEAAaOCAl4wggJa
MA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIw
DAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUUI0q5dsRYEZfuzr3JfexIvOCHG8wHwYD
VR0jBBgwFoAUqEpqYwR93brm0Tm3pkVl7/Oo7KEwbwYIKwYBBQUHAQEEYzBhMC4G
CCsGAQUFBzABhiJodHRwOi8vb2NzcC5pbnQteDMubGV0c2VuY3J5cHQub3JnMC8G
CCsGAQUFBzAChiNodHRwOi8vY2VydC5pbnQteDMubGV0c2VuY3J5cHQub3JnLzAU
BgNVHREEDTALgglyZWJvbC50b3AwTAYDVR0gBEUwQzAIBgZngQwBAgEwNwYLKwYB
BAGC3xMBAQEwKDAmBggrBgEFBQcCARYaaHR0cDovL2Nwcy5sZXRzZW5jcnlwdC5v
cmcwggEEBgorBgEEAdZ5AgQCBIH1BIHyAPAAdgBvU3asMfAxGdiZAKRRFf93FRwR
2QLBACkGjbIImjfZEwAAAXVjn68HAAAEAwBHMEUCIGl2P+HXXoHtIoFopGuGw0XO
vMoO121dMp6a+yKuSrKUAiEA2QG6zfLryqMFaB9NGGlItIkoKu5ZjJO1U8K6/Pmi
adgAdgB9PvL4j/+IVWgkwsDKnlKJeSvFDngJfy5ql2iZfiLw1wAAAXVjn69EAAAE
AwBHMEUCIQDp1/7R5SjtZ0X0aIHeqf7Hby+OlH5O2s9el+GfsRQsEgIgbBJ+bN/6
MyPBveduOkZOReULqscJWN9Q53AFh8yvViQwDQYJKoZIhvcNAQELBQADggEBAIOx
BstUbrPvGQ4mVyK3QFu/twvUlu9lKgBvH6oWVK4qJBGDqj8MYxk/UDit2KtdwB9b
1279S7PFe95M9LsvFFYq/Ieax7dTWSl0TZYfaA3YiOFWA/qqD/7y8u+t5oMa4/51
HHaC7pZ1Fi8ozuGEePmaLmsWXWiOyXUUtfhvLrTebw8QMR3AKhn5oeF2KHi5xGXx
N0Gk2SI3mJUDYnR8kqHbe3NrIcCHmnWz5GoPxYnA/7Tk21l23cu5na8Rs+EWTGUu
QfH2ZJA06cJd6fy8115dhz6zMp6xpjM6ljd8tNZ5ld6MaDkwDHPCR9HeUqh11R8y
ZWRjKJSEWMaFKHFQYxA=
-----END CERTIFICATE-----
}

;-- To prevent that some systems not install this chain certiface
chain: {
-----BEGIN CERTIFICATE-----
MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTE2MDMxNzE2NDA0NloXDTIxMDMxNzE2NDA0Nlow
SjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUxldCdzIEVuY3J5cHQxIzAhBgNVBAMT
GkxldCdzIEVuY3J5cHQgQXV0aG9yaXR5IFgzMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEAnNMM8FrlLke3cl03g7NoYzDq1zUmGSXhvb418XCSL7e4S0EF
q6meNQhY7LEqxGiHC6PjdeTm86dicbp5gWAf15Gan/PQeGdxyGkOlZHP/uaZ6WA8
SMx+yk13EiSdRxta67nsHjcAHJyse6cF6s5K671B5TaYucv9bTyWaN8jKkKQDIZ0
Z8h/pZq4UmEUEz9l6YKHy9v6Dlb2honzhT+Xhq+w3Brvaw2VFn3EK6BlspkENnWA
a6xK8xuQSXgvopZPKiAlKQTGdMDQMc2PMTiVFrqoM7hD8bEfwzB/onkxEz0tNvjj
/PIzark5McWvxI0NHWQWM6r6hCm21AvA2H3DkwIDAQABo4IBfTCCAXkwEgYDVR0T
AQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwfwYIKwYBBQUHAQEEczBxMDIG
CCsGAQUFBzABhiZodHRwOi8vaXNyZy50cnVzdGlkLm9jc3AuaWRlbnRydXN0LmNv
bTA7BggrBgEFBQcwAoYvaHR0cDovL2FwcHMuaWRlbnRydXN0LmNvbS9yb290cy9k
c3Ryb290Y2F4My5wN2MwHwYDVR0jBBgwFoAUxKexpHsscfrb4UuQdf/EFWCFiRAw
VAYDVR0gBE0wSzAIBgZngQwBAgEwPwYLKwYBBAGC3xMBAQEwMDAuBggrBgEFBQcC
ARYiaHR0cDovL2Nwcy5yb290LXgxLmxldHNlbmNyeXB0Lm9yZzA8BgNVHR8ENTAz
MDGgL6AthitodHRwOi8vY3JsLmlkZW50cnVzdC5jb20vRFNUUk9PVENBWDNDUkwu
Y3JsMB0GA1UdDgQWBBSoSmpjBH3duubRObemRWXv86jsoTANBgkqhkiG9w0BAQsF
AAOCAQEA3TPXEfNjWDjdGBX7CVW+dla5cEilaUcne8IkCJLxWh9KEik3JHRRHGJo
uM2VcGfl96S8TihRzZvoroed6ti6WqEBmtzw3Wodatg+VyOeph4EYpr/1wXKtx8/
wApIvJSwtmVi4MFU5aMqrSDE6ea73Mj2tcMyo5jMd6jmeWUHK8so/joWUoHOUgwu
X4Po1QYz+3dszkDqMp4fklxBwXRsW10KXzPMTZ+sOPAveyxindmjkW8lGy+QsRlG
PfZ+G6Z6h7mjem0Y+iWlkYcV4PIWL1iwBi8saCbGS5jN2p8M+X+Q7UNKEkROb3N6
KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg==
-----END CERTIFICATE-----
}

key: {
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAsJNd12w6gy425hC/P3Gul51Iqk5mWoIkHW/9dDFLPz0FPmYn
/aRlQdiOCo5971adfinsF9ZufBJSJQ12BIXwv5RJLe8iL24LWOmzi/NkBs6U64uI
ASXhFefy7G2ITq3W6ypPYbUL6dcF+3S+UMwsYYb8cYtnaBsZvz3dJPWAyi6LG166
aAxIs6K/49+bnEdOZsVkhi2r6LSq7anPAML6NWVOEsJTOJiuyEUtpAtWvjKaPzSr
gCGP+OrIyCUZNN0jKCkhWDn3THBYqiz+KTToeJAbziGS2vQVz+ryPV6IBRhgpfWx
/9xCAeNkq2ZVP+YkGgpY18IRJa9I2m+MBkRlJwIDAQABAoIBAB36BrZpw0097UgF
k9I7hH5sz0dKZAn9ihANUSQGslWcEGXVhfiDjkUtdH/KTQry0231xAUP/FXH7nYn
4N9HteVwUTQhItaWggqoMjkSKusU6ydJ2t8HBT1o0U7eEYP580CdQDjAObOLM5LK
8PxajTZJalYEapu77hUPdZmurBymnfdd+a9idrZvBJ6sRGihGjExTbJPqyCkwhC3
hQrZdqLZ+j12X9pWlaZY7axLYuzdVD5q/cWC9eMAhzqpooUZMGwHrvBFv2gCzV1+
mUcByE5EDbNCv5jDviljSVbiG3bmhswzrH2IqAOIlBwGszfmx7FQD+dw8A5xwwS+
obVOvTECgYEA2JrLkmDBJ7CsuKsBhIz8uRUTEr9AuKXtpbz0WgTOhApiUZFLA7L/
8ZawhIozs7cSOVua0nyeyU/P5jTaAWLSKKqmfn2JLGNZ7buITdIvvtuk+XyfOWNt
5fGxSUlmAOcNPghpyG9n9/N3a0c3ZkI5FPU5t5FRgaHLWl4yqIra5QsCgYEA0LDN
qt+Tg3hcKig8CN2OiJC1D2GnYihpW0161cxcPqmj12G+yvkAJHu/u7XR8tFfB6pT
Y6fHio+9R0g3sS7GylO5JUVv9c4ds/TbS3oPzwByqKlk1P3GXHrWnJ2+xExuIKp3
gqO1pU5rbiA93GK7eORNirELeEpHktnkqTlpWdUCgYBXfe9MqRhcV9jsnuZ2DBzp
BcI2iFo0O5HKqJBq7BYe77LXD8ElNWB8zUlvwAMyTHhoAsB+1SeuWTa43hBRDwGk
u4mU/lAyRc9FX8Km7IesqDvzKouGOsthXkcmOyegpbOLowpXk+iDFyzdgF64R3eX
J5awt1oc6qWhUvtTaQMSEQKBgQC6KI0+WPRAubQVUxDCo8jKn7MzxlvG3t+kt4fU
gdjjePYTYjkM3HO5F76gFn/zB7uqndCHPBpuyuwAUzaC0oQ35dlpmvhVn4i1h727
JWZGtFKTi4/Lw5kX0+fvi3OprbgrYYT8P0cA7+Q7N32XQ2eSXq2hA2+E3VXddIta
PUFyBQKBgCgoQvwkPtho6X//h7Q+ZHW6lHWZ980LVail/UD6yNVJfjbfh0fjHpN6
N/Lj55jwxDK+z71wR3EkhKuZd2Q0RxSSXAOKl/LfTcEwc2vksmwj3eQwuZEGzOxm
pa2QOlDvQvLkUlONGX2Y6TQJrnga3jwVcRvQmibG9Ar9u5rpFK3h
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
    certs: [(cert) (chain)]
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


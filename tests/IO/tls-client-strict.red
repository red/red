Red [
    title: "Basic Secure TCP test client"
]

root-cert: {
-----BEGIN CERTIFICATE-----
MIIDujCCAqKgAwIBAgIIfNYqE0BDfBIwDQYJKoZIhvcNAQELBQAwezELMAkGA1UE
BhMCQ04xFzAVBgNVBAoTDktleU1hbmFnZXIub3JnMTEwLwYDVQQLEyhLZXlNYW5h
Z2VyIFRlc3QgUm9vdCAtIEZvciBUZXN0IFVzZSBPbmx5MSAwHgYDVQQDExdLZXlN
YW5hZ2VyIFRlc3QgUm9vdCBDQTAeFw0yMDA3MjQwMjUxNTRaFw00MDA3MjQwMjUx
NTRaMHsxCzAJBgNVBAYTAkNOMRcwFQYDVQQKEw5LZXlNYW5hZ2VyLm9yZzExMC8G
A1UECxMoS2V5TWFuYWdlciBUZXN0IFJvb3QgLSBGb3IgVGVzdCBVc2UgT25seTEg
MB4GA1UEAxMXS2V5TWFuYWdlciBUZXN0IFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCtwHYCCEPGuOfoBbRcQvfcdJeG35xypwLpVGOC/Rt8
jZ6BKZqN0kep8Cb1cczGM8R9H14BQXbrbPTqsoK06/4w9bSuk2XVxg7g5Iyst6hI
qp8i65n1IP9HIloGFFRRXya+k2bhhD8x7WOnn7n93PYASZqYyVc8sdu/tLCe5mIN
9dO0skl5eS41crVsU/PFdzil4PiavPNTKNbe2/eU2W7cEnaEU/og8bwU+y13EVv1
BuTBkfR240B1FM4WIlXICNkJtUm6zSbS+3WsJRCaF0zMhHO7/jt3AOIfW4JZoQoF
5C+OM7eAS9lH9IhG2KAr62QrltD2pajNDtBTgBfhCz1VAgMBAAGjQjBAMA4GA1Ud
DwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRNKVphLPPN0s0P
46JKT9qnJ584PTANBgkqhkiG9w0BAQsFAAOCAQEAN8iGZJ83cw1ZShpDEWDf/S+Y
y3MuEr+Z+xvpSHOvwyDBSCP2Z8yx/kPhKirZH2I3nwE14/zp9a2rk5WHHAoenIoU
YiDoUXGim6rcj2BAw+7IY4GoD2rZJPOIwlutTbQjxUnahLjDGdtbJnIwTETbknie
JkYpGbGMtMTwHFf7dBChpVZgq9Yau8akIvnqVMHSIPfTWe/wGubaOTZoo7581tdV
xxKD3Vm6QmrbgQ1KaeepYAW01EAeM1DoGtY5MR+RGJcIr986JDPB0pqIi1o4UNZI
k7DHKNpfN1Dc61cY3vz5rZiTFHoNK8u5P+F6nqQvvjQql6ogIwjQIucZIJO3fQ==
-----END CERTIFICATE-----
}

do [

;debug: :print
debug: :comment

max-count: 300000
count: 0
total: 0.0

print "Secure TCP client"

client: open tls://127.0.0.1:8123
;client: open tls://192.168.1.15:8123

client/extra: compose/deep [
    ;domain: "bitbegin.com"
    ;-- temporary
    accept-invalid-cert: (false)
    disable-builtin-roots: (true)
    roots: [(root-cert)]
    min-protocol: 0302h             ;-- min protocol sslv3,
    max-protocol: 0303h             ;-- max protocol tls1.2
]

start: now/precise
mbps: "?"

b: to-binary "Hello Red"

client/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [insert port b]
        read [
	        probe length? port/data
	        probe to-string port/data
	        insert port b
        ]
        wrote [copy port]
    ]
    false
]
if none? system/view [
	wait client
	close client
	print "Done"
]
]

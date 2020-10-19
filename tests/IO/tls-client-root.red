Red [
    title: "Basic Secure TCP test client"
]

cert: {
-----BEGIN CERTIFICATE-----
MIIEDDCCAvSgAwIBAgIIZLM7o/nXzsgwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNV
BAYTAkNOMRUwEwYDVQQKEwxiaXRiZWdpbi5jb20xHzAdBgNVBAsTFmJpdGJlZ2lu
IHRlc3QgcnNhIHJvb3QxHjAcBgNVBAMTFXJzYS5yb290LmJpdGJlZ2luLmNvbTEh
MB8GCSqGSIb3DQEJAQwSYml0YmVnaW5AZ21haWwuY29tMB4XDTIwMDczMDAzMzUx
MVoXDTIxMDczMDAzMzUxMVowgYgxCzAJBgNVBAYTAkNOMRUwEwYDVQQKEwxiaXRi
ZWdpbi5jb20xHzAdBgNVBAsTFmJpdGJlZ2luIHRlc3QgcnNhIHJvb3QxHjAcBgNV
BAMTFXJzYS5yb290LmJpdGJlZ2luLmNvbTEhMB8GCSqGSIb3DQEJAQwSYml0YmVn
aW5AZ21haWwuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApLQN
YBZkscZY9TXprHGMve7pUlnmm+OvANgabnSCQEDZeYr0FFQ7y8LGP/XWCmr+Fyd+
rJjvwhmSGD3ZKOEqOc3LJkaUCccK3RxeGuGDLDKJ2GX1DtCkXwtQF//SQSA8mpFR
48L9nbITvxPuqN7V1oGV2yXFWUpyQ9kbxKBrrG0eh2PArrDFr97hFbugZ5Stnqrx
5VEHSLzk+T8LQrkJsMaBlsJMLWpLdSe6Xn4XesMf+vBgMC980mhy4aOIF656qrNP
XAgZGVZ8I9TGKVmdtdVhaDNIn+Do24GYZooRInC+LhK2McV+/5LT1aPDDlVq8mZF
eWKY5MLBrPu0r4Gi2QIDAQABo3gwdjAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/
BAUwAwEB/zAdBgNVHQ4EFgQUSrI4ssbNCyj0lBgoYJQgvxBW9vEwNAYDVR0RBC0w
K4IVcnNhLnJvb3QuYml0YmVnaW4uY29tgRJiaXRiZWdpbkBnbWFpbC5jb20wDQYJ
KoZIhvcNAQELBQADggEBAGAhy+qZNy6cCbV0RAHIe28h0OqpUKC0fHG19McRc+hu
22YW7rCt9629S2WJEw2PsQQZ2dV/QA0aEvQ58J8Cgp5PUoSZLQ40uvLZUpVu5CcR
ZTp/9rd/I9wQnoPFwlEYoRbgda+UkdurYMn1gCyC54+4hfHljkdwNQD1T85xlPNs
gFGYm2qMeSp5xnPUvknfS38b9go8ooGZIoCYxFbClNxXRTVydV4rvCdjuziJ74ck
2/swOQIx7WZd8pNezHJbZ2b7K4/6knBHrsNOLxuS9My04pH1fkY3mD42yqf+ichf
VWbx33V8buqISWiaIADGdKYY44Wny1aq4xCYSqfQDw4=
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

client/extra: compose [
    domain: "red-lang.org"
    ;-- temporary
    accept-invalid-cert: false
    disable-builtin-roots: true
    root-cert: (cert)
    ;chain-cert: (chain)            ;-- maybe support chain
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

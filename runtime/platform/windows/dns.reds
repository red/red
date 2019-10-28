Red/System [
	Title:	"Async DNS implementation on Windows"
	Author: "Xie Qingtian"
	File: 	%dns.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define DnsConfigDnsServerList			6
#define DnsTypeA						1
#define DnsTypeAAAA 					28

#define DNS_PACKET_SZ					512

dns: context [
	server-list: as int-ptr! 0
	xid: 0

	getaddrinfo: func [
		addr			[c-string!]
		port			[integer!]
		domain			[integer!]
		dns-data		[dns-data!]
		/local
			res			[integer!]
			len			[integer!]
			buffer		[byte-ptr!]
			fd			[integer!]
			n			[integer!]
			server		[integer!]
			dns-addr	[sockaddr_in6! value]
			recv-addr	[sockaddr_in6! value]
	][
		if null? server-list [
			len: 0
			dnsQueryConfig DnsConfigDnsServerList 0 null null null :len
			if len > 4 [
				server-list: as int-ptr! allocate len
				dnsQueryConfig DnsConfigDnsServerList 0 null null server-list :len
			]
		]

		len: 0
		domain: either domain = AF_INET [DnsTypeA][DnsTypeAAAA]
		system/atomic/add :xid 1
		dnsWriteQuestionToBuffer_UTF8 null :len addr domain xid false
		if len > 0 [
			buffer: allocate len
			dnsWriteQuestionToBuffer_UTF8 buffer :len addr domain xid false
		]

		fd: socket/create AF_INET SOCK_DGRAM IPPROTO_UDP
		n: server-list/1				;-- server-list: IP4_ARRAY
		server: server-list + 1
		port: htons port
		dns-addr/sin_family: port << 16 or AF_INET
		dns-addr/sa_data1: 0
		dns-addr/sa_data2: 0
		loop n [
			dns-addr/sin_addr: server/1
			socket/usend fd dns-addr size? sockaddr_in! buffer len dns-data
		]
	]
]
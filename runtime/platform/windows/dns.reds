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

dns: context [
	server-list: as int-ptr! 0
	server-idx: 0
	xid: 0
	datalen: 0

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
			server		[int-ptr!]
			dns-addr	[sockaddr_in!]
			recv-addr	[sockaddr_in6! value]
			s			[series!]
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
			dns-data/addrinfo: as int-ptr! buffer
		]

		fd: socket/create AF_INET SOCK_DGRAM IPPROTO_UDP
		iocp/bind g-iocp as int-ptr! fd

		n: server-list/1				;-- server-list: IP4_ARRAY

		server: server-list + 1
		port: htons port
		dns-addr: as sockaddr_in! :dns-data/addr
		dns-addr/sin_family: port << 16 or AF_INET
		dns-addr/sa_data1: 0
		dns-addr/sa_data2: 0

		if n > 0 [
			datalen: len
			dns-addr/sin_addr: server/1
			socket/usend fd as sockaddr_in6! dns-addr size? sockaddr_in! buffer len as iocp-data! dns-data

			dns-data/addr-sz: size? sockaddr_in!
			dns-data/device: as int-ptr! fd
		]
	]

	recv: func [
		dns-data	[dns-data!]
		/local
			s		[series!]
	][
		IODebug("dns/recv")
		io/pin-memory dns-data/send-buf
		s: as series! dns-data/send-buf/value
		socket/urecv
			as-integer dns-data/device
			as byte-ptr! s/offset
			DNS_PACKET_SZ
			as sockaddr_in6! :dns-data/addr
			:dns-data/addr-sz
			as sockdata! dns-data
	]

	parse-data: func [
		data	[dns-data!]
		return: [logic!]
		/local
			s		[series!]
			header	[DNS_HEADER]
			addr	[addrinfo!]
			pp		[ptr-value!]
			res		[integer!]
			w1		[integer!]
			w2		[integer!]
			server	[int-ptr!]
			dns-addr [sockaddr_in!]
			port	[integer!]
	][
		io/unpin-memory data/send-buf
		s: as series! data/send-buf/value

		header: as DNS_HEADER s/offset
		res: header/Xid and FFFFh

		header/Xid: header/Xid and FFFF0000h or ntohs res
		w1: ntohs header/QuestionCount and FFFFh
		w2: ntohs header/QuestionCount >>> 16
		header/QuestionCount: w2 << 16 or w1
		w1: ntohs header/NameServerCount and FFFFh
		w2: ntohs header/NameServerCount >>> 16
		header/NameServerCount: w2 << 16 or w1	
		
		res: DnsExtractRecordsFromMessage_UTF8 as DNS_MESSAGE_BUFFER header data/transferred :pp
?? res
		if res <> 0 [
			server-idx: server-idx + 1
			if server-idx < server-list/1 [
				port: htons 53
				dns-addr: as sockaddr_in! :data/addr
				dns-addr/sin_family: port << 16 or AF_INET
				dns-addr/sa_data1: 0
				dns-addr/sa_data2: 0
				server: server-list + 1 + server-idx
				dns-addr/sin_addr: server/1
				socket/usend as-integer data/device as sockaddr_in6! dns-addr size? sockaddr_in! as byte-ptr! data/addrinfo datalen as iocp-data! data
			]
			return no
		]
		no
	]
]
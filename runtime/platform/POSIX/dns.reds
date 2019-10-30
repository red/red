Red/System [
	Title:	"Async DNS implementation on POSIX"
	Author: "Xie Qingtian"
	File: 	%dns.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

dns: context [
	gstate:	as int-ptr! 0

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
			state		[int-ptr!]
			r			[res_state!]
			res			[integer!]
			len			[integer!]
			buffer		[byte-ptr!]
			fd			[integer!]
			n			[integer!]
			server		[int-ptr!]
			dns-addr	[sockaddr_in!]
			s			[series!]
	][
		if null? gstate [
			gstate: as int-ptr! allocate 512
			assert zero? res_ninit gstate
		]
		state: gstate
dump4 state
		domain: either domain = AF_INET [1][28]
		buffer: allocate DNS_PACKET_SZ
		len: res_nmkquery state 0 addr 1 domain null 0 null buffer DNS_PACKET_SZ
?? len
		if len <= 0 [
			probe "Could not create DNS query!"
		]
probe dns-data/type
		dns-data/addrinfo: as int-ptr! buffer
		fd: socket/create AF_INET SOCK_DGRAM IPPROTO_UDP
		r: as res_state! state

		dns-data/addr-sz: size? sockaddr_in!
		dns-addr: as sockaddr_in! :dns-data/addr
		copy-memory as byte-ptr! dns-addr as byte-ptr! :r/nsaddr1 size? sockaddr_in!

probe dns-addr/sin_addr

probe dns-data/type

		dns-data/device: as int-ptr! fd
		if len = socket/send fd buffer len as iocp-data! dns-data [
			0
			;if zero? recv dns-data [
			;	parse-data dns-data
			;]
		]
	]

	recv: func [
		dns-data	[dns-data!]
		return:		[integer!]
		/local
			s		[series!]
	][
		io/pin-memory dns-data/send-buf
		s: as series! dns-data/send-buf/value
		socket/recv
			as-integer dns-data/device
			as byte-ptr! s/offset
			DNS_PACKET_SZ
			as iocp-data! dns-data
	]

	parse-data: func [
		data	[dns-data!]
		return: [logic!]
		/local
			s		[series!]
			pp		[ptr-value!]
			res		[integer!]
			server	[int-ptr!]
			dns-addr [sockaddr_in!]
			port	[integer!]
	][
		io/unpin-memory data/send-buf
		s: as series! data/send-buf/value

		dump4 s

		no
	]
]
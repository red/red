Red [
	title:   "Red locale data file"
	purpose: {
		Data for the default 'red' locale with conventions used by Reducers
		and date formats used by various standards (ISO, RFC, etc)
	}
	author:  [@hiiamboris @greggirwin]
	license: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

system/locale/list/red: #(
	parent: en
	numbers: #(
		latn: #(
			symbols: #(
				group:    "'"
				infinity: "1.#INF"
				nan:      "1.#NAN"
			)
		)
	)
	calendar: #(masks: #(datetime: #()))				;-- placeholder for extension
)


;-----------   standard named date/time formats   -------------
	
;; have to use 'extend' because functions cannot be put into maps directly
extend system/locale/list/red/calendar/masks/datetime to block! object [
	;; http://www.hackcraft.net/web/datetime/
	;; http://tools.ietf.org/html/rfc3339
	;; http://www.w3.org/TR/NOTE-datetime.html
	RFC3339: Atom: W3C: W3C-DTF: function [value [date! time!]] [
		;; Fractional seconds are considered a rarely used option in the RFC.
		;; The question for us is whether to have the user control whether
		;; fractional seconds are used via a special name, or by modding their
		;; data values, by trimming fractional seconds, to avoid them being
		;; included.
		if date? t: value [t: t/time]
		;; If the time includes fractional seconds, include them in
		;; the format, otherwise omit them.
		either zero? remainder t/second 1 [
			"yyyy-mm-dd'T'hhh:mi:ss+zz:zz"
		][
			"yyyy-mm-dd'T'hhh:mi:ss.fff+zz:zz"
		]
	]
	
	;; http://en.wikipedia.org/wiki/ISO_8601
	ISO8601: func [value [date! time!]] [ 				;-- ISO8601 without separators
		either none? value/time [
			"yyyymmdd"
		][
			;; If we want to emit Z for UTC times, we can use the first
			;; option here. The second is simpler, though, and the
			;; output just as valid (and more consistent to boot).
			;;"yyyymmdd'T'hhhmiss+ZZZZ"
			"yyyymmdd'T'hhhmiss+zzzz"
		]
	]
	ISO-8601: func [value [date! time!]] [ 				;-- ISO8601 with separators
		either none? value/time [
			"yyyy-mm-dd"
		][
			;; If we want to emit Z for UTC times, we can use the first
			;; option here. The second is simpler, though, and the
			;; output just as valid (and more consistent to boot).
			;;"yyyy-mm-dd'T'hhh:mi:ss+ZZZZ"
			"yyyy-mm-dd'T'hhh:mi:ss+zzzz"
		]
	]
	
	;; http://www.w3.org/Protocols/rfc822/
	;; http://feed2.w3.org/docs/error/InvalidRFC2822Date.html
	;; http://tech.groups.yahoo.com/group/rss-public/message/536
	;; We use 2 digits for the year to match the spec. RFC2822 uses 4 digits.
	RFC822: "Www, dd Mon yy hhh:mi:ss +zzzz" 
	
	;; http://cyber.law.harvard.edu/rss/rss.html
	;; http://diveintomark.org/archives/2003/06/21/history_of_rss_date_formats
	;; http://www.ietf.org/rfc/rfc1123.txt
	;; http://tools.ietf.org/html/rfc2822#page-14
	RFC2822: RFC1123: RSS: "Www, dd Mon yyyy hhh:mi:ss +zzzz"

	;; Must be in UTC
	;; HTTP-date is case sensitive and MUST NOT include additional
	;; LWS beyond that specifically included as SP in the grammar.
	;; Per https://tools.ietf.org/html/rfc2616#section-3.3.1
	;;	HTTP-date    = rfc1123-date | rfc850-date | asctime-date
	;;	rfc1123-date = wkday "," SP date1 SP time SP "GMT"
	;;	rfc850-date  = weekday "," SP date2 SP time SP "GMT"
	;;	asctime-date = wkday SP date3 SP time SP 4DIGIT				
	;HTTP-Cookie: "Www, dd Mon yyyy hhh:mi:ss GMT"
	HTTP-Cookie:    "Wwww Month yyyy hhh:mi:ss GMT"
	RFC850: USENET: "Wwww, dd Month yy hhh:mi:ss GMT"
	;; http://www.ietf.org/rfc/rfc1036.txt  §2.1.2
	RFC1036:        "Www, dd Mon yy hhh:mm:ss +zzzz"
]


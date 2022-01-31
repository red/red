Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/en: #(
    lang-name: "English"
    region-name: none
    currency: USD
    numbers: #(
        system: latn
        latn: #(
            digits: "0123456789"
            fin-digits: "0123456789"
            symbols: #(
                nan: "NaN"
                infinity: "∞"
                permille: "‰"
                superscripting-exponent: "×"
                exponential: "E"
                approximately: "~"
                minus: "-"
                plus: "+"
                percent: "%"
                list: ";"
                group: ","
                decimal: "."
            )
            masks: #(
                number: #(
                    dec: "# ##0.###"
                    sci: "0.##############E0"
                    pct: "# ##0.%"
                    eng: "0.##############E3"
                )
                money: #(
                    std: "$$# ##0.00"
                    acct: "($$# ##0.00)"
                )
            )
        )
        ordinal-suffixes: #(
            few: "rd"
            one: "st"
            other: "th"
            two: "nd"
        )
    )
    calendar: #(
        standalone: #(
            months: #(
                char: ["J" "F" "M" "A" "M" "J" "J" "A" "S" "O" "N" "D"]
                abbr: ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"]
                full: ["January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December"]
            )
            days: #(
                short: #(
                    sun: "Su"
                    mon: "Mo"
                    tue: "Tu"
                    wed: "We"
                    thu: "Th"
                    fri: "Fr"
                    sat: "Sa"
                )
                full: #(
                    sun: "Sunday"
                    mon: "Monday"
                    tue: "Tuesday"
                    wed: "Wednesday"
                    thu: "Thursday"
                    fri: "Friday"
                    sat: "Saturday"
                )
            )
            quarters: #(
                full: ["1st quarter" "2nd quarter" "3rd quarter" "4th quarter"]
            )
            periods: #(
                char: #(
                    am: "a"
                    pm: "p"
                )
            )
        )
        format: #(
            months: #(
                abbr: ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"]
                full: ["January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December"]
                char: ["J" "F" "M" "A" "M" "J" "J" "A" "S" "O" "N" "D"]
            )
            days: #(
                short: #(
                    sun: "Su"
                    mon: "Mo"
                    tue: "Tu"
                    wed: "We"
                    thu: "Th"
                    fri: "Fr"
                    sat: "Sa"
                )
                full: #(
                    sun: "Sunday"
                    mon: "Monday"
                    tue: "Tuesday"
                    wed: "Wednesday"
                    thu: "Thursday"
                    fri: "Friday"
                    sat: "Saturday"
                )
            )
            quarters: #(
                full: ["1st quarter" "2nd quarter" "3rd quarter" "4th quarter"]
            )
            periods: #(
                char: #(
                    am: "a"
                    pm: "p"
                )
            )
            eras: #(
                full: #(
                    BC: "Before Christ"
                    AD: "Anno Domini"
                    BCE: "Before Common Era"
                    CE: "Common Era"
                )
                abbr: #(
                    BC: "BC"
                    AD: "AD"
                    BCE: "BCE"
                    CE: "CE"
                )
                char: #(
                    BC: "B"
                    AD: "A"
                )
            )
        )
        masks: #(
            date: #(
                full: "Sunday, December 31, 1999"
                long: "December 31, 1999"
                medium: "Dec 31, 1999"
                short: "12/31/99"
            )
            time: #(
                full: "12:59:59 AM 'GMT'+00:00"
                long: "12:59:59 AM 'GMT'+0"
                medium: "12:59:59 AM"
                short: "12:59 AM"
            )
            datetime: #(
                full: {Sunday, December 31, 1999 'at' 12:59:59 AM 'GMT'+00:00}
                long: "December 31, 1999 'at' 12:59:59 AM 'GMT'+0"
                medium: "Dec 31, 1999, 12:59:59 AM"
                short: "12/31/99, 12:59 AM"
            )
        )
    )
    currency-names: #(
        JPY: [std: "¥"]
        USD: [std: "$"]
    )
    parent: root
)
Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/de: #(
    lang-name: "Deutsch"
    region-name: none
    currency: EUR
    numbers: #(
        system: latn
        latn: #(
            digits: "0123456789"
            fin-digits: "0123456789"
            symbols: #(
                nan: "NaN"
                infinity: "∞"
                permille: "‰"
                superscripting-exponent: "·"
                exponential: "E"
                approximately: "≈"
                minus: "-"
                plus: "+"
                percent: "%"
                list: ";"
                group: "."
                decimal: ","
            )
            masks: #(
                number: #(
                    dec: "# ##0.###"
                    sci: "0.##############E0"
                    pct: "# ##0. %"
                    eng: "0.##############E3"
                )
                money: #(
                    std: "# ##0.00 $$"
                    acct: "# ##0.00 $$"
                )
            )
        )
        ordinal-suffixes: #(
            other: "."
        )
    )
    calendar: #(
        day1: mon
        standalone: #(
            months: #(
                abbr: ["Jan" "Feb" "Mär" "Apr" "Mai" "Jun" "Jul" "Aug" "Sep" "Okt" "Nov" "Dez"]
                char: ["J" "F" "M" "A" "M" "J" "J" "A" "S" "O" "N" "D"]
                full: ["Januar" "Februar" "März" "April" "Mai" "Juni" "Juli" "August" "September" "Oktober" "November" "Dezember"]
            )
            days: #(
                abbr: #(
                    sun: "So"
                    mon: "Mo"
                    tue: "Di"
                    wed: "Mi"
                    thu: "Do"
                    fri: "Fr"
                    sat: "Sa"
                )
                char: #(
                    tue: "D"
                    wed: "M"
                    thu: "D"
                )
                short: #(
                    sun: "So."
                    mon: "Mo."
                    tue: "Di."
                    wed: "Mi."
                    thu: "Do."
                    fri: "Fr."
                    sat: "Sa."
                )
                full: #(
                    sun: "Sonntag"
                    mon: "Montag"
                    tue: "Dienstag"
                    wed: "Mittwoch"
                    thu: "Donnerstag"
                    fri: "Freitag"
                    sat: "Samstag"
                )
            )
            quarters: #(
                full: ["1. Quartal" "2. Quartal" "3. Quartal" "4. Quartal"]
            )
        )
        format: #(
            months: #(
                abbr: ["Jan." "Feb." "März" "Apr." "Mai" "Juni" "Juli" "Aug." "Sept." "Okt." "Nov." "Dez."]
                char: ["J" "F" "M" "A" "M" "J" "J" "A" "S" "O" "N" "D"]
                full: ["Januar" "Februar" "März" "April" "Mai" "Juni" "Juli" "August" "September" "Oktober" "November" "Dezember"]
            )
            days: #(
                abbr: #(
                    sun: "So."
                    mon: "Mo."
                    tue: "Di."
                    wed: "Mi."
                    thu: "Do."
                    fri: "Fr."
                    sat: "Sa."
                )
                char: #(
                    tue: "D"
                    wed: "M"
                    thu: "D"
                )
                short: #(
                    sun: "So."
                    mon: "Mo."
                    tue: "Di."
                    wed: "Mi."
                    thu: "Do."
                    fri: "Fr."
                    sat: "Sa."
                )
                full: #(
                    sun: "Sonntag"
                    mon: "Montag"
                    tue: "Dienstag"
                    wed: "Mittwoch"
                    thu: "Donnerstag"
                    fri: "Freitag"
                    sat: "Samstag"
                )
            )
            quarters: #(
                full: ["1. Quartal" "2. Quartal" "3. Quartal" "4. Quartal"]
            )
            eras: #(
                full: #(
                    BC: "v. Chr."
                    AD: "n. Chr."
                    BCE: "vor unserer Zeitrechnung"
                    CE: "unserer Zeitrechnung"
                )
                abbr: #(
                    BC: "v. Chr."
                    AD: "n. Chr."
                    BCE: "v. u. Z."
                    CE: "u. Z."
                )
                char: #(
                    BC: "v. Chr."
                    AD: "n. Chr."
                    BCE: "v. u. Z."
                    CE: "u. Z."
                )
            )
        )
        masks: #(
            date: #(
                full: "Sunday, 31. December 1999"
                long: "31. December 1999"
                medium: "031.012.1999"
                short: "031.012.99"
            )
            datetime: #(
                full: {Sunday, 31. December 1999 'um' 023:59:59 'GMT'+00:00}
                long: "31. December 1999 'um' 023:59:59 'GMT'+0"
                medium: "031.012.1999, 023:59:59"
                short: "031.012.99, 023:59"
            )
        )
    )
    currency-names: #(
        ATS: [std: "öS"]
        AUD: [char: "$" std: "AU$"]
        BGM: [std: "BGK"]
        BGO: [std: "BGJ"]
        BYN: [char: "р."]
        CUC: [char: "Cub$"]
        DEM: [std: "DM"]
        FKP: [char: "Fl£"]
        GHS: [char: "₵"]
        GNF: [char: "F.G."]
        JPY: [std: "¥"]
        KMF: [char: "FC"]
        PHP: [char: "₱"]
        RON: [char: "L"]
        RUR: [char: "р."]
        RWF: [char: "F.Rw"]
        THB: [std: "฿"]
        TWD: [std: "NT$"]
        USD: [std: "$"]
        ZMW: [char: "K"]
    )
    parent: root
)
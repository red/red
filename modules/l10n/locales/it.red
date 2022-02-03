Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/it: #(
    lang-name: "italiano"
    region-name: #[none]
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
                superscripting-exponent: "×"
                exponential: "E"
                approximately: "~"
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
                    pct: "# ##0.%"
                    eng: "0.##############E3"
                )
                money: #(
                    std: "# ##0.00 $$"
                    acct: "# ##0.00 $$"
                )
            )
        )
        ordinal-suffixes: #(
            many: "°"
            other: "°"
        )
    )
    calendar: #(
        day1: mon
        standalone: #(
            months: #(
                abbr: ["gen" "feb" "mar" "apr" "mag" "giu" "lug" "ago" "set" "ott" "nov" "dic"]
                char: ["G" "F" "M" "A" "M" "G" "L" "A" "S" "O" "N" "D"]
                full: ["gennaio" "febbraio" "marzo" "aprile" "maggio" "giugno" "luglio" "agosto" "settembre" "ottobre" "novembre" "dicembre"]
            )
            days: #(
                abbr: #(
                    sun: "dom"
                    mon: "lun"
                    tue: "mar"
                    wed: "mer"
                    thu: "gio"
                    fri: "ven"
                    sat: "sab"
                )
                char: #(
                    sun: "D"
                    mon: "L"
                    tue: "M"
                    wed: "M"
                    thu: "G"
                    fri: "V"
                )
                short: #(
                    sun: "dom"
                    mon: "lun"
                    tue: "mar"
                    wed: "mer"
                    thu: "gio"
                    fri: "ven"
                    sat: "sab"
                )
                full: #(
                    sun: "domenica"
                    mon: "lunedì"
                    tue: "martedì"
                    wed: "mercoledì"
                    thu: "giovedì"
                    fri: "venerdì"
                    sat: "sabato"
                )
            )
            quarters: #(
                abbr: ["T1" "T2" "T3" "T4"]
                full: ["1º trimestre" "2º trimestre" "3º trimestre" "4º trimestre"]
            )
            periods: #(
                char: #(
                    am: "m."
                    pm: "p."
                )
            )
        )
        format: #(
            months: #(
                abbr: ["gen" "feb" "mar" "apr" "mag" "giu" "lug" "ago" "set" "ott" "nov" "dic"]
                char: ["G" "F" "M" "A" "M" "G" "L" "A" "S" "O" "N" "D"]
                full: ["gennaio" "febbraio" "marzo" "aprile" "maggio" "giugno" "luglio" "agosto" "settembre" "ottobre" "novembre" "dicembre"]
            )
            days: #(
                abbr: #(
                    sun: "dom"
                    mon: "lun"
                    tue: "mar"
                    wed: "mer"
                    thu: "gio"
                    fri: "ven"
                    sat: "sab"
                )
                char: #(
                    sun: "D"
                    mon: "L"
                    tue: "M"
                    wed: "M"
                    thu: "G"
                    fri: "V"
                )
                short: #(
                    sun: "dom"
                    mon: "lun"
                    tue: "mar"
                    wed: "mer"
                    thu: "gio"
                    fri: "ven"
                    sat: "sab"
                )
                full: #(
                    sun: "domenica"
                    mon: "lunedì"
                    tue: "martedì"
                    wed: "mercoledì"
                    thu: "giovedì"
                    fri: "venerdì"
                    sat: "sabato"
                )
            )
            quarters: #(
                abbr: ["T1" "T2" "T3" "T4"]
                full: ["1º trimestre" "2º trimestre" "3º trimestre" "4º trimestre"]
            )
            periods: #(
                char: #(
                    am: "m."
                    pm: "p."
                )
            )
            eras: #(
                full: #(
                    BC: "avanti Cristo"
                    AD: "dopo Cristo"
                    BCE: "avanti Era Volgare"
                    CE: "Era Volgare"
                )
                abbr: #(
                    BC: "a.C."
                    AD: "d.C."
                    BCE: "a.E.V."
                    CE: "E.V."
                )
                char: #(
                    BC: "aC"
                    AD: "dC"
                )
            )
        )
        masks: #(
            date: #(
                full: "Sunday 31 December 1999"
                long: "31 December 1999"
                medium: "31 Dec 1999"
                short: "031/012/99"
            )
            datetime: #(
                full: "Sunday 31 December 1999 023:59:59 'GMT'+00:00"
                long: "31 December 1999 023:59:59 'GMT'+0"
                medium: "31 Dec 1999, 023:59:59"
                short: "031/012/99, 023:59"
            )
        )
    )
    currency-names: #(
        BRL: [char: "R$"]
        BYN: [char: "Br"]
        EGP: [char: "£E"]
        HKD: [char: "$"]
        INR: [char: "₹"]
        JPY: [char: "¥"]
        KRW: [char: "₩"]
        MXN: [char: "$"]
        NOK: [char: "NKr"]
        THB: [std: "฿"]
        TWD: [char: "NT$"]
        USD: [char: "$"]
        VND: [char: "₫"]
    )
    parent: root
)
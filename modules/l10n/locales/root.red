Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/root: #(
    lang-name: "root"
    region-name: #[none]
    numbers: #(
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
                    std: "$$ # ##0.00"
                    acct: "$$ # ##0.00"
                )
            )
        )
        arab: #(
            digits: "٠١٢٣٤٥٦٧٨٩"
            fin-digits: "٠١٢٣٤٥٦٧٨٩"
            symbols: #(
                nan: "NaN"
                infinity: "∞"
                permille: "؉"
                superscripting-exponent: "×"
                exponential: "اس"
                approximately: "~"
                minus: "؜-"
                plus: "؜+"
                percent: "٪؜"
                list: "؛"
                group: "٬"
                decimal: "٫"
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
            other: "?"
        )
    )
    calendar: #(
        day1: sun
        standalone: #(
            months: #(
                abbr: ["M01" "M02" "M03" "M04" "M05" "M06" "M07" "M08" "M09" "M10" "M11" "M12"]
                char: ["1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12"]
                full: ["M01" "M02" "M03" "M04" "M05" "M06" "M07" "M08" "M09" "M10" "M11" "M12"]
            )
            days: #(
                abbr: #(
                    sun: "Sun"
                    mon: "Mon"
                    tue: "Tue"
                    wed: "Wed"
                    thu: "Thu"
                    fri: "Fri"
                    sat: "Sat"
                )
                char: #(
                    sun: "S"
                    mon: "M"
                    tue: "T"
                    wed: "W"
                    thu: "T"
                    fri: "F"
                    sat: "S"
                )
                short: #(
                    sun: "Sun"
                    mon: "Mon"
                    tue: "Tue"
                    wed: "Wed"
                    thu: "Thu"
                    fri: "Fri"
                    sat: "Sat"
                )
                full: #(
                    sun: "Sun"
                    mon: "Mon"
                    tue: "Tue"
                    wed: "Wed"
                    thu: "Thu"
                    fri: "Fri"
                    sat: "Sat"
                )
            )
            quarters: #(
                abbr: ["Q1" "Q2" "Q3" "Q4"]
                char: ["1" "2" "3" "4"]
                full: ["Q1" "Q2" "Q3" "Q4"]
            )
            periods: #(
                abbr: #(
                    am: "AM"
                    pm: "PM"
                )
                char: #(
                    am: "AM"
                    pm: "PM"
                )
                full: #(
                    am: "AM"
                    pm: "PM"
                )
            )
        )
        format: #(
            months: #(
                abbr: ["M01" "M02" "M03" "M04" "M05" "M06" "M07" "M08" "M09" "M10" "M11" "M12"]
                char: ["1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12"]
                full: ["M01" "M02" "M03" "M04" "M05" "M06" "M07" "M08" "M09" "M10" "M11" "M12"]
            )
            days: #(
                abbr: #(
                    sun: "Sun"
                    mon: "Mon"
                    tue: "Tue"
                    wed: "Wed"
                    thu: "Thu"
                    fri: "Fri"
                    sat: "Sat"
                )
                char: #(
                    sun: "S"
                    mon: "M"
                    tue: "T"
                    wed: "W"
                    thu: "T"
                    fri: "F"
                    sat: "S"
                )
                short: #(
                    sun: "Sun"
                    mon: "Mon"
                    tue: "Tue"
                    wed: "Wed"
                    thu: "Thu"
                    fri: "Fri"
                    sat: "Sat"
                )
                full: #(
                    sun: "Sun"
                    mon: "Mon"
                    tue: "Tue"
                    wed: "Wed"
                    thu: "Thu"
                    fri: "Fri"
                    sat: "Sat"
                )
            )
            quarters: #(
                abbr: ["Q1" "Q2" "Q3" "Q4"]
                char: ["1" "2" "3" "4"]
                full: ["Q1" "Q2" "Q3" "Q4"]
            )
            periods: #(
                abbr: #(
                    am: "AM"
                    pm: "PM"
                )
                char: #(
                    am: "AM"
                    pm: "PM"
                )
                full: #(
                    am: "AM"
                    pm: "PM"
                )
            )
            eras: #(
                full: #(
                    BC: "BCE"
                    AD: "CE"
                )
                abbr: #(
                    BC: "BCE"
                    AD: "CE"
                )
                char: #(
                    BC: "BCE"
                    AD: "CE"
                )
            )
        )
        masks: #(
            date: #(
                full: "1999 December 31, Sunday"
                long: "1999 December 31"
                medium: "1999 Dec 31"
                short: "1999-012-031"
            )
            time: #(
                full: "023:59:59 'GMT'+00:00"
                long: "023:59:59 'GMT'+0"
                medium: "023:59:59"
                short: "023:59"
            )
            datetime: #(
                full: "1999 December 31, Sunday 023:59:59 'GMT'+00:00"
                long: "1999 December 31 023:59:59 'GMT'+0"
                medium: "1999 Dec 31 023:59:59"
                short: "1999-012-031 023:59"
            )
        )
    )
    currency-names: #(
        AFN: [char: "؋"]
        AMD: [char: "֏"]
        AOA: [char: "Kz"]
        ARS: [char: "$"]
        AUD: [char: "$" std: "A$"]
        AZN: [char: "₼"]
        BAM: [char: "KM"]
        BBD: [char: "$"]
        BDT: [char: "৳"]
        BMD: [char: "$"]
        BND: [char: "$"]
        BOB: [char: "Bs"]
        BRL: [std: "R$"]
        BSD: [char: "$"]
        BWP: [char: "P"]
        BZD: [char: "$"]
        CAD: [char: "$" std: "CA$"]
        CLP: [char: "$"]
        CNY: [char: "¥" std: "CN¥"]
        COP: [char: "$"]
        CRC: [char: "₡"]
        CUC: [char: "$"]
        CUP: [char: "$"]
        CZK: [char: "Kč"]
        DKK: [char: "kr"]
        DOP: [char: "$"]
        EGP: [char: "E£"]
        ESP: [char: "₧"]
        EUR: [std: "€"]
        FJD: [char: "$"]
        FKP: [char: "£"]
        GBP: [std: "£"]
        GEL: [char: "₾"]
        GHS: [char: "GH₵"]
        GIP: [char: "£"]
        GNF: [char: "FG"]
        GTQ: [char: "Q"]
        GYD: [char: "$"]
        HKD: [char: "$" std: "HK$"]
        HNL: [char: "L"]
        HRK: [char: "kn"]
        HUF: [char: "Ft"]
        IDR: [char: "Rp"]
        ILS: [std: "₪"]
        INR: [std: "₹"]
        ISK: [char: "kr"]
        JMD: [char: "$"]
        JPY: [char: "¥" std: "JP¥"]
        KHR: [char: "៛"]
        KMF: [char: "CF"]
        KPW: [char: "₩"]
        KRW: [std: "₩"]
        KYD: [char: "$"]
        KZT: [char: "₸"]
        LAK: [char: "₭"]
        LBP: [char: "L£"]
        LKR: [char: "Rs"]
        LRD: [char: "$"]
        LTL: [char: "Lt"]
        LVL: [char: "Ls"]
        MGA: [char: "Ar"]
        MMK: [char: "K"]
        MNT: [char: "₮"]
        MUR: [char: "Rs"]
        MXN: [char: "$" std: "MX$"]
        MYR: [char: "RM"]
        NAD: [char: "$"]
        NGN: [char: "₦"]
        NIO: [char: "C$"]
        NOK: [char: "kr"]
        NPR: [char: "Rs"]
        NZD: [char: "$" std: "NZ$"]
        PHP: [std: "₱"]
        PKR: [char: "Rs"]
        PLN: [char: "zł"]
        PYG: [char: "₲"]
        RON: [char: "lei"]
        RUB: [char: "₽"]
        RWF: [char: "RF"]
        SBD: [char: "$"]
        SEK: [char: "kr"]
        SGD: [char: "$"]
        SHP: [char: "£"]
        SRD: [char: "$"]
        SSP: [char: "£"]
        STN: [char: "Db"]
        SYP: [char: "£"]
        THB: [char: "฿"]
        TOP: [char: "T$"]
        TRY: [char: "₺"]
        TTD: [char: "$"]
        TWD: [char: "$" std: "NT$"]
        UAH: [char: "₴"]
        USD: [char: "$" std: "US$"]
        UYU: [char: "$"]
        VEF: [char: "Bs"]
        VND: [std: "₫"]
        XAF: [std: "FCFA"]
        XCD: [char: "$" std: "EC$"]
        XOF: [std: "F CFA"]
        XPF: [std: "CFPF"]
        XXX: [std: "¤"]
        ZAR: [char: "R"]
        ZMW: [char: "ZK"]
    )
)
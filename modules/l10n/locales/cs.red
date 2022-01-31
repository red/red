Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/cs: #(
    lang-name: "čeština"
    region-name: none
    currency: CZK
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
                group: " "
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
                abbr: ["led" "úno" "bře" "dub" "kvě" "čvn" "čvc" "srp" "zář" "říj" "lis" "pro"]
                full: ["leden" "únor" "březen" "duben" "květen" "červen" "červenec" "srpen" "září" "říjen" "listopad" "prosinec"]
            )
            days: #(
                abbr: #(
                    sun: "ne"
                    mon: "po"
                    tue: "út"
                    wed: "st"
                    thu: "čt"
                    fri: "pá"
                    sat: "so"
                )
                char: #(
                    sun: "N"
                    mon: "P"
                    tue: "Ú"
                    wed: "S"
                    thu: "Č"
                    fri: "P"
                )
                short: #(
                    sun: "ne"
                    mon: "po"
                    tue: "út"
                    wed: "st"
                    thu: "čt"
                    fri: "pá"
                    sat: "so"
                )
                full: #(
                    sun: "neděle"
                    mon: "pondělí"
                    tue: "úterý"
                    wed: "středa"
                    thu: "čtvrtek"
                    fri: "pátek"
                    sat: "sobota"
                )
            )
            quarters: #(
                full: ["1. čtvrtletí" "2. čtvrtletí" "3. čtvrtletí" "4. čtvrtletí"]
            )
            periods: #(
                abbr: #(
                    am: "dop."
                    pm: "odp."
                )
                char: #(
                    am: "dop."
                    pm: "odp."
                )
                full: #(
                    am: "dop."
                    pm: "odp."
                )
            )
        )
        format: #(
            months: #(
                abbr: ["led" "úno" "bře" "dub" "kvě" "čvn" "čvc" "srp" "zář" "říj" "lis" "pro"]
                full: ["ledna" "února" "března" "dubna" "května" "června" "července" "srpna" "září" "října" "listopadu" "prosince"]
            )
            days: #(
                abbr: #(
                    sun: "ne"
                    mon: "po"
                    tue: "út"
                    wed: "st"
                    thu: "čt"
                    fri: "pá"
                    sat: "so"
                )
                char: #(
                    sun: "N"
                    mon: "P"
                    tue: "Ú"
                    wed: "S"
                    thu: "Č"
                    fri: "P"
                )
                short: #(
                    sun: "ne"
                    mon: "po"
                    tue: "út"
                    wed: "st"
                    thu: "čt"
                    fri: "pá"
                    sat: "so"
                )
                full: #(
                    sun: "neděle"
                    mon: "pondělí"
                    tue: "úterý"
                    wed: "středa"
                    thu: "čtvrtek"
                    fri: "pátek"
                    sat: "sobota"
                )
            )
            quarters: #(
                full: ["1. čtvrtletí" "2. čtvrtletí" "3. čtvrtletí" "4. čtvrtletí"]
            )
            periods: #(
                abbr: #(
                    am: "dop."
                    pm: "odp."
                )
                char: #(
                    am: "dop."
                    pm: "odp."
                )
                full: #(
                    am: "dop."
                    pm: "odp."
                )
            )
            eras: #(
                full: #(
                    BC: "před naším letopočtem"
                    AD: "našeho letopočtu"
                    BCE: "před naším letopočtem"
                    CE: "našeho letopočtu"
                )
                abbr: #(
                    BC: "př. n. l."
                    AD: "n. l."
                )
                char: #(
                    BC: "př.n.l."
                    AD: "n.l."
                )
            )
        )
        masks: #(
            date: #(
                full: "Sunday 31. December 1999"
                long: "31. December 1999"
                medium: "31. 12. 1999"
                short: "031.012.99"
            )
            time: #(
                full: "23:59:59 'GMT'+00:00"
                long: "23:59:59 'GMT'+0"
                medium: "23:59:59"
                short: "23:59"
            )
            datetime: #(
                full: "Sunday 31. December 1999 23:59:59 'GMT'+00:00"
                long: "31. December 1999 23:59:59 'GMT'+0"
                medium: "31. 12. 1999 23:59:59"
                short: "031.012.99 23:59"
            )
        )
    )
    currency-names: #(
        AUD: [char: "$" std: "AU$"]
        BYN: [char: "р."]
        CSK: [std: "Kčs"]
        CZK: [std: "Kč"]
        ILS: [char: "₪"]
        INR: [char: "₹"]
        PHP: [char: "₱"]
        RON: [char: "L"]
        RUR: [char: "р."]
        TWD: [std: "NT$"]
        VND: [char: "₫"]
        XEU: [std: "ECU"]
    )
    parent: root
)
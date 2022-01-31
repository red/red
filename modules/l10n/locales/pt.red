Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/pt: #(
    lang-name: "português"
    region-name: none
    currency: BRL
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
                    std: "$$ # ##0.00"
                    acct: "$$ # ##0.00"
                )
            )
        )
        ordinal-suffixes: #(
            other: "ª"
        )
    )
    calendar: #(
        standalone: #(
            months: #(
                char: ["J" "F" "M" "A" "M" "J" "J" "A" "S" "O" "N" "D"]
                full: ["janeiro" "fevereiro" "março" "abril" "maio" "junho" "julho" "agosto" "setembro" "outubro" "novembro" "dezembro"]
                abbr: ["jan." "fev." "mar." "abr." "mai." "jun." "jul." "ago." "set." "out." "nov." "dez."]
            )
            days: #(
                char: #(
                    sun: "D"
                    mon: "S"
                    wed: "Q"
                    thu: "Q"
                    fri: "S"
                )
                full: #(
                    sun: "domingo"
                    mon: "segunda-feira"
                    tue: "terça-feira"
                    wed: "quarta-feira"
                    thu: "quinta-feira"
                    fri: "sexta-feira"
                    sat: "sábado"
                )
                abbr: #(
                    sun: "dom."
                    mon: "seg."
                    tue: "ter."
                    wed: "qua."
                    thu: "qui."
                    fri: "sex."
                    sat: "sáb."
                )
            )
            quarters: #(
                abbr: ["T1" "T2" "T3" "T4"]
                full: ["1º trimestre" "2º trimestre" "3º trimestre" "4º trimestre"]
            )
        )
        format: #(
            months: #(
                abbr: ["jan." "fev." "mar." "abr." "mai." "jun." "jul." "ago." "set." "out." "nov." "dez."]
                char: ["J" "F" "M" "A" "M" "J" "J" "A" "S" "O" "N" "D"]
                full: ["janeiro" "fevereiro" "março" "abril" "maio" "junho" "julho" "agosto" "setembro" "outubro" "novembro" "dezembro"]
            )
            days: #(
                abbr: #(
                    sun: "dom."
                    mon: "seg."
                    tue: "ter."
                    wed: "qua."
                    thu: "qui."
                    fri: "sex."
                    sat: "sáb."
                )
                char: #(
                    sun: "D"
                    mon: "S"
                    wed: "Q"
                    thu: "Q"
                    fri: "S"
                )
                full: #(
                    sun: "domingo"
                    mon: "segunda-feira"
                    tue: "terça-feira"
                    wed: "quarta-feira"
                    thu: "quinta-feira"
                    fri: "sexta-feira"
                    sat: "sábado"
                )
            )
            quarters: #(
                abbr: ["T1" "T2" "T3" "T4"]
                full: ["1º trimestre" "2º trimestre" "3º trimestre" "4º trimestre"]
            )
            eras: #(
                full: #(
                    BC: "antes de Cristo"
                    AD: "depois de Cristo"
                    BCE: "antes da Era Comum"
                    CE: "Era Comum"
                )
                abbr: #(
                    BC: "a.C."
                    AD: "d.C."
                    BCE: "AEC"
                    CE: "EC"
                )
            )
        )
        masks: #(
            date: #(
                full: "Sunday, 31 'de' December 'de' 1999"
                long: "31 'de' December 'de' 1999"
                medium: "31 'de' Dec 'de' 1999"
                short: "031/012/1999"
            )
            datetime: #(
                full: {Sunday, 31 'de' December 'de' 1999 023:59:59 'GMT'+00:00}
                long: "31 'de' December 'de' 1999 023:59:59 'GMT'+0"
                medium: "31 'de' Dec 'de' 1999 023:59:59"
                short: "031/012/1999 023:59"
            )
        )
    )
    currency-names: #(
        AUD: [char: "$" std: "AU$"]
        BYN: [char: "р."]
        PHP: [char: "₱"]
        PTE: [std: "Esc."]
        RON: [char: "L"]
        SYP: [char: "S£"]
        THB: [std: "฿"]
        TWD: [std: "NT$"]
    )
    parent: root
)
Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/ru: #(
    lang-name: "русский"
    region-name: none
    currency: RUB
    numbers: #(
        system: latn
        latn: #(
            digits: "0123456789"
            fin-digits: "0123456789"
            symbols: #(
                nan: "не число"
                infinity: "∞"
                permille: "‰"
                superscripting-exponent: "×"
                exponential: "E"
                approximately: "≈"
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
            other: "-й"
        )
    )
    calendar: #(
        day1: mon
        standalone: #(
            months: #(
                abbr: ["янв." "февр." "март" "апр." "май" "июнь" "июль" "авг." "сент." "окт." "нояб." "дек."]
                char: ["Я" "Ф" "М" "А" "М" "И" "И" "А" "С" "О" "Н" "Д"]
                full: ["январь" "февраль" "март" "апрель" "май" "июнь" "июль" "август" "сентябрь" "октябрь" "ноябрь" "декабрь"]
            )
            days: #(
                abbr: #(
                    sun: "вс"
                    mon: "пн"
                    tue: "вт"
                    wed: "ср"
                    thu: "чт"
                    fri: "пт"
                    sat: "сб"
                )
                char: #(
                    sun: "В"
                    mon: "П"
                    tue: "В"
                    wed: "С"
                    thu: "Ч"
                    fri: "П"
                    sat: "С"
                )
                short: #(
                    sun: "вс"
                    mon: "пн"
                    tue: "вт"
                    wed: "ср"
                    thu: "чт"
                    fri: "пт"
                    sat: "сб"
                )
                full: #(
                    sun: "воскресенье"
                    mon: "понедельник"
                    tue: "вторник"
                    wed: "среда"
                    thu: "четверг"
                    fri: "пятница"
                    sat: "суббота"
                )
            )
            quarters: #(
                abbr: ["1-й кв." "2-й кв." "3-й кв." "4-й кв."]
                full: ["1-й квартал" "2-й квартал" "3-й квартал" "4-й квартал"]
            )
        )
        format: #(
            months: #(
                abbr: ["янв." "февр." "мар." "апр." "мая" "июн." "июл." "авг." "сент." "окт." "нояб." "дек."]
                char: ["Я" "Ф" "М" "А" "М" "И" "И" "А" "С" "О" "Н" "Д"]
                full: ["января" "февраля" "марта" "апреля" "мая" "июня" "июля" "августа" "сентября" "октября" "ноября" "декабря"]
            )
            days: #(
                abbr: #(
                    sun: "вс"
                    mon: "пн"
                    tue: "вт"
                    wed: "ср"
                    thu: "чт"
                    fri: "пт"
                    sat: "сб"
                )
                short: #(
                    sun: "вс"
                    mon: "пн"
                    tue: "вт"
                    wed: "ср"
                    thu: "чт"
                    fri: "пт"
                    sat: "сб"
                )
                full: #(
                    sun: "воскресенье"
                    mon: "понедельник"
                    tue: "вторник"
                    wed: "среда"
                    thu: "четверг"
                    fri: "пятница"
                    sat: "суббота"
                )
                char: #(
                    sun: "В"
                    mon: "П"
                    tue: "В"
                    wed: "С"
                    thu: "Ч"
                    fri: "П"
                    sat: "С"
                )
            )
            quarters: #(
                abbr: ["1-й кв." "2-й кв." "3-й кв." "4-й кв."]
                full: ["1-й квартал" "2-й квартал" "3-й квартал" "4-й квартал"]
            )
            eras: #(
                full: #(
                    BC: "до Рождества Христова"
                    AD: "от Рождества Христова"
                    BCE: "до нашей эры"
                    CE: "нашей эры"
                )
                abbr: #(
                    BC: "до Р. Х."
                    AD: "от Р. Х."
                    CE: "н. э."
                    BCE: "до н. э."
                )
                char: #(
                    BC: "до Р.Х."
                    AD: "от Р.Х."
                    CE: "н.э."
                    BCE: "до н.э."
                )
            )
        )
        masks: #(
            date: #(
                full: "Sunday, 31 December 1999 'г'."
                long: "31 December 1999 'г'."
                medium: "31 Dec 1999 'г'."
                short: "031.012.1999"
            )
            datetime: #(
                full: {Sunday, 31 December 1999 'г'., 023:59:59 'GMT'+00:00}
                long: "31 December 1999 'г'., 023:59:59 'GMT'+0"
                medium: "31 Dec 1999 'г'., 023:59:59"
                short: "031.012.1999, 023:59"
            )
        )
    )
    currency-names: #(
        BYN: [char: "р."]
        GEL: [char: "ლ"]
        JPY: [std: "¥"]
        PHP: [char: "₱"]
        RON: [char: "L"]
        RUB: [std: "₽"]
        RUR: [std: "р."]
        THB: [std: "฿"]
        TMT: [std: "ТМТ"]
        TWD: [std: "NT$"]
        UAH: [std: "₴"]
        USD: [std: "$"]
        XXX: [std: "XXXX"]
    )
    parent: root
)
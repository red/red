Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/ja: #(
    lang-name: "日本語"
    region-name: none
    currency: JPY
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
                approximately: "約"
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
            other: " 番目の角を右折します。"
        )
    )
    calendar: #(
        standalone: #(
            months: #(
                abbr: ["1月" "2月" "3月" "4月" "5月" "6月" "7月" "8月" "9月" "10月" "11月" "12月"]
                full: ["1月" "2月" "3月" "4月" "5月" "6月" "7月" "8月" "9月" "10月" "11月" "12月"]
            )
            days: #(
                abbr: #(
                    sun: "日"
                    mon: "月"
                    tue: "火"
                    wed: "水"
                    thu: "木"
                    fri: "金"
                    sat: "土"
                )
                char: #(
                    sun: "日"
                    mon: "月"
                    tue: "火"
                    wed: "水"
                    thu: "木"
                    fri: "金"
                    sat: "土"
                )
                short: #(
                    sun: "日"
                    mon: "月"
                    tue: "火"
                    wed: "水"
                    thu: "木"
                    fri: "金"
                    sat: "土"
                )
                full: #(
                    sun: "日曜日"
                    mon: "月曜日"
                    tue: "火曜日"
                    wed: "水曜日"
                    thu: "木曜日"
                    fri: "金曜日"
                    sat: "土曜日"
                )
            )
            quarters: #(
                full: ["第1四半期" "第2四半期" "第3四半期" "第4四半期"]
            )
            periods: #(
                abbr: #(
                    am: "午前"
                    pm: "午後"
                )
                char: #(
                    am: "午前"
                    pm: "午後"
                )
                full: #(
                    am: "午前"
                    pm: "午後"
                )
            )
        )
        format: #(
            months: #(
                abbr: ["1月" "2月" "3月" "4月" "5月" "6月" "7月" "8月" "9月" "10月" "11月" "12月"]
                full: ["1月" "2月" "3月" "4月" "5月" "6月" "7月" "8月" "9月" "10月" "11月" "12月"]
            )
            days: #(
                abbr: #(
                    sun: "日"
                    mon: "月"
                    tue: "火"
                    wed: "水"
                    thu: "木"
                    fri: "金"
                    sat: "土"
                )
                char: #(
                    sun: "日"
                    mon: "月"
                    tue: "火"
                    wed: "水"
                    thu: "木"
                    fri: "金"
                    sat: "土"
                )
                short: #(
                    sun: "日"
                    mon: "月"
                    tue: "火"
                    wed: "水"
                    thu: "木"
                    fri: "金"
                    sat: "土"
                )
                full: #(
                    sun: "日曜日"
                    mon: "月曜日"
                    tue: "火曜日"
                    wed: "水曜日"
                    thu: "木曜日"
                    fri: "金曜日"
                    sat: "土曜日"
                )
            )
            quarters: #(
                full: ["第1四半期" "第2四半期" "第3四半期" "第4四半期"]
            )
            periods: #(
                abbr: #(
                    am: "午前"
                    pm: "午後"
                )
                char: #(
                    am: "午前"
                    pm: "午後"
                )
                full: #(
                    am: "午前"
                    pm: "午後"
                )
            )
            eras: #(
                full: #(
                    BC: "紀元前"
                    AD: "西暦"
                    BCE: "西暦紀元前"
                    CE: "西暦紀元"
                )
                abbr: #(
                    BC: "紀元前"
                    AD: "西暦"
                    BCE: "西暦紀元前"
                    CE: "西暦紀元"
                )
                char: #(
                    BC: "BC"
                    AD: "AD"
                )
            )
        )
        masks: #(
            date: #(
                full: "1999年12月31日Sunday"
                long: "1999年12月31日"
                medium: "1999/012/031"
                short: "1999/012/031"
            )
            time: #(
                full: "23時59分59秒 'GMT'+00:00"
                long: "23:59:59 'GMT'+0"
                medium: "23:59:59"
                short: "23:59"
            )
            datetime: #(
                full: "1999年12月31日Sunday 23時59分59秒 'GMT'+00:00"
                long: "1999年12月31日 23:59:59 'GMT'+0"
                medium: "1999/012/031 23:59:59"
                short: "1999/012/031 23:59"
            )
        )
    )
    currency-names: #(
        BYN: [char: "р."]
        CNY: [char: "￥" std: "元"]
        JPY: [std: "￥"]
        PHP: [char: "₱"]
        RON: [char: "レイ"]
        USD: [std: "$"]
    )
    parent: root
)
Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/zh: #(
    lang-name: "中文"
    region-name: #[none]
    currency: CNY
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
            other: " 个路口右转。"
        )
    )
    calendar: #(
        standalone: #(
            months: #(
                abbr: ["1月" "2月" "3月" "4月" "5月" "6月" "7月" "8月" "9月" "10月" "11月" "12月"]
                full: ["一月" "二月" "三月" "四月" "五月" "六月" "七月" "八月" "九月" "十月" "十一月" "十二月"]
            )
            days: #(
                abbr: #(
                    sun: "周日"
                    mon: "周一"
                    tue: "周二"
                    wed: "周三"
                    thu: "周四"
                    fri: "周五"
                    sat: "周六"
                )
                char: #(
                    sun: "日"
                    mon: "一"
                    tue: "二"
                    wed: "三"
                    thu: "四"
                    fri: "五"
                    sat: "六"
                )
                short: #(
                    sun: "周日"
                    mon: "周一"
                    tue: "周二"
                    wed: "周三"
                    thu: "周四"
                    fri: "周五"
                    sat: "周六"
                )
                full: #(
                    sun: "星期日"
                    mon: "星期一"
                    tue: "星期二"
                    wed: "星期三"
                    thu: "星期四"
                    fri: "星期五"
                    sat: "星期六"
                )
            )
            quarters: #(
                abbr: ["1季度" "2季度" "3季度" "4季度"]
                full: ["第一季度" "第二季度" "第三季度" "第四季度"]
            )
            periods: #(
                abbr: #(
                    am: "上午"
                    pm: "下午"
                )
                char: #(
                    am: "上午"
                    pm: "下午"
                )
                full: #(
                    am: "上午"
                    pm: "下午"
                )
            )
        )
        format: #(
            months: #(
                abbr: ["1月" "2月" "3月" "4月" "5月" "6月" "7月" "8月" "9月" "10月" "11月" "12月"]
                full: ["一月" "二月" "三月" "四月" "五月" "六月" "七月" "八月" "九月" "十月" "十一月" "十二月"]
            )
            days: #(
                abbr: #(
                    sun: "周日"
                    mon: "周一"
                    tue: "周二"
                    wed: "周三"
                    thu: "周四"
                    fri: "周五"
                    sat: "周六"
                )
                char: #(
                    sun: "日"
                    mon: "一"
                    tue: "二"
                    wed: "三"
                    thu: "四"
                    fri: "五"
                    sat: "六"
                )
                short: #(
                    sun: "周日"
                    mon: "周一"
                    tue: "周二"
                    wed: "周三"
                    thu: "周四"
                    fri: "周五"
                    sat: "周六"
                )
                full: #(
                    sun: "星期日"
                    mon: "星期一"
                    tue: "星期二"
                    wed: "星期三"
                    thu: "星期四"
                    fri: "星期五"
                    sat: "星期六"
                )
            )
            quarters: #(
                abbr: ["1季度" "2季度" "3季度" "4季度"]
                full: ["第一季度" "第二季度" "第三季度" "第四季度"]
            )
            periods: #(
                abbr: #(
                    am: "上午"
                    pm: "下午"
                )
                char: #(
                    am: "上午"
                    pm: "下午"
                )
                full: #(
                    am: "上午"
                    pm: "下午"
                )
            )
            eras: #(
                full: #(
                    BC: "公元前"
                    AD: "公元"
                )
                abbr: #(
                    BC: "公元前"
                    AD: "公元"
                )
                char: #(
                    BC: "公元前"
                    AD: "公元"
                )
            )
        )
        masks: #(
            date: #(
                full: "1999年12月31日Sunday"
                long: "1999年12月31日"
                medium: "1999年12月31日"
                short: "1999/12/31"
            )
            time: #(
                full: "'GMT'+00:00 023:59:59"
                long: "'GMT'+0 023:59:59"
            )
            datetime: #(
                full: "1999年12月31日Sunday 'GMT'+00:00 023:59:59"
                long: "1999年12月31日 'GMT'+0 023:59:59"
                medium: "1999年12月31日 023:59:59"
                short: "1999/12/31 023:59"
            )
        )
    )
    currency-names: #(
        AUD: [char: "$" std: "AU$"]
        BYN: [char: "р."]
        CNY: [std: "¥"]
        ILR: [std: "ILS"]
        KRW: [char: "₩" std: "￦"]
        PHP: [char: "₱"]
        RUR: [char: "р."]
        TWD: [std: "NT$"]
    )
    parent: root
)
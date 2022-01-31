Red [
	title:  "Red locale data file"
	notes:  "DO NOT MODIFY! Generated automatically from CLDR data"
	license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
]

system/locale/list/ko: #(
    lang-name: "한국어"
    region-name: none
    currency: KRW
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
            other: "번째"
        )
    )
    calendar: #(
        standalone: #(
            months: #(
                abbr: ["1월" "2월" "3월" "4월" "5월" "6월" "7월" "8월" "9월" "10월" "11월" "12월"]
                char: ["1월" "2월" "3월" "4월" "5월" "6월" "7월" "8월" "9월" "10월" "11월" "12월"]
                full: ["1월" "2월" "3월" "4월" "5월" "6월" "7월" "8월" "9월" "10월" "11월" "12월"]
            )
            days: #(
                abbr: #(
                    sun: "일"
                    mon: "월"
                    tue: "화"
                    wed: "수"
                    thu: "목"
                    fri: "금"
                    sat: "토"
                )
                char: #(
                    sun: "일"
                    mon: "월"
                    tue: "화"
                    wed: "수"
                    thu: "목"
                    fri: "금"
                    sat: "토"
                )
                short: #(
                    sun: "일"
                    mon: "월"
                    tue: "화"
                    wed: "수"
                    thu: "목"
                    fri: "금"
                    sat: "토"
                )
                full: #(
                    sun: "일요일"
                    mon: "월요일"
                    tue: "화요일"
                    wed: "수요일"
                    thu: "목요일"
                    fri: "금요일"
                    sat: "토요일"
                )
            )
            quarters: #(
                abbr: ["1분기" "2분기" "3분기" "4분기"]
                full: ["제 1/4분기" "제 2/4분기" "제 3/4분기" "제 4/4분기"]
            )
            periods: #(
                full: #(
                    am: "오전"
                    pm: "오후"
                )
            )
        )
        format: #(
            months: #(
                abbr: ["1월" "2월" "3월" "4월" "5월" "6월" "7월" "8월" "9월" "10월" "11월" "12월"]
                char: ["1월" "2월" "3월" "4월" "5월" "6월" "7월" "8월" "9월" "10월" "11월" "12월"]
                full: ["1월" "2월" "3월" "4월" "5월" "6월" "7월" "8월" "9월" "10월" "11월" "12월"]
            )
            days: #(
                abbr: #(
                    sun: "일"
                    mon: "월"
                    tue: "화"
                    wed: "수"
                    thu: "목"
                    fri: "금"
                    sat: "토"
                )
                char: #(
                    sun: "일"
                    mon: "월"
                    tue: "화"
                    wed: "수"
                    thu: "목"
                    fri: "금"
                    sat: "토"
                )
                short: #(
                    sun: "일"
                    mon: "월"
                    tue: "화"
                    wed: "수"
                    thu: "목"
                    fri: "금"
                    sat: "토"
                )
                full: #(
                    sun: "일요일"
                    mon: "월요일"
                    tue: "화요일"
                    wed: "수요일"
                    thu: "목요일"
                    fri: "금요일"
                    sat: "토요일"
                )
            )
            quarters: #(
                abbr: ["1분기" "2분기" "3분기" "4분기"]
                full: ["제 1/4분기" "제 2/4분기" "제 3/4분기" "제 4/4분기"]
            )
            periods: #(
                full: #(
                    am: "오전"
                    pm: "오후"
                )
            )
            eras: #(
                full: #(
                    BC: "기원전"
                    AD: "서기"
                    BCE: "BCE"
                    CE: "CE"
                )
                abbr: #(
                    BC: "BC"
                    AD: "AD"
                    BCE: "BCE"
                    CE: "CE"
                )
            )
        )
        masks: #(
            date: #(
                full: "1999년 12월 31일 Sunday"
                long: "1999년 12월 31일"
                medium: "1999. 12. 31."
                short: "99. 12. 31."
            )
            time: #(
                full: "AM 12시 m분 s초 'GMT'+00:00"
                long: "AM 12시 m분 s초 'GMT'+0"
                medium: "AM 12:59:59"
                short: "AM 12:59"
            )
            datetime: #(
                full: "1999년 12월 31일 Sunday AM 12시 m분 s초 'GMT'+00:00"
                long: "1999년 12월 31일 AM 12시 m분 s초 'GMT'+0"
                medium: "1999. 12. 31. AM 12:59:59"
                short: "99. 12. 31. AM 12:59"
            )
        )
    )
    currency-names: #(
        AUD: [char: "$" std: "AU$"]
        BYN: [char: "р."]
        PHP: [char: "₱"]
        RON: [char: "L"]
        TWD: [std: "NT$"]
    )
    parent: root
)
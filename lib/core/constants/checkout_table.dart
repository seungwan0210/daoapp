// lib/core/constants/checkout_table.dart
import 'package:daoapp/data/models/checkout_route_model.dart';

/// 점수별 추천 체크아웃 루트 테이블
/// key: 남은 점수 (String)
/// value: CheckoutRoute (primary + alts)
final Map<String, CheckoutRoute> checkoutTable = {
  // === 170 ~ 151 ===
  "170": CheckoutRoute(primary: ["T20", "T20", "Bull"], alts: []),
  "167": CheckoutRoute(primary: ["T20", "T19", "Bull"], alts: []),
  "164": CheckoutRoute(primary: ["T20", "T18", "Bull"], alts: []),
  "161": CheckoutRoute(primary: ["T20", "T17", "Bull"], alts: []),
  "160": CheckoutRoute(primary: ["T20", "T20", "D20"], alts: [
    ["T19", "T19", "D16"],
  ]),
  "158": CheckoutRoute(primary: ["T20", "T20", "D19"], alts: []),
  "157": CheckoutRoute(primary: ["T20", "T19", "D20"], alts: []),
  "156": CheckoutRoute(primary: ["T20", "T20", "D18"], alts: []),
  "155": CheckoutRoute(primary: ["T20", "T19", "D18"], alts: []),
  "154": CheckoutRoute(primary: ["T20", "T18", "D20"], alts: []),
  "153": CheckoutRoute(primary: ["T20", "T19", "D17"], alts: []),
  "152": CheckoutRoute(primary: ["T20", "T20", "D16"], alts: []),
  "151": CheckoutRoute(primary: ["T20", "T17", "D20"], alts: []),
  "150": CheckoutRoute(
    primary: ["T20", "T18", "D18"],
    alts: [
      ["T20", "Bull", "D20"],
    ],
  ),

  // === 149 ~ 130 ===
  "149": CheckoutRoute(primary: ["T20", "T19", "D16"], alts: []),
  "148": CheckoutRoute(primary: ["T20", "T16", "D20"], alts: []),
  "147": CheckoutRoute(primary: ["T20", "T17", "D18"], alts: []),
  "146": CheckoutRoute(primary: ["T20", "T18", "D16"], alts: []),
  "145": CheckoutRoute(primary: ["T20", "T15", "D20"], alts: []),
  "144": CheckoutRoute(primary: ["T20", "T20", "D12"], alts: []),
  "143": CheckoutRoute(primary: ["T20", "T17", "D16"], alts: []),
  "142": CheckoutRoute(primary: ["T20", "T14", "D20"], alts: []),
  "141": CheckoutRoute(primary: ["T20", "T19", "D12"], alts: []),
  "140": CheckoutRoute(
    primary: ["T20", "T20", "D10"],
    alts: [
      ["T20", "Bull", "D10"],
    ],
  ),
  "139": CheckoutRoute(primary: ["T19", "T19", "D12"], alts: []),
  "138": CheckoutRoute(primary: ["T20", "T18", "D12"], alts: []),
  "137": CheckoutRoute(primary: ["T19", "T18", "D13"], alts: []),
  "136": CheckoutRoute(primary: ["T20", "T20", "D8"], alts: []),
  "135": CheckoutRoute(primary: ["T20", "T15", "D15"], alts: []),
  "134": CheckoutRoute(primary: ["T20", "T14", "D16"], alts: []),
  "133": CheckoutRoute(primary: ["T20", "T19", "D8"], alts: []),
  "132": CheckoutRoute(
    primary: ["T20", "T12", "D18"],
    alts: [
      ["Bull", "Bull", "D16"],
    ],
  ),
  "131": CheckoutRoute(primary: ["T20", "T17", "D10"], alts: []),
  "130": CheckoutRoute(
    primary: ["T20", "T18", "D10"],
    alts: [
      ["Bull", "T20", "D10"],
    ],
  ),

  // === 129 ~ 110 ===
  "129": CheckoutRoute(primary: ["T19", "T19", "D6"], alts: []),
  "128": CheckoutRoute(primary: ["T20", "T16", "D10"], alts: []),
  "127": CheckoutRoute(primary: ["T20", "T17", "D8"], alts: []),
  "126": CheckoutRoute(
    primary: ["T20", "T10", "D18"],
    alts: [
      ["Bull", "T18", "D12"],
    ],
  ),
  "125": CheckoutRoute(
    primary: ["T20", "T15", "D10"],
    alts: [
      ["Bull", "T17", "D9"],
    ],
  ),
  "124": CheckoutRoute(primary: ["T20", "T16", "D8"], alts: []),
  "123": CheckoutRoute(primary: ["T19", "T16", "D9"], alts: []),
  "122": CheckoutRoute(primary: ["T20", "T14", "D10"], alts: []),
  "121": CheckoutRoute(
    primary: ["T20", "S11", "D20"],
    alts: [
      ["T19", "S14", "D20"],
    ],
  ),
  "120": CheckoutRoute(
    primary: ["T20", "S20", "D20"],
    alts: [
      ["Bull", "Bull", "D20"],
    ],
  ),
  "119": CheckoutRoute(primary: ["T19", "T18", "D7"], alts: []),
  "118": CheckoutRoute(primary: ["T20", "T18", "D2"], alts: []),
  "117": CheckoutRoute(primary: ["T20", "T11", "D12"], alts: []),
  "116": CheckoutRoute(primary: ["T20", "T16", "D4"], alts: []),
  "115": CheckoutRoute(primary: ["T20", "T15", "D5"], alts: []),
  "114": CheckoutRoute(primary: ["T20", "T14", "D6"], alts: []),
  "113": CheckoutRoute(primary: ["T19", "T16", "D7"], alts: []),
  "112": CheckoutRoute(primary: ["T20", "T20", "D6"], alts: []),
  "111": CheckoutRoute(
    primary: ["T20", "S11", "D20"],
    alts: [
      ["Bull", "T20", "D16"],
    ],
  ),
  "110": CheckoutRoute(
    primary: ["T20", "D20"],
    alts: [
      ["Bull", "D20"],
    ],
  ),

  // === 109 ~ 90 ===
  "109": CheckoutRoute(primary: ["T19", "T18", "D7"], alts: []),
  "108": CheckoutRoute(primary: ["T20", "T16", "D6"], alts: []),
  "107": CheckoutRoute(primary: ["T19", "T16", "D7"], alts: []),
  "106": CheckoutRoute(primary: ["T20", "T14", "D2"], alts: []),
  "105": CheckoutRoute(primary: ["T20", "T13", "D3"], alts: []),
  "104": CheckoutRoute(primary: ["T20", "T12", "D4"], alts: []),
  "103": CheckoutRoute(primary: ["T19", "T16", "D3"], alts: []),
  "102": CheckoutRoute(primary: ["T20", "T14", "D2"], alts: []),
  "101": CheckoutRoute(
    primary: ["T20", "S13", "D20"],
    alts: [
      ["T17", "S18", "D20"],
    ],
  ),
  "100": CheckoutRoute(
    primary: ["T20", "D20"],
    alts: [
      ["S20", "S20", "D20"],
    ],
  ),
  "99": CheckoutRoute(primary: ["T19", "T18", "D3"], alts: []),
  "98": CheckoutRoute(
    primary: ["T20", "D19"],
    alts: [
      ["T18", "D12"],
    ],
  ),
  "97": CheckoutRoute(primary: ["T19", "D20"], alts: []),
  "96": CheckoutRoute(
    primary: ["T20", "D18"],
    alts: [
      ["S20", "S20", "D18"],
    ],
  ),
  "95": CheckoutRoute(primary: ["T19", "D19"], alts: []),
  "94": CheckoutRoute(primary: ["T20", "D17"], alts: []),
  "93": CheckoutRoute(primary: ["T19", "D18"], alts: []),
  "92": CheckoutRoute(primary: ["T20", "D16"], alts: []),
  "91": CheckoutRoute(primary: ["T17", "D20"], alts: []),
  "90": CheckoutRoute(
    primary: ["T20", "D15"],
    alts: [
      ["Bull", "D20"],
    ],
  ),

  // === 89 ~ 70 ===
  "89": CheckoutRoute(primary: ["T19", "D16"], alts: []),
  "88": CheckoutRoute(primary: ["T20", "D14"], alts: []),
  "87": CheckoutRoute(primary: ["T19", "D15"], alts: []),
  "86": CheckoutRoute(primary: ["T20", "D13"], alts: []),
  "85": CheckoutRoute(primary: ["T15", "D20"], alts: []),
  "84": CheckoutRoute(primary: ["T20", "D12"], alts: []),
  "83": CheckoutRoute(primary: ["T19", "D13"], alts: []),
  "82": CheckoutRoute(
    primary: ["T14", "D20"],
    alts: [
      ["Bull", "D16"],
    ],
  ),
  "81": CheckoutRoute(primary: ["T15", "D18"], alts: []),
  "80": CheckoutRoute(
    primary: ["T20", "D10"],
    alts: [
      ["S20", "D20"],
    ],
  ),
  "79": CheckoutRoute(primary: ["T19", "D11"], alts: []),
  "78": CheckoutRoute(primary: ["T18", "D12"], alts: []),
  "77": CheckoutRoute(primary: ["T19", "D10"], alts: []),
  "76": CheckoutRoute(primary: ["T16", "D14"], alts: []),
  "75": CheckoutRoute(primary: ["T15", "D15"], alts: []),
  "74": CheckoutRoute(
    primary: ["T14", "D16"],
    alts: [
      ["Bull", "D12"],
    ],
  ),
  "73": CheckoutRoute(primary: ["T19", "D8"], alts: []),
  "72": CheckoutRoute(primary: ["T16", "D12"], alts: []),
  "71": CheckoutRoute(primary: ["T13", "D16"], alts: []),
  "70": CheckoutRoute(
    primary: ["T20", "D5"],
    alts: [
      ["Bull", "D10"],
    ],
  ),

  // === 69 ~ 50 ===
  "69": CheckoutRoute(primary: ["T19", "D6"], alts: []),
  "68": CheckoutRoute(primary: ["T16", "D10"], alts: []),
  "67": CheckoutRoute(primary: ["T17", "D8"], alts: []),
  "66": CheckoutRoute(primary: ["T18", "D6"], alts: []),
  "65": CheckoutRoute(primary: ["T15", "D10"], alts: []),
  "64": CheckoutRoute(primary: ["T16", "D8"], alts: []),
  "63": CheckoutRoute(primary: ["T13", "D12"], alts: []),
  "62": CheckoutRoute(
    primary: ["T10", "D16"],
    alts: [
      ["S12", "Bull"],
    ],
  ),
  "61": CheckoutRoute(primary: ["T11", "D14"], alts: []),
  "60": CheckoutRoute(primary: ["S20", "D20"], alts: []),
  "59": CheckoutRoute(primary: ["T13", "D10"], alts: []),
  "58": CheckoutRoute(primary: ["S18", "D20"], alts: []),
  "57": CheckoutRoute(primary: ["S17", "D20"], alts: []),
  "56": CheckoutRoute(primary: ["S16", "D20"], alts: []),
  "55": CheckoutRoute(primary: ["S15", "D20"], alts: []),
  "54": CheckoutRoute(primary: ["S14", "D20"], alts: []),
  "53": CheckoutRoute(primary: ["S13", "D20"], alts: []),
  "52": CheckoutRoute(primary: ["S12", "D20"], alts: []),
  "51": CheckoutRoute(primary: ["S11", "D20"], alts: []),
  "50": CheckoutRoute(
    primary: ["Bull"],
    alts: [
      ["S10", "D20"],
    ],
  ),

  // === 49 ~ 30 ===
  "49": CheckoutRoute(primary: ["S9", "D20"], alts: []),
  "48": CheckoutRoute(primary: ["S8", "D20"], alts: []),
  "47": CheckoutRoute(primary: ["S7", "D20"], alts: []),
  "46": CheckoutRoute(primary: ["S6", "D20"], alts: []),
  "45": CheckoutRoute(primary: ["S5", "D20"], alts: []),
  "44": CheckoutRoute(primary: ["S4", "D20"], alts: []),
  "43": CheckoutRoute(primary: ["S3", "D20"], alts: []),
  "42": CheckoutRoute(primary: ["S10", "D16"], alts: []),
  "41": CheckoutRoute(primary: ["S1", "D20"], alts: []),
  "40": CheckoutRoute(primary: ["D20"], alts: []),
  "39": CheckoutRoute(primary: ["S7", "D16"], alts: []),
  "38": CheckoutRoute(primary: ["D19"], alts: []),
  "37": CheckoutRoute(primary: ["S5", "D16"], alts: []),
  "36": CheckoutRoute(primary: ["D18"], alts: []),
  "35": CheckoutRoute(primary: ["S3", "D16"], alts: []),
  "34": CheckoutRoute(primary: ["D17"], alts: []),
  "33": CheckoutRoute(primary: ["S1", "D16"], alts: []),
  "32": CheckoutRoute(primary: ["D16"], alts: []),
  "31": CheckoutRoute(primary: ["S15", "D8"], alts: []),
  "30": CheckoutRoute(primary: ["D15"], alts: []),

  // === 29 ~ 2 ===
  "29": CheckoutRoute(primary: ["S13", "D8"], alts: []),
  "28": CheckoutRoute(primary: ["D14"], alts: []),
  "27": CheckoutRoute(primary: ["S11", "D8"], alts: []),
  "26": CheckoutRoute(primary: ["D13"], alts: []),
  "25": CheckoutRoute(primary: ["S5", "D10"], alts: []),
  "24": CheckoutRoute(primary: ["D12"], alts: []),
  "23": CheckoutRoute(primary: ["S7", "D8"], alts: []),
  "22": CheckoutRoute(primary: ["D11"], alts: []),
  "21": CheckoutRoute(primary: ["S5", "D8"], alts: []),
  "20": CheckoutRoute(primary: ["D10"], alts: []),
  "19": CheckoutRoute(primary: ["S3", "D8"], alts: []),
  "18": CheckoutRoute(primary: ["D9"], alts: []),
  "17": CheckoutRoute(primary: ["S1", "D8"], alts: []),
  "16": CheckoutRoute(primary: ["D8"], alts: []),
  "15": CheckoutRoute(primary: ["S7", "D4"], alts: []),
  "14": CheckoutRoute(primary: ["D7"], alts: []),
  "13": CheckoutRoute(primary: ["S5", "D4"], alts: []),
  "12": CheckoutRoute(primary: ["D6"], alts: []),
  "11": CheckoutRoute(primary: ["S3", "D4"], alts: []),
  "10": CheckoutRoute(primary: ["D5"], alts: []),
  "9": CheckoutRoute(primary: ["S1", "D4"], alts: []),
  "8": CheckoutRoute(primary: ["D4"], alts: []),
  "7": CheckoutRoute(primary: ["S3", "D2"], alts: []),
  "6": CheckoutRoute(primary: ["D3"], alts: []),
  "5": CheckoutRoute(primary: ["S1", "D2"], alts: []),
  "4": CheckoutRoute(primary: ["D2"], alts: []),
  "3": CheckoutRoute(primary: ["S1", "D1"], alts: []),
  "2": CheckoutRoute(primary: ["D1"], alts: []),
};

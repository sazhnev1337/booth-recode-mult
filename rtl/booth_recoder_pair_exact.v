module booth_recoder_pair_exact (
    input  wire [4:0] window,   // {a[2k+3], a[2k+2], a[2k+1], a[2k], a[2k-1]}
    output wire       neg_lo,   // управление для позиции 2k
    output wire       one_lo,
    output wire       two_lo,
    output wire       neg_hi,   // управление для позиции 2k+1
    output wire       one_hi,
    output wire       two_hi
);

    // Распаковка окна для читаемости.
    wire a_m1 = window[0];  // a[2k-1]
    wire a_0  = window[1];  // a[2k]
    wire a_1  = window[2];  // a[2k+1]
    wire a_2  = window[3];  // a[2k+2]
    wire a_3  = window[4];  // a[2k+3]

    // Триплеты для обычного Booth.
    // Позиция 2k:   {a[2k+1], a[2k],   a[2k-1]} = {a_1, a_0, a_m1}
    // Позиция 2k+1: {a[2k+3], a[2k+2], a[2k+1]} = {a_3, a_2, a_1}
    wire [2:0] triplet_lo = {a_1, a_0, a_m1};
    wire [2:0] triplet_hi = {a_3, a_2, a_1};

    // Обычные Booth-кодировки для обеих позиций.
    wire neg_lo_raw = triplet_lo[2];
    wire one_lo_raw = triplet_lo[1] ^ triplet_lo[0];
    wire two_lo_raw = ( triplet_lo[2] & ~triplet_lo[1] & ~triplet_lo[0])
                    | (~triplet_lo[2] &  triplet_lo[1] &  triplet_lo[0]);

    wire neg_hi_raw = triplet_hi[2];
    wire one_hi_raw = triplet_hi[1] ^ triplet_hi[0];
    wire two_hi_raw = ( triplet_hi[2] & ~triplet_hi[1] & ~triplet_hi[0])
                    | (~triplet_hi[2] &  triplet_hi[1] &  triplet_hi[0]);

    // Детектор exact-паттерна на 5-битном подокне младшей позиции пары:
    // {a[2k+3], a[2k+2], a[2k+1], a[2k], a[2k-1]} == 00100 или 11011.
    wire pat_00100 = ~a_3 & ~a_2 &  a_1 & ~a_0 & ~a_m1;
    wire pat_11011 =  a_3 &  a_2 & ~a_1 &  a_0 &  a_m1;
    wire recode    = pat_00100 | pat_11011;

    // При срабатывании паттерна:
    //   позиция 2k   получает -M_lo (по формуле 8), |M_lo|=2  =>  neg = ~neg_lo_raw, two=1, one=0
    //   позиция 2k+1 получает 0    (по формуле 7)               =>  neg=0, one=0, two=0
    //
    // Замечание: оба паттерна 00100 и 11011 дают |M_lo|=2 (это видно из их триплетов
    // a_1 a_0 a_m1 = 100 и 011), так что флаг two_lo при срабатывании — единица,
    // а знак инвертируется относительно raw.

    assign neg_lo = recode ? ~neg_lo_raw : neg_lo_raw;
    assign one_lo = recode ? 1'b0        : one_lo_raw;
    assign two_lo = recode ? 1'b1        : two_lo_raw;

    assign neg_hi = recode ? 1'b0 : neg_hi_raw;
    assign one_hi = recode ? 1'b0 : one_hi_raw;
    assign two_hi = recode ? 1'b0 : two_hi_raw;

endmodule
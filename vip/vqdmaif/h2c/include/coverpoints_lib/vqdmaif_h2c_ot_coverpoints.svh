CP_H2C_OT_CNT      : coverpoint ot_cnt{
  bins ot_range[] = {[1:128]};
}
CP_H2C_OT_FULL     : coverpoint (cfg.max_ot == ot_cnt);

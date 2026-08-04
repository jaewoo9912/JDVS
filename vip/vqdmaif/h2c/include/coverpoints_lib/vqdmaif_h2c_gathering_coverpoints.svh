  CP_NUM_GATHERING_PKT : coverpoint h2c_trans.q_sub.size {
    // [HISTORY] Decided based on the use case as the following: (2025/5/E)
    //   - NRT project: number of max command per pkt: 66
    bins range[] = {[1:80]};
  }
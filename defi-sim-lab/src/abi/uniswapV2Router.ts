export const UNISWAP_V2_ROUTER_ABI = [
  {
    "type":"function",
    "stateMutability":"payable",
    "name":"swapExactETHForTokens",
    "inputs":[
      {"name":"amountOutMin","type":"uint256"},
      {"name":"path","type":"address[]"},
      {"name":"to","type":"address"},
      {"name":"deadline","type":"uint256"}
    ],
    "outputs":[{"name":"amounts","type":"uint256[]"}]
  }
] as const;

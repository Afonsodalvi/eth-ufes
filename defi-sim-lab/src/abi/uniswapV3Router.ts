export const UNISWAP_V3_SWAPROUTER_ABI = [
  {
    "type":"function",
    "name":"exactInputSingle",
    "stateMutability":"payable",
    "inputs":[
      {
        "name":"params",
        "type":"tuple",
        "components":[
          {"name":"tokenIn","type":"address"},
          {"name":"tokenOut","type":"address"},
          {"name":"fee","type":"uint24"},
          {"name":"recipient","type":"address"},
          {"name":"deadline","type":"uint256"},
          {"name":"amountIn","type":"uint256"},
          {"name":"amountOutMinimum","type":"uint256"},
          {"name":"sqrtPriceLimitX96","type":"uint160"}
        ]
      }
    ],
    "outputs":[{"name":"amountOut","type":"uint256"}]
  }
] as const;

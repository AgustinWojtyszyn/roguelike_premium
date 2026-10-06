class_name Pricing
extends RefCounted
## Configuracion central de precios futuros. NO hay billing real: `MOCK_PURCHASES` simula compras con aviso claro.

const PASS_PRICE_USD := 2.99
const MOCK_PURCHASES := true
const PASS_PRICE_LABEL := "US$ 2,99"
const GEM_PACKS: Array = [
	{"id": "gems_s", "gems": 80, "usd": 0.99},
	{"id": "gems_m", "gems": 450, "usd": 4.99},
	{"id": "gems_l", "gems": 1000, "usd": 9.99},
]

class_name CurrencyWallet
extends RefCounted
## Local test currencies (no real payments). Gold: circulating, earned in battle.
## Coupons: premium-like LOCAL test currency. Vouchers: bound, from quests/mail.

enum Currency { GOLD, COUPONS, VOUCHERS }

var gold: int = 0
var coupons: int = 0
var vouchers: int = 0


func balance(currency: Currency) -> int:
	match currency:
		Currency.COUPONS:
			return coupons
		Currency.VOUCHERS:
			return vouchers
	return gold


func can_afford(currency: Currency, amount: int) -> bool:
	return amount >= 0 and balance(currency) >= amount


func spend(currency: Currency, amount: int) -> bool:
	if not can_afford(currency, amount):
		return false
	add(currency, -amount)
	return true


func add(currency: Currency, amount: int) -> void:
	match currency:
		Currency.COUPONS:
			coupons += amount
		Currency.VOUCHERS:
			vouchers += amount
		_:
			gold += amount


static func currency_name(currency: Currency) -> String:
	return ["Gold", "Coupons", "Vouchers"][currency]


func to_dict() -> Dictionary:
	return {"gold": gold, "coupons": coupons, "vouchers": vouchers}


static func from_dict(data: Dictionary) -> CurrencyWallet:
	var wallet := CurrencyWallet.new()
	wallet.gold = DataReader.get_int(data, "gold")
	wallet.coupons = DataReader.get_int(data, "coupons")
	wallet.vouchers = DataReader.get_int(data, "vouchers")
	return wallet

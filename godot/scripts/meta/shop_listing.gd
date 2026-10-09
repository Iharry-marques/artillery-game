class_name ShopListing
extends RefCounted
## One shop offer (local test currencies only; no real payments).

enum Category { WEAPONS, CLOTHES, CONSUMABLES, MATERIALS }

var item_id: StringName
var category: Category
var currency: CurrencyWallet.Currency
var price: int
## Units received per purchase.
var quantity: int = 1


static func make(p_item_id: StringName, p_category: Category, p_currency: CurrencyWallet.Currency, p_price: int, p_quantity: int = 1) -> ShopListing:
	var listing := ShopListing.new()
	listing.item_id = p_item_id
	listing.category = p_category
	listing.currency = p_currency
	listing.price = p_price
	listing.quantity = p_quantity
	return listing


static func category_name(value: Category) -> String:
	return ["Weapons", "Clothes", "Battle Items", "Blacksmith"][value]

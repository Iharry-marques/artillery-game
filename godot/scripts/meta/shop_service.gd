class_name ShopService
extends RefCounted
## Local shop transactions (fake currencies only).


## Returns an error message, or "" on success.
static func buy(profile: PlayerProfile, content: ContentDatabase, listing: ShopListing, count: int = 1) -> String:
	var def: ItemDefinition = content.item(listing.item_id)
	if def == null or count <= 0:
		return "Unknown item"
	var total_price: int = listing.price * count
	var units: int = listing.quantity * count
	if not profile.wallet.can_afford(listing.currency, total_price):
		return "Not enough %s" % CurrencyWallet.currency_name(listing.currency)
	if not profile.inventory.can_add(def, units):
		return "The bag is full"
	profile.wallet.spend(listing.currency, total_price)
	profile.inventory.add(def, units, profile.uid_allocator())
	return ""


## Sells a Bag item (whole stack) to the NPC for gold. Returns gold received, or -1.
static func sell(profile: PlayerProfile, content: ContentDatabase, uid: int) -> int:
	var item: ItemInstance = profile.inventory.find(uid)
	if item == null:
		return -1
	var def: ItemDefinition = content.item(item.def_id)
	var gold: int = def.sell_gold * item.quantity
	profile.inventory.take(uid)
	profile.wallet.add(CurrencyWallet.Currency.GOLD, gold)
	return gold

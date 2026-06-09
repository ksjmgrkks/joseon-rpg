extends Node
##
## ShopManager autoload — 상점 매매 로직.
##
## buy(id, price)  : PlayerStats.spend_gold + Inventory.add 1개. 잔액 부족 시 false.
## sell(id, price) : Inventory.remove 1개 + PlayerStats.add_gold. 보유 없으면 false.
##
## 상점 진열은 ShopPanel UI 가 dialogue action 데이터로부터 받음 — 매니저는 거래만.
##

signal transaction(kind: String, item_id: String, ok: bool)


func buy(item_id: String, price: int) -> bool:
    if item_id == "" or price < 0:
        return false
    if not PlayerStats.spend_gold(price):
        transaction.emit("buy", item_id, false)
        return false
    Inventory.add(item_id, 1)
    transaction.emit("buy", item_id, true)
    return true


# 판매가는 호출자 책임(보통 정가의 절반).
func sell(item_id: String, price: int) -> bool:
    if item_id == "" or Inventory.count(item_id) <= 0:
        transaction.emit("sell", item_id, false)
        return false
    Inventory.remove(item_id, 1)
    PlayerStats.add_gold(maxi(0, price))
    transaction.emit("sell", item_id, true)
    return true

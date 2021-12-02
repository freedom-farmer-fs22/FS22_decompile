MoneyType = {}
local moneyTypeId = 0
local moneyTypeIdToType = {}

function MoneyType.getMoneyType(statistic, title)
	moneyTypeId = moneyTypeId + 1
	local value = {
		id = moneyTypeId,
		statistic = statistic,
		title = title
	}
	moneyTypeIdToType[moneyTypeId] = value

	return value
end

function MoneyType.getMoneyTypeById(id)
	return moneyTypeIdToType[id]
end

function MoneyType.getMoneyTypeByName(name)
	if name ~= nil then
		name = string.upper(name)

		return MoneyType[name]
	end

	return nil
end

function MoneyType.reset()
	moneyTypeId = MoneyType.LAST_ID
end

MoneyType.OTHER = MoneyType.getMoneyType("other", "finance_other")
MoneyType.SHOP_VEHICLE_BUY = MoneyType.getMoneyType("newVehiclesCost", "finance_newVehiclesCost")
MoneyType.SHOP_VEHICLE_SELL = MoneyType.getMoneyType("soldVehicles", "finance_soldVehicles")
MoneyType.SHOP_VEHICLE_LEASE = MoneyType.getMoneyType("newVehiclesCost", "finance_vehicleLeasingCost")
MoneyType.SHOP_PROPERTY_BUY = MoneyType.getMoneyType("constructionCost", "finance_constructionCost")
MoneyType.SHOP_PROPERTY_SELL = MoneyType.getMoneyType("soldBuildings", "finance_soldBuildings")
MoneyType.SOLD_MILK = MoneyType.getMoneyType("soldMilk", "finance_soldMilk")
MoneyType.HARVEST_INCOME = MoneyType.getMoneyType("harvestIncome", "finance_harvestIncome")
MoneyType.AI = MoneyType.getMoneyType("wagePayment", "finance_wagePayment")
MoneyType.MISSIONS = MoneyType.getMoneyType("missionIncome", "finance_missionIncome")
MoneyType.SOLD_ANIMALS = MoneyType.getMoneyType("soldAnimals", "finance_soldAnimals")
MoneyType.NEW_ANIMALS_COST = MoneyType.getMoneyType("newAnimalsCost", "finance_newAnimalsCost")
MoneyType.ANIMAL_UPKEEP = MoneyType.getMoneyType("animalUpkeep", "finance_animalUpkeep")
MoneyType.PURCHASE_SEEDS = MoneyType.getMoneyType("purchaseSeeds", "finance_purchaseSeeds")
MoneyType.PURCHASE_FERTILIZER = MoneyType.getMoneyType("purchaseFertilizer", "finance_purchaseFertilizer")
MoneyType.PURCHASE_FUEL = MoneyType.getMoneyType("purchaseFuel", "finance_purchaseFuel")
MoneyType.PURCHASE_SAPLINGS = MoneyType.getMoneyType("purchaseSaplings", "finance_purchaseSaplings")
MoneyType.FIELD_BUY = MoneyType.getMoneyType("fieldPurchase", "finance_fieldPurchase")
MoneyType.FIELD_SELL = MoneyType.getMoneyType("fieldSelling", "finance_fieldSelling")
MoneyType.LEASING_COSTS = MoneyType.getMoneyType("vehicleLeasingCost", "finance_vehicleLeasingCost")
MoneyType.LOAN_INTEREST = MoneyType.getMoneyType("loanInterest", "finance_loanInterest")
MoneyType.VEHICLE_RUNNING_COSTS = MoneyType.getMoneyType("vehicleRunningCost", "finance_vehicleRunningCost")
MoneyType.VEHICLE_REPAIR = MoneyType.getMoneyType("vehicleRunningCost", "finance_vehicleRunningCost")
MoneyType.PROPERTY_MAINTENANCE = MoneyType.getMoneyType("propertyMaintenance", "finance_propertyMaintenance")
MoneyType.PROPERTY_INCOME = MoneyType.getMoneyType("propertyIncome", "finance_propertyIncome")
MoneyType.LOAN = MoneyType.getMoneyType("loan", "finance_other")
MoneyType.PRODUCTION_COSTS = MoneyType.getMoneyType("productionCosts", "finance_productionCosts")
MoneyType.SOLD_PRODUCTS = MoneyType.getMoneyType("soldProducts", "finance_soldProducts")
MoneyType.INCOME_BGA = MoneyType.getMoneyType("incomeBga", "finance_incomeBga")
MoneyType.SOLD_WOOD = MoneyType.getMoneyType("soldWood", "finance_soldWood")
MoneyType.SOLD_BALES = MoneyType.getMoneyType("soldBales", "finance_soldBales")
MoneyType.BOUGHT_MATERIALS = MoneyType.getMoneyType("expenses", "finance_other")
MoneyType.TRANSFER = MoneyType.getMoneyType("other", "finance_transfer")
MoneyType.COLLECTIBLE = MoneyType.getMoneyType("other", "finance_collectible")
MoneyType.LAST_ID = moneyTypeId

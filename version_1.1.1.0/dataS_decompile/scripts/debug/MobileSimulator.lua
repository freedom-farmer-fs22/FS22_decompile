g_isMobileSimulationActive = false

if g_isMobileSimulationActive then
	print("--> Mobile Simulator active!")

	local isIAPLoaded = false
	local currentPurchase = nil
	local pendingPurchases = {
		1,
		3
	}
	local oldKeyEvent = keyEvent

	function keyEvent(unicode, sym, modifier, isDown)
		if isDown then
			if sym == Input.KEY_1 then
				log("!")
			elseif sym == Input.KEY_2 then
				log("Marking IAP as loaded...")

				isIAPLoaded = true
			elseif sym == Input.KEY_3 then
				log("Finishing IAP with FAILED...")
				handleNextPurchase(InAppPurchase.ERROR_FAILED)
			elseif sym == Input.KEY_4 then
				log("Finishing IAP with CANCELLED...")
				handleNextPurchase(InAppPurchase.ERROR_CANCELLED)
			elseif sym == Input.KEY_5 then
				log("Finishing IAP with IN PROGRESS...")
				handleNextPurchase(InAppPurchase.ERROR_PURCHASE_IN_PROGRESS)
			elseif sym == Input.KEY_6 then
				log("Finishing IAP with OK...")
				handleNextPurchase(InAppPurchase.ERROR_OK)
			elseif sym == Input.KEY_7 then
				log("Finishing IAP with NETWORK_UNAVAILABLE...")
				handleNextPurchase(InAppPurchase.ERROR_NETWORK_UNAVAILABLE)
			end
		end

		oldKeyEvent(unicode, sym, modifier, isDown)
	end

	function inAppInit(xmlFilename)
		log("[IAP] Loading IAP using", xmlFilename)

		isIAPLoaded = false
	end

	function inAppIsLoaded()
		log("[IAP] Testing if loaded")

		return isIAPLoaded
	end

	function inAppGetProductPrice(productId)
		log("[IAP] Getting price for", productId)

		return "$ " .. productId .. ".xx"
	end

	function inAppGetProductDescription(productId)
		log("[IAP] Getting description for", productId)

		return "PRODUCT " .. productId
	end

	function inAppStartPurchase(productId, completionHandler, callbackObject)
		log("[IAP] Starting purchase", productId, completionHandler, callbackObject)

		if currentPurchase ~= nil then
			callbackObject[completionHandler](callbackObject, InAppPurchase.ERROR_PURCHASE_IN_PROGRESS, productId)

			return
		end

		currentPurchase = {
			productId,
			completionHandler,
			callbackObject
		}
	end

	function inAppFinishPurchase(productId)
		log("[IAP] Finish purchase of", productId)
	end

	function handleNextPurchase(result)
		if currentPurchase ~= nil then
			log("[IAP] Finishing purchase", currentPurchase[1])
			currentPurchase[3][currentPurchase[2]](currentPurchase[3], result, currentPurchase[1])

			currentPurchase = nil
		end
	end

	function inAppGetNumPendingPurchases()
		log("[IAP] Get num pending purchases")

		return #pendingPurchases
	end

	function inAppGetPendingPurchaseProductId(index)
		log("[IAP] Get pending purchase product ID for", index)

		return pendingPurchases[index + 1]
	end

	function inAppFinishPendingPurchase(index)
		log("[IAP] Finish pending purchase for ", index)
		table.remove(pendingPurchases, index + 1)
	end
end

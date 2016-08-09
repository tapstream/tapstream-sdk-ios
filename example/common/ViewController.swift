//
//  ViewController.swift
//  example
//
//  Created by Adam Bard on 2016-05-13.
//  Copyright © 2016 Tapstream. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	// MARK: Properties

	@IBOutlet weak var exampleLog: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func logMessage(m: String) {

		self.exampleLog.text = m
	}

	@IBAction func generateConversion(sender: AnyObject) {
		let accountName = TSTapstream.instance().config.accountName
		let hitUrl = NSURL(string:String(format:"https://api.tapstream.com/%@/hit/", accountName))
		TSTapstream.instance().httpClient.request(hitUrl) { (response: TSResponse!) in
			if response == nil || response.failed() {
				self.logMessage("Could not create hit. Ensure Safari Services Framework is present and your default campaign\nredirects to an https url")
				return
			}
			let event = TSEvent(name:"exampleapp-test-event", oneTimeOnly:false)
			TSTapstream.instance().fireEvent(event)
			self.logMessage("Created conversion")
		}
	}

	@IBAction func fireEventWithCustomParams(sender: AnyObject) {

		let event = TSEvent(name:"event-with-custom-params", oneTimeOnly:false);
		event.addValue("some-value", forKey: "some-key")

		TSTapstream.instance().fireEvent(event);

		self.logMessage(String.init(format: "Event Fired: %@", event.name))
	}

	@IBAction func firePurchaseEvent(sender: AnyObject) {
		let event = TSEvent(transactionId: "my-transaction-id",
		                    productId: "my-product-id",
		                    quantity: 12,
		                    priceInCents: 1000,
		                    currency: "USD")
		TSTapstream.instance().fireEvent(event);
		self.logMessage(String.init(format: "Event Fired: %@", event.name))
	}
	@IBAction func firePurchaseEventNoPrice(sender: AnyObject) {
		let event = TSEvent(transactionId: "my-transaction-id",
		                    productId: "my-product-id",
		                    quantity: 12)
		TSTapstream.instance().fireEvent(event);
		self.logMessage(String.init(format: "Event Fired: %@", event.name))
	}

	@IBAction func lookupWOMRewards(sender: AnyObject) {
		self.logMessage("Fetching rewards...")
		let wom = TSTapstream.wordOfMouthController()
		wom.getRewardList { (response: TSRewardApiResponse!) in
			if response == nil || response.failed() {
				self.logMessage("Reward Request failed!")
				return
			}
			self.logMessage(String.init(format:"%d rewards retrieved", response.rewards.count))
			for reward in response.rewards {
				self.logMessage(String.init(format:"Reward: %@, %@", reward.insertionPoint, reward.sku))
			}
		}
	}

	@IBAction func testIAP(sender: AnyObject) {
		self.logMessage("Testing IAP")
	}

	@IBAction func lookupTimeline(sender: AnyObject) {
		self.logMessage("Fetching timeline...")
		TSTapstream.instance().lookupTimeline() { (response: TSTimelineApiResponse!) in
			if response == nil || response.failed() {
				self.logMessage("Timeline request failed!")
				return
			}

			if let event = response.events.last as? NSDictionary {
				if let tracker = event["tracker"] as? NSString {
					self.logMessage(String(format:"Hits: %d, Events: %d (Last Event: %@)",
						response.hits.count,
						response.events.count,
						tracker
					))
				}
			}

		}
	}

	@IBAction func lookupWOMOffer(sender: AnyObject) {
		self.logMessage("Fetching offer...")

		let wom = TSTapstream.wordOfMouthController()
		wom.getOfferForInsertionPoint("launch") { (resp: TSOfferApiResponse!) in
			if(resp == nil || resp.failed()) {
				self.logMessage("No offer retrieved!")
				return
			}
			let offer = resp.offer;
			wom.showOffer(offer, parentViewController: self)
			self.logMessage(String.init(format:"Offer retrieved (id=%d)", offer.ident))
		}
	}

	@IBAction func clearState(sender: AnyObject) {
		self.logMessage("")
		NSUserDefaults.standardUserDefaults().setPersistentDomain([:], forName: "__tapstream")

		let ts = TSTapstream.instance(), config = ts.config
		TSTapstream.createWithConfig(config)
		
	}

	@IBAction func testInAppLander(sender: AnyObject) {
		TSTapstream.instance().showLanderIfExistsWithDelegate(nil)
	}


}


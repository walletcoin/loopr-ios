//
//  Wallet.swift
//  loopr-ios
//
//  Created by xiaoruby on 2/17/18.
//  Copyright © 2018 Loopring. All rights reserved.
//

import Foundation

class AppWallet: NSObject, NSCoding {
    
    final let setupWalletMethod: SetupWalletMethod

    final let address: String
    final let privateKey: String

    // The password used to get the address and the private key when users use mnemonics and keystore.
    final var password: String
    final var mnemonics: [String]
    var keystoreString: String?

    // The wallet name in the app. Users can update later.
    var name: String

    // TODO: what is active for?
    var active: Bool

    var assetSequence: [String] = []
    var assetSequenceInHideSmallAssets: [String] = []
    
    init(setupWalletMethod: SetupWalletMethod, address: String, privateKey: String, password: String, mnemonics: [String] = [], keystoreString: String? = nil, name: String, active: Bool, assetSequence: [String] = ["ETH", "LRC"], assetSequenceInHideSmallAssets: [String] = ["ETH", "LRC"]) {
        self.setupWalletMethod = setupWalletMethod
        self.address = address
        self.privateKey = privateKey
        self.password = password
        self.mnemonics = mnemonics
        self.keystoreString = keystoreString
        self.name = name
        self.active = active
        self.assetSequence = assetSequence
        self.assetSequenceInHideSmallAssets = assetSequenceInHideSmallAssets
        
        super.init()
        
        if keystoreString == nil {
            generateKeystoreInBackground()
        }
    }
    
    // TODO: Not sure whether it's the best way to have getter and setter.
    func getAssetSequence() -> [String] {
        return assetSequence
    }

    func addAssetSequence(symbol: String) {
        if symbol.trim() != "" && !assetSequence.contains(symbol) {
            assetSequence.append(symbol)
        }
    }

    func getAssetSequenceInHideSmallAssets() -> [String] {
        return assetSequenceInHideSmallAssets
    }

    func addAssetSequenceInHideSmallAssets(symbol: String) {
        if symbol.trim() != "" {
            assetSequenceInHideSmallAssets.append(symbol)
        }
    }
    
    func generateKeystoreInBackground() {
        var password = self.password
        // Generating a keystore requires password.
        // However, importing a wallet using private key doesn't require password. Use a default password
        // Users won't export keystore
        if setupWalletMethod == .importUsingPrivateKey && password.trim() == "" {
            password = "123456"
        }
        
        // Generate keystore data
        DispatchQueue.global().async {
            guard let data = Data(hexString: self.privateKey) else {
                print("Invalid private key")
                return // .failure(KeystoreError.failedToImportPrivateKey)
            }
            do {
                let key = try KeystoreKey(password: password, key: data)
                let keystoreData = try JSONEncoder().encode(key)
                let json = try JSON(data: keystoreData)
                self.keystoreString = json.description
            } catch {
                print("Failed to generate keystore")
            }
        }
    }
    
    func getKeystore() -> String {
        return keystoreString ?? "Generating ..."
    }
    
    static func == (lhs: AppWallet, rhs: AppWallet) -> Bool {
        return lhs.address == rhs.address && lhs.privateKey == rhs.privateKey
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(setupWalletMethod.rawValue, forKey: "setupWalletMethod")
        aCoder.encode(password, forKey: "password")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(privateKey, forKey: "privateKey")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(active, forKey: "active")
        aCoder.encode(mnemonics, forKey: "mnemonics")
        aCoder.encode(keystoreString ?? "", forKey: "keystore")
        aCoder.encode(assetSequence, forKey: "assetSequence")
        aCoder.encode(assetSequenceInHideSmallAssets, forKey: "assetSequenceInHideSmallAssets")
    }

    required convenience init?(coder aDecoder: NSCoder) {
        let setupWalletMethodString = aDecoder.decodeObject(forKey: "setupWalletMethod") as? String ?? ""
        
        // If setupWalletMethod is null, the default value is importUsingPrivateKey
        let setupWalletMethod = SetupWalletMethod(rawValue: setupWalletMethodString) ?? SetupWalletMethod.importUsingPrivateKey
        
        let password = aDecoder.decodeObject(forKey: "password") as? String
        let address = aDecoder.decodeObject(forKey: "address") as? String
        let privateKey = aDecoder.decodeObject(forKey: "privateKey") as? String
        let name = aDecoder.decodeObject(forKey: "name") as? String
        let active = aDecoder.decodeBool(forKey: "active")

        // TODO: mnemonics vs. mnemonic
        let mnemonics = aDecoder.decodeObject(forKey: "mnemonics") as? [String]
        let assetSequence = aDecoder.decodeObject(forKey: "assetSequence") as? [String] ?? []
        let filteredAssetSequence = assetSequence.filter { (item) -> Bool in
            return item.trim() != ""
        }
        
        let keystoreString = aDecoder.decodeObject(forKey: "keystore") as? String
        
        let assetSequenceInHideSmallAssets = aDecoder.decodeObject(forKey: "assetSequenceInHideSmallAssets") as? [String] ?? []
        let filteredAssetSequenceInHideSmallAssets = assetSequenceInHideSmallAssets.filter { (item) -> Bool in
            return item.trim() != ""
        }
        
        if let address = address, let privateKey = privateKey, let password = password, let mnemonics = mnemonics, let name = name {
            self.init(setupWalletMethod: setupWalletMethod, address: address, privateKey: privateKey, password: password, mnemonics: mnemonics, keystoreString: keystoreString, name: name, active: active, assetSequence: unique(filteredAssetSequence), assetSequenceInHideSmallAssets: unique(filteredAssetSequenceInHideSmallAssets))
        } else {
            return nil
        }
    }
}

//
//  ViewController.swift
//  AppKeychainAccess
//
//  Created by Samiran Saha on 17/11/21.
//

import UIKit

class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var loginToApp: UIButton!
    
    @IBOutlet weak var fetchAppCredsFromKeychain: UIButton!
    
    
    @IBOutlet weak var textViewKeychain: UITextView!
    
    
    @IBOutlet weak var logoutButton: UIButton!
    
    var addQuery: [String: Any] = [:];
    var retrieveQuery: [String: Any] = [:];
    var deleteQuery: [String: Any] = [:];
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        cleanUpKeyChainOnReinstall();
        retrieveKeyChainItem(query: retrieveQuery);
        
        
    }
    
    func cleanUpKeyChainOnReinstall() {
        
        initApp();
        let userDefaults = UserDefaults.standard

        if !userDefaults.bool(forKey: "hasRunBefore") {
             // Remove Keychain items here
            deleteKeyChainItem(query: deleteQuery);
            
             // Update the flag indicator
             userDefaults.set(true, forKey: "hasRunBefore")
        }

    }
    
    func initApp() {
        var server: String = "";
        var credentials: Credentials;
        server = "www.example.com"
        credentials = Credentials(username: "helloUser", password: "helloPassword")
        let account = credentials.username
        let password = credentials.password.data(using: String.Encoding.utf8)!
        
        addQuery = [kSecClass as String: kSecClassInternetPassword,
                    kSecAttrAccount as String: account,
                    kSecAttrServer as String: server,
                    kSecValueData as String: password]
        
        retrieveQuery = [kSecClass as String: kSecClassInternetPassword,
                         kSecAttrServer as String: server,
                         kSecMatchLimit as String: kSecMatchLimitOne,
                         kSecReturnAttributes as String: true,
                         kSecReturnData as String: true]
        
        deleteQuery = [kSecClass as String: kSecClassInternetPassword,
        kSecAttrServer as String: server]
        
        
    }
    
    func deleteKeyChainItem(query: Any) {
        
        do {
            
            let status = SecItemDelete(query as! CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
            
            
            textViewKeychain.text = "Logged out successfully!";
            
            
        } catch let error {
            print(error.localizedDescription)
            textViewKeychain.text = "Error: \(error.localizedDescription)";
        }
        
        
    }
    
    func retrieveKeyChainItem(query: Any) {
        do {
            
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as! CFDictionary, &item)
            guard status != errSecItemNotFound else { throw KeychainError.noPassword }
            guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
            
            guard let existingItem = item as? [String : Any],
                  let passwordData = existingItem[kSecValueData as String] as? Data,
                  let password = String(data: passwordData, encoding: String.Encoding.utf8),
                  let account = existingItem[kSecAttrAccount as String] as? String
            else {
                throw KeychainError.unexpectedPasswordData
            }
            
            let credentials2 = Credentials(username: account, password: password)
            
            print("Credentials: \(credentials2)")
            textViewKeychain.text = "Credentials: \(credentials2)";
            
            
            
        } catch let error {
            print(error.localizedDescription)
            textViewKeychain.text = "Error: \(error.localizedDescription)";
        }
    }
    
    func addKeyChainItem(query: Any) {
        
        do {
            
            let status = SecItemAdd(query as! CFDictionary, nil)
            guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
            print("Status of keychain getting added: \(status)")
            
            textViewKeychain.text = "Logged in successfully!";
            
        } catch let error {
            print(error.localizedDescription)
            textViewKeychain.text = "Error: \(error.localizedDescription)";
        }
    }
    
    @IBAction func onClickLogin(_ sender: Any) {
        
        addKeyChainItem(query: addQuery);
        
    }
    
    @IBAction func printAppCreds(_ sender: Any) {
        retrieveKeyChainItem(query: retrieveQuery);
        
        
    }
    
    @IBAction func onClickLogout(_ sender: Any) {
        deleteKeyChainItem(query: deleteQuery);
    }
    
    
}

struct Credentials {
    var username: String
    var password: String
}


enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

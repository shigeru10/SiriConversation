//
//  AppDelegate.swift
//  SiriConversation
//
//  Created by SuzukiShigeru on 2017/08/16.
//  Copyright © 2017年 Shigeru Suzuki. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        csvToArray()
        
        return true
    }
    
    func csvToArray() {
        if let csvPath = Bundle.main.path(forResource: "words", ofType: "csv") {
            do {
                let data = loadCsvDataFromPath(csvPath)
                let realm = try Realm()
                
                guard let _data = data else { return }
                guard realm.objects(Word.self).count == 0 else { return }
                
                let words = realm.objects(Word.self)
                words.forEach { word in
                    do {
                        try realm.write {
                            realm.delete(word)
                        }
                    } catch {
                        fatalError("Could not delete word data")
                    }
                }
                
                for datum in _data {
                    let word = Word()
                    word.id = Int(datum["id"]!)!
                    word.answer = datum["answer"]!
                    word.question = datum["question"]!
                    
                    try realm.write() {
                        realm.add(word)
                    }
                }
            } catch {
                fatalError("Could not get csvArr")
            }
        }
    }
    
    func loadCsvDataFromPath(_ path:String) -> [[String:String]]? {
        guard let data:Data = try? Data(contentsOf: URL(fileURLWithPath: path)), let csv:String = String(data: data, encoding: String.Encoding.utf8) else { return nil }
        
        var dics:[[String:String]] = []
        var columns:[String] = []
        csv.enumerateLines(invoking: { (line, stop) -> () in
            let elements:[String] = line.components(separatedBy: ",")
            if columns == [] {
                columns = elements
            } else {
                var dic:[String:String] = [:]
                for object in elements.enumerated() {
                    dic[columns[object.offset]] = object.element
                }
                dics.append(dic)
            }
        })
        
        return dics
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


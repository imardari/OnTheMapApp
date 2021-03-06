//
//  UdacityCLient.swift
//  OnTheMap
//
//  Created by Ion M on 5/28/18.
//  Copyright © 2018 Ion M. All rights reserved.
//

import UIKit

class UdacityClient {
    
    // MARK: Properties
    var AccountKey : String?
    var SessionID : String?
    
    // MARK: Shared instance
    class func sharedInstance() -> UdacityClient {
        struct Singleton {
            static var sharedInstance = UdacityClient()
        }
        return Singleton.sharedInstance
    }
    
    // Udacity login
    func performUdacityLogin(_ email: String,
                             _ password: String,
                             completionHandlerLogin: @escaping (_ error: NSError?)
        -> Void) {
        
        let request = NSMutableURLRequest(url: URL(string: Constants.AuthorizationURL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\": {\"username\": \"\(email)\", \"password\": \"\(password)\"}}".data(using: String.Encoding.utf8)
        
        let _ = performRequest(request: request) { (parsedResult, error) in
            /* Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerLogin(error)
            } else {
                /* GUARD: Is the key Account in our result? */
                guard let accountDictionary = parsedResult?[UdacityClient.UdacityAccountKeys.Account] as? [String:AnyObject] else {
                    return
                }
                
                /* GUARD: Is the key Registered in our result? */
                guard let registered = accountDictionary[UdacityClient.UdacityAccountKeys.Registered] as? Bool else {
                    return
                }
                
                /* GUARD: Is the key Key in our result? */
                guard let accountKey = accountDictionary[UdacityClient.UdacityAccountKeys.Key] as? String else {
                    return
                }
                
                /* GUARD: Is the key Session in our result? */
                guard let sessionDictionary = parsedResult?[UdacityClient.SessionKeys.Session] as? [String:AnyObject] else {
                    return
                }
                
                /* GUARD: Is the key ID in our result? */
                guard let sessionID = sessionDictionary[UdacityClient.SessionKeys.ID] as? String else {
                    return
                }
                
                // Login if account is registered.
                if registered {
                    self.AccountKey = accountKey
                    self.SessionID = sessionID
                    completionHandlerLogin(nil)
                }
                else {
                    let errorMsg = "Account is not registered"
                    let userInfo = [NSLocalizedDescriptionKey : errorMsg]
                    completionHandlerLogin(NSError(domain: errorMsg, code: 2, userInfo: userInfo))
                }
            }
        }
    }
    
    // Udacity logout
    func performUdacityLogout(completionHandlerLogout: @escaping (_ error: NSError?) -> Void) {
        let request = NSMutableURLRequest(url: URL(string: Constants.AuthorizationURL)!)
        request.httpMethod = "DELETE"
        var xsrfCookie: HTTPCookie? = nil
        let sharedCookieStorage = HTTPCookieStorage.shared
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        
        let _ = performRequest(request: request) { (parsedResult, error) in
            /* Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerLogout(error)
            } else {
                /* GUARD: Is the key Session in our result? */
                guard let sessionDictionary = parsedResult?[UdacityClient.SessionKeys.Session] as? [String:AnyObject] else {
                    return
                }
                
                /* GUARD: Is the key ID in our result? */
                guard let logoutSessionID = sessionDictionary[UdacityClient.SessionKeys.ID] as? String else {
                    return
                }
                
                // Make sure the session ID is the same as the one when we loginr
                if (logoutSessionID == self.SessionID!) {
                    completionHandlerLogout(nil)
                }
                else {
                    let errorMsg = "Difference session ID"
                    let userInfo = [NSLocalizedDescriptionKey : errorMsg]
                    completionHandlerLogout(NSError(domain: errorMsg, code: 3, userInfo: userInfo))
                }
            }
        }
    }
    
    // FB Login
    func performFacebookLogin(_ fbAccessToken: String,
                              completionHandlerFBLogin: @escaping (_ error: NSError?)
        -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let request = NSMutableURLRequest(url: URL(string: Constants.AuthorizationURL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"facebook_mobile\": {\"access_token\": \"\(fbAccessToken)\"}}".data(using: String.Encoding.utf8)
        
        let _ = performRequest(request: request) { (parsedResult, error) in
            
            /* Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerFBLogin(error)
            } else {
                
                /* GUARD: Is the key Account in our result? */
                guard let accountDictionary = parsedResult?[UdacityClient.UdacityAccountKeys.Account] as? [String:AnyObject] else {
                    return
                }
                
                /* GUARD: Is the key Registered in our result? */
                guard let registered = accountDictionary[UdacityClient.UdacityAccountKeys.Registered] as? Bool else {
                    return
                }
                
                /* GUARD: Is the key Key in our result? */
                guard let accountKey = accountDictionary[UdacityClient.UdacityAccountKeys.Key] as? String else {
                    return
                }
                
                /* GUARD: Is the key Session in our result? */
                guard let sessionDictionary = parsedResult?[UdacityClient.SessionKeys.Session] as? [String:AnyObject] else {
                    return
                }
                
                /* GUARD: Is the key ID in our result? */
                guard let sessionID = sessionDictionary[UdacityClient.SessionKeys.ID] as? String else {
                    return
                }
                
                // Login if the account is registered
                if registered {
                    self.AccountKey = accountKey
                    self.SessionID = sessionID
                    completionHandlerFBLogin(nil)
                }
                else {
                    let errorMsg = "Account is not registered"
                    let userInfo = [NSLocalizedDescriptionKey : errorMsg]
                    completionHandlerFBLogin(NSError(domain: errorMsg, code: 2, userInfo: userInfo))
                }
            }
        }
    }
    
    private func performRequest(request: NSMutableURLRequest,
                                completionHandlerRequest: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void)
        -> URLSessionDataTask {
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                
                func displayError(_ error: String) {
                    print(error)
                    let userInfo = [NSLocalizedDescriptionKey : error]
                    completionHandlerRequest(nil, NSError(domain: "performRequest", code: 1, userInfo: userInfo))
                }
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    displayError("There was an error with your request. Please check internet connection.")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    let httpError = (response as? HTTPURLResponse)?.statusCode
                    if httpError == 403 {
                        displayError("Invalid login or password")
                    }
                    else {
                        displayError("Your request returned a status code: \(String(describing: httpError))")
                    }
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    displayError("No data was returned by the request!")
                    return
                }
                
                let range = Range(5..<data.count)
                let newData = data.subdata(in: range) /* subset response data! */
                self.convertDataWithCompletionHandler(newData, completionHandlerConvertData: completionHandlerRequest)
            }
            task.resume()
            return task
    }
    
    // Convert raw JSON
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        completionHandlerConvertData(parsedResult, nil)
    }
}

//
//  PKCS12.swift
//  TestSwiftyDocker
//
//  Created by Helge Hess on 07/05/15.
//  Copyright (c) 2015 Helge Hess. All rights reserved.
//

import Foundation

// https://developer.apple.com/library/mac/documentation/Security/Reference/certifkeytrustservices/index.html#//apple_ref/c/func/SecTrustGetTrustResult

public struct PKCS12Item: Printable {
  
  let storage : NSDictionary
  
  init(_ storage: NSDictionary) {
    self.storage = storage
  }
  
  public var keyID : NSData? {
    // Typically a SHA-1 digest of the public key
    return storage.secValueForKey(kSecImportItemKeyID)
  }
  public var label : String? {
    return storage.secValueForKey(kSecImportItemLabel)
  }
  
  public var identity : SecIdentity? {
    return storage.secValueForKey(kSecImportItemIdentity)
  }
  public var trust : SecTrust? {
    return storage.secValueForKey(kSecImportItemTrust)
  }
  
  public var certificateChain : [ SecCertificate ]? {
    return storage.secValueForKey(kSecImportItemCertChain)
  }
}

extension PKCS12Item: Printable {
  
  public var description: String {
    var s = "<PKCS12Item:"
    
    if let v = keyID    { s += " id=\(v)" }
    if let v = label    { s += " '\(v)'"  }
    if let v = identity { s += " \(v)"    }
    if let v = trust    { s += " \(v)"    }
    
    if let v = certificateChain {
      s += " certs["
      var isFirst = true
      for cert in v {
        if isFirst { isFirst = false } else { s += ", " }
        s += "\(cert)"
      }
      s += "]"
    }
    
    s += ">"
    return s
  }
}

// PKCS12 is just a wrapper of items
public typealias PKCS12 = [ PKCS12Item ]

public func ImportPKCS12(data: NSData, options: [ String : String ]? = nil)
  -> PKCS12?
{
  var keyref : Unmanaged<CFArray>?
  
  let importStatus = SecPKCS12Import(data, options, &keyref);
  if importStatus != noErr || keyref == nil {
    println("PKCS#12 import failed: \(importStatus)")
    return nil
  }
  
  let items = keyref!.takeRetainedValue() as NSArray
  return map(items) { PKCS12Item($0 as! NSDictionary) }
}

public func ImportPKCS12(path: String, password: String) -> PKCS12? {
  let data = NSData(contentsOfFile: path)
  if data == nil { return nil }
  
  let options = [
    String(kSecImportExportPassphrase.takeUnretainedValue()) : password
  ]
  return ImportPKCS12(data!, options: options)
}

extension NSDictionary {
  
  func secValueForKey<T>(key: Unmanaged<CFString>!) -> T? {
    let key = String(key.takeUnretainedValue())
    let v   : AnyObject? = self[key]
    if let vv : AnyObject = v { return (vv as! T)}
    return nil
  }
  
}

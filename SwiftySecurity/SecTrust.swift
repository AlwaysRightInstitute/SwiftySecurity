//
//  SecTrust.swift
//  TestSwiftyDocker
//
//  Created by Helge Hess on 08/05/15.
//  Copyright (c) 2015 Helge Hess. All rights reserved.
//

import Foundation

// Note: a trust seems to be more like an evaluation context
public extension SecTrust {
  
  public var count : Int {
    return SecTrustGetCertificateCount(self)
  }
  
  public subscript(index: Int) -> SecCertificate? {
    // Swift.Unmanaged<ObjectiveC.SecCertificate>
    // TBD: is unretained OK? (Get = Retained or not? :-)
    return SecTrustGetCertificateAtIndex(self, index).takeUnretainedValue()
  }
  
  
  /* anchor certs */

  public var anchorCertificates : [ SecCertificate ] {
    set {
      setAnchorCertificates(newValue)
    }
    get {
      var valueCopy : Unmanaged<CFArray>?
      let status = SecTrustCopyCustomAnchorCertificates(self, &valueCopy)
      if valueCopy == nil { return [] }
      return valueCopy!.takeRetainedValue() as! [ SecCertificate ]
    }
  }
  
  public var trustOwnCertificatesOnly : Bool? {
    set {
      let v : Boolean = (newValue ?? false) ? 1 : 0
      let status = SecTrustSetAnchorCertificatesOnly(self, v)
    }
    get {
      return nil // there is no getter for this?
    }
  }
  
  public func setAnchorCertificates(certificates: SecCertificate...)
           -> OSStatus
  {
    return setAnchorCertificates(certificates)
  }
  public func setAnchorCertificates(certificates: [ SecCertificate ])
           -> OSStatus
  {
    return SecTrustSetAnchorCertificates(self, certificates)
  }
  
  public static var anchorCertificates : [ SecCertificate ] {
    // those are the system certificates
    var valueCopy : Unmanaged<CFArray>?
    let status = SecTrustCopyAnchorCertificates(&valueCopy)
    if valueCopy == nil { return [] }
    return valueCopy!.takeRetainedValue() as! [ SecCertificate ]
  }
  
  
  /* evaluation */
  
  public func evaluate() -> ( OSStatus, SecTrustResultType ) {
    var result : SecTrustResultType = 0
    let status = SecTrustEvaluate(self, &result)
    return ( status, result )
  }
  
  public func evaluate(queue: dispatch_queue_t, cb: SecTrustCallback)
           -> OSStatus
  {
    return SecTrustEvaluateAsync(self, queue, cb)
  }
  
  public var lastResult : ( OSStatus, SecTrustResultType ) {
    var result : SecTrustResultType = 0
    let status = SecTrustGetTrustResult(self, &result)
    return ( status, result )
  }
  
  
  /* keys */
  
  public var publicKey : SecKey? {
    let valueCopy = SecTrustCopyPublicKey(self)
    return valueCopy != nil ? valueCopy!.takeRetainedValue() : nil
  }
  
  
  /* times */
  
  public var verifyTimestamp : CFAbsoluteTime {
    set {
      let newTime = CFDateCreate(nil, newValue)
      let status = SecTrustSetVerifyDate(self, newTime)
    }
    get {
      return SecTrustGetVerifyTime(self)
    }
  }
  
  public var verifyDate : CFDate {
    set {
      verifyTimestamp = CFDateGetAbsoluteTime(newValue)
    }
    get {
      return CFDateCreate(nil, verifyTimestamp)
    }
  }
}
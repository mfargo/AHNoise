//
//  AHNModifierStep.swift
//  AHNoise
//
//  Created by Andrew Heard on 24/02/2016.
//  Copyright © 2016 Andrew Heard. All rights reserved.
//


import Metal
import simd


/**
 Takes the outputs of any class that adheres to the `AHNTextureProvider` protocol and maps values larger than the `boundary` value to the `highValue`, and those below to the `lowValue`.
 
 For example if a pixel has a value of `0.6`, the `boundary` is set to `0.5`, the `highValue` set to `0.7` and the `lowValue` set to `0.1`, the returned value will be `0.1`.
 
 The output of this module will always be greyscale as the output value is written to all three colour channels equally.
 
 *Conforms to the `AHNTextureProvider` protocol.*
 */
public class AHNModifierStep: AHNModifier{
  
  
  // MARK:- Properties
  
  var allowableControls: [String] = ["lowValue", "highValue", "boundary"]
  
  
  
  
  
  ///The low value (default value is `0.0`) to output if the noise value is lower than the `boundary`.
  public var lowValue: Float = 0{
    didSet{
      dirty = true
    }
  }

  
  
  ///The hight value (default value is `1.0`) to output if the noise value is higher than the `boundary`.
  public var highValue: Float = 1{
    didSet{
      dirty = true
    }
  }

  
  
  ///The value at which to perform the step. Texture values lower than this are returned as `lowValue` and those above are returned as `highValue`. The default value is `0.5`.
  public var boundary: Float = 0.5{
    didSet{
      dirty = true
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  // MARK:- Initialiser
  
  
  required public init(){
    super.init(functionName: "stepModifier")
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  // MARK:- Argument table update
  
  
  ///Encodes the required uniform values for this `AHNModifier` subclass. This should never be called directly.
  public override func configureArgumentTableWithCommandencoder(commandEncoder: MTLComputeCommandEncoder) {
    var uniforms = vector_float3(lowValue, highValue, boundary)
    
    if uniformBuffer == nil{
      uniformBuffer = context.device.newBufferWithLength(strideof(vector_float3), options: .CPUCacheModeDefaultCache)
    }
    
    memcpy(uniformBuffer!.contents(), &uniforms, strideof(vector_float3))
    
    commandEncoder.setBuffer(uniformBuffer, offset: 0, atIndex: 0)
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  // MARK:- NSCoding
  public func encodeWithCoder(aCoder: NSCoder) {
    var mirror = Mirror(reflecting: self)
    repeat{
      for child in mirror.children{
        if allowableControls.contains(child.label!){
          if child.value is Int{
            aCoder.encodeInteger(child.value as! Int, forKey: child.label!)
          }
          if child.value is Float{
            aCoder.encodeFloat(child.value as! Float, forKey: child.label!)
          }
          if child.value is Bool{
            aCoder.encodeBool(child.value as! Bool, forKey: child.label!)
          }
        }
      }
      mirror = mirror.superclassMirror()!
    }while String(mirror.subjectType).hasPrefix("AHN")
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(functionName: "stepModifier")
    var mirror = Mirror(reflecting: self.dynamicType.init())
    repeat{
      for child in mirror.children{
        if allowableControls.contains(child.label!){
          if child.value is Int{
            let val = aDecoder.decodeIntegerForKey(child.label!)
            setValue(val, forKey: child.label!)
          }
          if child.value is Float{
            let val = aDecoder.decodeFloatForKey(child.label!)
            setValue(val, forKey: child.label!)
          }
          if child.value is Bool{
            let val = aDecoder.decodeBoolForKey(child.label!)
            setValue(val, forKey: child.label!)
          }
        }
      }
      mirror = mirror.superclassMirror()!
    }while String(mirror.subjectType).hasPrefix("AHN")
  }
}
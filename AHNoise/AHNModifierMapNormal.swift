//
//  AHNModifierNormalMap.swift
//  AHNoise
//
//  Created by Andrew Heard on 26/02/2016.
//  Copyright © 2016 Andrew Heard. All rights reserved.
//


import Metal
import SpriteKit
import MetalKit


/**
 Takes the outputs of any class that adheres to the `AHNTextureProvider` protocol and creates a normal map for it.
 
 The input pixels are analysed to detect colour variations that are interpreted as gradients, these gradients are then converted into a normal map for use in 3D lighting.
 
 *Conforms to the `AHNTextureProvider` protocol.*
 */
public class AHNModifierMapNormal: NSObject, AHNTextureProvider {
  
  var allowableControls: [String] = ["intensity", "smoothing"]

  
  // MARK:- Properties
  
  
  ///A value that magnifies the effect of the generated normal map. The default value of `1.0` indicates no magnification.
  public var intensity: Float = 1.0{
    didSet{
      dirty = true
    }
  }
  

  
  ///A value in teh range `0.0 - 1.0` indicating how much the input should be smoothed before the normal map is generated. The default value is `0.0`.
  public var smoothing: Float = 0{
    didSet{
      dirty = true
    }
  }
  
  
  
  ///The `AHNContext` that is being used by the `AHNTextureProvider` to communicate with the GPU. This is recovered from the first `AHNGenerator` class that is encountered in the chain of classes.
  public var context: AHNContext
  
  
  
  ///The `MTLTexture` that the compute kernel writes to as an output.
  var internalTexture: MTLTexture?
  
  
  
  ///Indicates whether or not the `internalTexture` needs updating.
  public var dirty: Bool = true
  
  
  
  ///The input that will be used to generator the normal map.
  var provider: AHNTextureProvider?
  
  
  
  /**
   The width of the output `MTLTexure`.
   
   This is dictated by the width of the texture of the input `AHNTextureProvider`. If there is no input, the default width is `128` pixels.
   */
  public var textureWidth: Int{
    get{
      return provider?.textureSize().width ?? 128
    }
  }
  
  
  
  /**
   The height of the output `MTLTexure`.
   
   This is dictated by the height of the texture of the input `AHNTextureProvider`. If there is no input, the default height is `128` pixels.
   */
  public var textureHeight: Int{
    get{
      return provider?.textureSize().height ?? 128
    }
  }

  public var modName: String = ""
  
  
  
  
  
  
  
  
  
  // MARK:- Initialiser
  
  
  override public required init(){
    context = AHNContext.SharedContext
    super.init()
  }
  
  
  
  
  
  
  
  

  
  
  
  
  
  
  // MARK:- Texture Functions
  
  
  /**
   Updates the output `MTLTexture`.
   
   This should not need to be called manually as it is called by the `texture()` method automatically if the texture does not represent the current `AHNTextureProvider` properties.
   */
  public func updateTexture(){
    if provider == nil {return}
    
    if internalTexture == nil{
      newInternalTexture()
    }
    if internalTexture!.width != textureWidth || internalTexture!.height != textureHeight{
      newInternalTexture()
    }
    
    
    guard var image = provider?.uiImage() else { return }
    guard var ciImage = CIImage(image: image) else { return }
    ciImage = ciImage.imageByApplyingTransform(CGAffineTransformMakeScale(1, -1))
    let ciContext = CIContext(options: nil)
    image = UIImage(CGImage: ciContext.createCGImage(ciImage, fromRect: ciImage.extent))
    
    let sprite = SKTexture(image: image)
    
    let normal = sprite.textureByGeneratingNormalMapWithSmoothness(CGFloat(smoothing), contrast: CGFloat(intensity))
    let loader = MTKTextureLoader(device: context.device)
    do{
      try internalTexture = loader.newTextureWithCGImage(normal.CGImage(), options: nil)
    }catch{
      fatalError()
    }
    dirty = false
  }
  
  
  
  ///Create a new `internalTexture` for the first time or whenever the texture is resized.
  func newInternalTexture(){
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: textureWidth, height: textureHeight, mipmapped: false)
    internalTexture = context.device.newTextureWithDescriptor(textureDescriptor)
  }
  
  
  
  ///- returns: The updated output `MTLTexture` for this module.
  public func texture() -> MTLTexture?{
    if isDirty(){
      updateTexture()
    }
    return internalTexture
  }
  
  
  
  ///- returns: The MTLSize of the the output `MTLTexture`. If no size has been explicitly set, the default value returned is `128x128` pixels.
  public func textureSize() -> MTLSize{
    return MTLSizeMake(textureWidth, textureHeight, 1)
  }
  
  
  
  ///- returns: The input `AHNTextureProvider` that provides the input `MTLTexture` to the `AHNModifier`. This is taken from the `input`. If there is no `input`, returns `nil`.
  public func textureProvider() -> AHNTextureProvider?{
    return provider
  }
  
  
  
  ///- returns: `False` if the input and the `internalTexture` do not need updating.
  public func isDirty() -> Bool {
    if let p = provider{
      return p.isDirty() || dirty
    }else{
      return dirty
    }
  }
  
  
  
  ///- returns: `False` if the `provider` property is not set.
  public func canUpdate() -> Bool {
    return provider != nil
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
    context = AHNContext.SharedContext

    super.init()
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
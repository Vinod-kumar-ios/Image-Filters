//
//  FilmGrain.swift
//  XMP_On_Image
//
//  Created by Vinod Kumar on 28/06/20.
//  Copyright © 2020 Vinod Kumar. All rights reserved.
//

import UIKit

class FilmGrain: CIFilter {
    let fname = "Film Grain"
   @objc dynamic var inputImage: CIImage?
    var inputAmount: CGFloat = 0.5
    var inputSize: CGFloat = 0.5
    var noiseImage:CIImage!
    
    
    // filters used to create effect. Static so that they can be re-used across instances
    private static var noiseFilter: CIFilter?  = nil
    private static var whiteningFilter: CIFilter?  = nil
    private static var darkeningFilter: CIFilter?  = nil
    private static var grayscaleFilter: CIFilter?  = nil
    private static var opacityFilter: CIFilter?  = nil
    private static var compositingFilter: CIFilter?  = nil
    private static var multiplyFilter: CIFilter?  = nil
    
    
    
  
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputAmount = 0.5
        inputSize = 0.5
    }
    
    
    // filter display name
    func displayName() -> String {
        return fname
    }
    
    private func checkFilters() {
        if FilmGrain.noiseFilter == nil {
            FilmGrain.noiseFilter = CIFilter(name: "CIRandomGenerator")
            FilmGrain.whiteningFilter = CIFilter(name: "CIColorMatrix")
            FilmGrain.darkeningFilter = CIFilter(name: "CIColorMatrix")
            FilmGrain.compositingFilter = CIFilter(name: "CISourceOverCompositing")
            FilmGrain.grayscaleFilter = CIFilter(name:"CIMinimumComponent")
            FilmGrain.multiplyFilter = CIFilter(name: "CIMultiplyCompositing")
            FilmGrain.opacityFilter = CIFilter(name: "OpacityFilter")
       }
    }
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputAmount": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.5,
                           kCIAttributeDisplayName: "Grain Amount",
                           kCIAttributeMin: 0.0,
                           kCIAttributeSliderMin: 0.0,
                           kCIAttributeSliderMax: 1.0,
                           kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputSize": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.5,
                           kCIAttributeDisplayName: "Grain Size",
                           kCIAttributeMin: 0.0,
                           kCIAttributeSliderMin: 0.0,
                           kCIAttributeSliderMax: 1.0,
                           kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputAmount":
            inputAmount = value as! CGFloat
        case "inputSize":
            inputSize = value as! CGFloat
        default:
            print("Invalid key: \(key)")
        }
    }

    dynamic override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            print("NIL image supplied")
            return nil
        }
        
        checkFilters()
        guard FilmGrain.noiseFilter != nil else {
            print("NIL noise filter")
            return inputImage
        }

        guard (inputAmount > 0.01) && (inputSize > 0.01) else { // don't bother applying
            return inputImage
        }
        
        // generate a noisy image
        let noiseImage = FilmGrain.noiseFilter?.outputImage?
            //.applyingFilter("ScatterFilter", parameters: ["inputScatterRadius": 25*inputSize])
            .cropped(to: inputImage.extent).clampedToExtent()
        
        guard noiseImage != nil else {
            print("NIL noise image")
            return inputImage
        }
        
        //return noiseImage // DEBUG: check intermediate result
        
        // Generate white speckles from the noise (scaling is empirical)
        let noiseSize = 0.001*inputSize
        let whitenVector = CIVector(x: 0, y: 1, z: 0, w: 0)
        //let whitenVector = CIVector(x: 0, y: inputAmount, z: 0, w: 0)
        let grainVector = CIVector(x:0, y:noiseSize, z:0, w:0)
        let zeroVector = CIVector(x: 0, y: 0, z: 0, w: 0)

        FilmGrain.whiteningFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        FilmGrain.whiteningFilter?.setValue(whitenVector, forKey: "inputRVector")
        FilmGrain.whiteningFilter?.setValue(whitenVector, forKey: "inputGVector")
        FilmGrain.whiteningFilter?.setValue(whitenVector, forKey: "inputBVector")
        FilmGrain.whiteningFilter?.setValue(grainVector, forKey: "inputAVector")
        FilmGrain.whiteningFilter?.setValue(zeroVector, forKey: "inputBiasVector")

        let whiteSpecks = FilmGrain.whiteningFilter?.outputImage?
            .applyingFilter("ScatterFilter", parameters: ["inputScatterRadius": 10*inputSize])
            .applyingFilter("BrightnessFilter", parameters: ["inputBrightness": min(-0.4, (inputAmount-1.0))])
            .applyingFilter("OpacityFilter", parameters: ["inputOpacity": 0.2*inputAmount])
            .cropped(to: inputImage.extent).clampedToExtent()
        guard whiteSpecks != nil else {
            print("NIL white specks image")
            return inputImage
        }
        
        //return whiteSpecks // DEBUG: check intermediate result
        
        // Blur the speckles a little
        //let blurredImage = whiteSpecks?.applyingFilter("CIBoxBlur", parameters: ["inputRadius": 2.0*inputSize]).cropped(to: inputImage.extent).clampedToExtent()
        //let blurredImage = whiteSpecks?.applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 2.0*inputSize]).cropped(to: inputImage.extent).clampedToExtent()

        let blurredImage = whiteSpecks
        //return blurredImage // DEBUG: check intermediate result

        /****/
        // generate 'faded' versions of the white speckles image
        let opacity = min(0.6, inputAmount)
        //let opacity = 0.2 // full intensity doesn't look good so scale it down a bit (empirical value)
        FilmGrain.opacityFilter?.setValue(opacity, forKey: "inputOpacity")
        FilmGrain.opacityFilter?.setValue(blurredImage, forKey: "inputImage")
        
        let fadedSpecksImage = FilmGrain.opacityFilter?.outputImage?.cropped(to: inputImage.extent).clampedToExtent()
        guard fadedSpecksImage != nil else {
            print("NIL faded speckles image")
            return inputImage
        }
        /***/


        //let fadedSpecksImage = blurredImage
        
        //return fadedSpecksImage // DEBUG: check intermediate result
        
       // overlay onto the original image - Overlay Blend Mode seems to work best
        //let overlayFilter = CIFilter(name:"CISourceOverCompositing")
        //let overlayFilter = CIFilter(name:"CIOverlayBlendMode")
        //let overlayFilter = CIFilter(name:"CISoftLightBlendMode")
        //let overlayFilter = CIFilter(name:"CIScreenBlendMode")
        let overlayFilter = CIFilter(name:"CILuminosityBlendMode")
        overlayFilter?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        overlayFilter?.setValue(fadedSpecksImage!, forKey: kCIInputImageKey)
        let speckledImage = overlayFilter?.outputImage?.cropped(to: inputImage.extent).clampedToExtent()
        guard speckledImage != nil else {
            print("NIL speckled image")
            return inputImage
        }

         //return speckledImage // DEBUG: check intermediate result

        /***/

        // generate dark scratches from the white speckled image
        //let verticalScale = CGAffineTransform(scaleX: 1.5, y: 25)
        let verticalScale = CGAffineTransform(scaleX: 1.0+inputSize, y: 1.5 + 5.0*(1.0+inputSize))
        let transformedNoise = noiseImage?.transformed(by: verticalScale)
        
        let darkenVector = CIVector(x: 4, y: 0, z: 0, w: 0)
        let darkenBias = CIVector(x: 0, y: 1, z: 1, w: 1)
        
        FilmGrain.darkeningFilter?.setValue(transformedNoise!, forKey: kCIInputImageKey)
        FilmGrain.darkeningFilter?.setValue(darkenVector, forKey: "inputRVector")
        FilmGrain.darkeningFilter?.setValue(zeroVector, forKey: "inputGVector")
        FilmGrain.darkeningFilter?.setValue(zeroVector, forKey: "inputBVector")
        FilmGrain.darkeningFilter?.setValue(zeroVector, forKey: "inputAVector")
        FilmGrain.darkeningFilter?.setValue(darkenBias, forKey: "inputBiasVector")

        let randomScratches =  FilmGrain.darkeningFilter?.outputImage?.cropped(to: inputImage.extent).clampedToExtent()
        guard randomScratches != nil else {
            print("NIL dark scratches image")
            return inputImage
        }

        // The resulting scratches are cyan-colored, so grayscale them using the CIMinimumComponentFilter, which takes the
        // minimum of the RGB values to produce a grayscale image.
        let darkScratches = randomScratches?.applyingFilter("CIMinimumComponent", parameters: [ kCIInputImageKey: randomScratches! ])
        
        //return darkScratches // DEBUG: check intermediate result

        /***
        FilmGrain.opacityFilter?.setValue(darkScratches!, forKey: kCIInputImageKey)
        let fadedScratchesImage = FilmGrain.opacityFilter?.outputImage
        guard fadedScratchesImage != nil else {
            log.error("NIL faded scratches image")
            return inputImage
        }
         ***/
        let fadedScratchesImage = darkScratches

        //return fadedScratchesImage // DEBUG: check intermediate result
        
        // multiply by the scratches image
        FilmGrain.multiplyFilter?.setValue(fadedScratchesImage!, forKey: kCIInputImageKey)
        FilmGrain.multiplyFilter?.setValue(speckledImage, forKey: kCIInputBackgroundImageKey)
        let scratchedImage = FilmGrain.multiplyFilter?.outputImage
        guard scratchedImage != nil else {
            print("NIL sratched image")
            return inputImage
        }

         //return scratchedImage // DEBUG: check intermediate result
        
        // reduce the opacity based on inputAmount
        FilmGrain.opacityFilter?.setValue(scratchedImage!, forKey: kCIInputImageKey)
        FilmGrain.opacityFilter?.setValue(inputAmount, forKey: "inputOpacity")
        let fadedImage = FilmGrain.opacityFilter?.outputImage
        guard fadedImage != nil else {
            print("NIL faded image")
            return inputImage
        }
        
        // we have a somewhat transparent scratched/speckled image, so overlay onto the original
        //let overlayFilter2 = CIFilter(name:"CIOverlayBlendMode")
        let overlayFilter2 = CIFilter(name:"CISourceOverCompositing")
        overlayFilter2?.setValue(fadedImage!, forKey: kCIInputImageKey)
        overlayFilter2?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        let finalImage = overlayFilter2?.outputImage
        guard finalImage != nil else {
            print("NIL speckled image")
            return inputImage
        }

        return finalImage!.cropped(to: inputImage.extent)
        
    }
}

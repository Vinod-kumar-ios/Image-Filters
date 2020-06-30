//
//  RGBChannelCompositing.swift
//  XMP_On_Image
//
//  Created by Vinod Kumar on 28/06/20.
//  Copyright © 2020 Vinod Kumar. All rights reserved.
//



import CoreImage

let tau = CGFloat.pi * 2

/// `RGBChannelCompositing` filter takes three input images and composites them together
/// by their color channels, the output RGB is `(inputRed.r, inputGreen.g, inputBlue.b)`

class RGBChannelCompositing: CIFilter
{
    @objc var inputRedImage : CIImage?
    @objc var inputGreenImage : CIImage?
    @objc var inputBlueImage : CIImage?
    
    let rgbChannelCompositingKernel = CIColorKernel(source:
        "kernel vec4 rgbChannelCompositing(__sample red, __sample green, __sample blue)" +
        "{" +
        "   return vec4(red.r, green.g, blue.b, 1.0);" +
        "}"
    )
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "RGB Compositing" as AnyObject,
            
            "inputRedImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Red Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputGreenImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Green Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputBlueImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Blue Image",
                kCIAttributeType: kCIAttributeTypeImage]
        ]
    }
    
    override var outputImage: CIImage!
    {
        guard let inputRedImage = inputRedImage,
            let inputGreenImage = inputGreenImage,
            let inputBlueImage = inputBlueImage,
            let rgbChannelCompositingKernel = rgbChannelCompositingKernel else
        {
            return nil
        }
        
        let extent = inputRedImage.extent.union(inputGreenImage.extent.union(inputBlueImage.extent))
        let arguments = [inputRedImage, inputGreenImage, inputBlueImage]
        
        return rgbChannelCompositingKernel.apply(extent: extent, arguments: arguments)
    }
}

/// `RGBChannelToneCurve` allows individual tone curves to be applied to each channel.
/// The `x` values of each tone curve are locked to `[0.0, 0.25, 0.5, 0.75, 1.0]`, the
/// supplied vector for each channel defines the `y` positions.
///
/// For example, if the `redValues` vector is `[0.2, 0.4, 0.6, 0.8, 0.9]`, the points
/// passed to the `CIToneCurve` filter will be:
/// ```
/// [(0.0, 0.2), (0.25, 0.4), (0.5, 0.6), (0.75, 0.8), (1.0, 0.9)]
/// ```
class RGBChannelToneCurve: CIFilter
{
    @objc var inputImage: CIImage?
    
    @objc var inputRedYValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    @objc var inputGreenYValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    @objc var inputBlueYValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    
    @objc var inputRedXValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    @objc var inputGreenXValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    @objc var inputBlueXValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    
    let rgbChannelCompositing = RGBChannelCompositing()
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputRedYvalues":
            inputRedYValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        case "inputGreenYvalues":
            inputGreenYValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        case "inputBlueYvalues":
            inputBlueYValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
            
        case "inputRedXvalues":
            inputRedXValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        case "inputGreenXvalues":
            inputGreenXValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        case "inputBlueXvalues":
            inputBlueXValues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        default:
            break
        }
    }
    
    
   
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "RGB Tone Curve" as AnyObject,
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRedValues": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDefault: CIVector(values: [inputRedXValues.value(at: 0), inputRedXValues.value(at: 1), inputRedXValues.value(at: 2), inputRedXValues.value(at: 3), inputRedXValues.value(at: 3)], count: 5),
                kCIAttributeDisplayName: "Red 'y' Values",
                kCIAttributeDescription: "Red tone curve 'y' values at 'x' positions [0.0, 0.25, 0.5, 0.75, 1.0].",
                kCIAttributeType: kCIAttributeTypeOffset],

            "inputGreenValues": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDefault: CIVector(values: [inputGreenXValues.value(at: 0), inputGreenXValues.value(at: 1), inputGreenXValues.value(at: 2), inputGreenXValues.value(at: 3), inputGreenXValues.value(at: 3)], count: 5),
                kCIAttributeDisplayName: "Green 'y' Values",
                kCIAttributeDescription: "Green tone curve 'y' values at 'x' positions [0.0, 0.25, 0.5, 0.75, 1.0].",
                kCIAttributeType: kCIAttributeTypeOffset],
            
            "inputBlueValues": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
               kCIAttributeDefault: CIVector(values: [inputBlueXValues.value(at: 0), inputBlueXValues.value(at: 1), inputBlueXValues.value(at: 2), inputBlueXValues.value(at: 3), inputBlueXValues.value(at: 3)], count: 5),
                kCIAttributeDisplayName: "Blue 'y' Values",
                kCIAttributeDescription: "Blue tone curve 'y' values at 'x' positions [0.0, 0.25, 0.5, 0.75, 1.0].",
                kCIAttributeType: kCIAttributeTypeOffset]
        ]
    }
    
    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage else
        {
            return nil
        }

        let red = inputImage.applyingFilter("CIToneCurve",
            parameters: [
                "inputPoint0": CIVector(x: inputRedXValues.value(at: 0), y: inputRedYValues.value(at: 0)),
                "inputPoint1": CIVector(x: inputRedXValues.value(at: 1), y: inputRedYValues.value(at: 1)),
                "inputPoint2": CIVector(x: inputRedXValues.value(at: 2), y: inputRedYValues.value(at: 2)),
                "inputPoint3": CIVector(x: inputRedXValues.value(at: 3), y: inputRedYValues.value(at: 3)),
                "inputPoint4": CIVector(x: inputRedXValues.value(at: 4), y: inputRedYValues.value(at: 4))
            ])
        
        let green = inputImage.applyingFilter("CIToneCurve",
            parameters: [
                "inputPoint0": CIVector(x: inputGreenXValues.value(at: 0), y: inputGreenYValues.value(at: 0)),
                "inputPoint1": CIVector(x: inputGreenXValues.value(at: 1), y: inputGreenYValues.value(at: 1)),
                "inputPoint2": CIVector(x: inputGreenXValues.value(at: 2), y: inputGreenYValues.value(at: 2)),
                "inputPoint3": CIVector(x: inputGreenXValues.value(at: 3), y: inputGreenYValues.value(at: 3)),
                "inputPoint4": CIVector(x: inputGreenXValues.value(at: 4), y: inputGreenYValues.value(at: 4))
            ])
        
        let blue = inputImage.applyingFilter("CIToneCurve",
            parameters: [
                "inputPoint0": CIVector(x: inputBlueXValues.value(at: 0), y: inputBlueYValues.value(at: 0)),
                "inputPoint1": CIVector(x: inputBlueXValues.value(at: 1), y: inputBlueYValues.value(at: 1)),
                "inputPoint2": CIVector(x: inputBlueXValues.value(at: 2), y: inputBlueYValues.value(at: 2)),
                "inputPoint3": CIVector(x: inputBlueXValues.value(at: 3), y: inputBlueYValues.value(at: 3)),
                "inputPoint4": CIVector(x: inputBlueXValues.value(at: 4), y: inputBlueYValues.value(at: 4))
            ])
        
        rgbChannelCompositing.inputRedImage = red
        rgbChannelCompositing.inputGreenImage = green
        rgbChannelCompositing.inputBlueImage = blue
        
        return rgbChannelCompositing.outputImage
    }
}

/// `RGBChannelBrightnessAndContrast` controls brightness & contrast per color channel

class RGBChannelBrightnessAndContrast: CIFilter
{
    @objc var inputImage: CIImage?
    
    @objc var inputRedBrightness: CGFloat = 0
    @objc var inputRedContrast: CGFloat = 1
    
    @objc var inputGreenBrightness: CGFloat = 0
    @objc var inputGreenContrast: CGFloat = 1
    
    @objc var inputBlueBrightness: CGFloat = 0
    @objc var inputBlueContrast: CGFloat = 1
    
    let rgbChannelCompositing = RGBChannelCompositing()
    
    override func setDefaults()
    {
        inputRedBrightness = 0
        inputRedContrast = 1
        
        inputGreenBrightness = 0
        inputGreenContrast = 1
        
        inputBlueBrightness = 0
        inputBlueContrast = 1
    }
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "RGB Brightness And Contrast" as AnyObject,
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRedBrightness": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0,
                kCIAttributeDisplayName: "Red Brightness",
                kCIAttributeMin: 1,
                kCIAttributeSliderMin: -1,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputRedContrast": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1,
                kCIAttributeDisplayName: "Red Contrast",
                kCIAttributeMin: 0.25,
                kCIAttributeSliderMin: 0.25,
                kCIAttributeSliderMax: 4,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputGreenBrightness": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0,
                kCIAttributeDisplayName: "Green Brightness",
                kCIAttributeMin: 1,
                kCIAttributeSliderMin: -1,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputGreenContrast": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1,
                kCIAttributeDisplayName: "Green Contrast",
                kCIAttributeMin: 0.25,
                kCIAttributeSliderMin: 0.25,
                kCIAttributeSliderMax: 4,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputBlueBrightness": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0,
                kCIAttributeDisplayName: "Blue Brightness",
                kCIAttributeMin: 1,
                kCIAttributeSliderMin: -1,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputBlueContrast": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1,
                kCIAttributeDisplayName: "Blue Contrast",
                kCIAttributeMin: 0.25,
                kCIAttributeSliderMin: 0.25,
                kCIAttributeSliderMax: 4,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        let red = inputImage.applyingFilter("CIColorControls",
            parameters: [
                kCIInputBrightnessKey: inputRedBrightness,
                kCIInputContrastKey: inputRedContrast])
        
        let green = inputImage.applyingFilter("CIColorControls",
            parameters: [
                kCIInputBrightnessKey: inputGreenBrightness,
                kCIInputContrastKey: inputGreenContrast])
        
        let blue = inputImage.applyingFilter("CIColorControls",
            parameters: [
                kCIInputBrightnessKey: inputBlueBrightness,
                kCIInputContrastKey: inputBlueContrast])
        
        rgbChannelCompositing.inputRedImage = red
        rgbChannelCompositing.inputGreenImage = green
        rgbChannelCompositing.inputBlueImage = blue
        
        let finalImage = rgbChannelCompositing.outputImage
        
        return finalImage
    }
}

/// `ChromaticAberration` offsets an image's RGB channels around an equilateral triangle

class ChromaticAberration: CIFilter
{
    @objc var inputImage: CIImage?
    
    @objc var inputAngle: CGFloat = 0
    @objc var inputRadius: CGFloat = 2
    
    let rgbChannelCompositing = RGBChannelCompositing()
    
    override func setDefaults()
    {
        inputAngle = 0
        inputRadius = 2
    }
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "Chromatic Abberation" as AnyObject,
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputAngle": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0,
                kCIAttributeDisplayName: "Angle",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: tau,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 2,
                kCIAttributeDisplayName: "Radius",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 25,
                kCIAttributeType: kCIAttributeTypeScalar],
        ]
    }
    
    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        let redAngle = inputAngle + tau
        let greenAngle = inputAngle + tau * 0.333
        let blueAngle = inputAngle + tau * 0.666
        
        let redTransform = CGAffineTransform(translationX: sin(redAngle) * inputRadius, y: cos(redAngle) * inputRadius)
        let greenTransform = CGAffineTransform(translationX: sin(greenAngle) * inputRadius, y: cos(greenAngle) * inputRadius)
        let blueTransform = CGAffineTransform(translationX: sin(blueAngle) * inputRadius, y: cos(blueAngle) * inputRadius)
        
        let red = inputImage.applyingFilter("CIAffineTransform",
            parameters: [kCIInputTransformKey: NSValue(cgAffineTransform: redTransform)])
            .cropped(to: inputImage.extent)
        
        let green = inputImage.applyingFilter("CIAffineTransform",
            parameters: [kCIInputTransformKey: NSValue(cgAffineTransform: greenTransform)])
            .cropped(to: inputImage.extent)
        
        let blue = inputImage.applyingFilter("CIAffineTransform",
            parameters: [kCIInputTransformKey: NSValue(cgAffineTransform: blueTransform)])
            .cropped(to: inputImage.extent)

        rgbChannelCompositing.inputRedImage = red
        rgbChannelCompositing.inputGreenImage = green
        rgbChannelCompositing.inputBlueImage = blue
        
        let finalImage = rgbChannelCompositing.outputImage
        
        return finalImage
    }
}

/// `RGBChannelGaussianBlur` allows Gaussian blur on a per channel basis

class RGBChannelGaussianBlur: CIFilter
{
    @objc var inputImage: CIImage?
    
    @objc var inputRedRadius: CGFloat = 2
    @objc var inputGreenRadius: CGFloat = 4
    @objc var inputBlueRadius: CGFloat = 8
    
    let rgbChannelCompositing = RGBChannelCompositing()
    
    override func setDefaults()
    {
        inputRedRadius = 2
        inputGreenRadius = 4
        inputBlueRadius = 8
    }
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "RGB Channel Gaussian Blur" as AnyObject,
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRedRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 2,
                kCIAttributeDisplayName: "Red Radius",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputGreenRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 4,
                kCIAttributeDisplayName: "Green Radius",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputBlueRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 8,
                kCIAttributeDisplayName: "Blue Radius",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        let red = inputImage
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: inputRedRadius])
            .clampedToExtent()
        
        let green = inputImage
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: inputGreenRadius])
            .clampedToExtent()
        
        let blue = inputImage
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: inputBlueRadius])
            .clampedToExtent()
        
        rgbChannelCompositing.inputRedImage = red
        rgbChannelCompositing.inputGreenImage = green
        rgbChannelCompositing.inputBlueImage = blue
        
        return rgbChannelCompositing.outputImage
    }
}

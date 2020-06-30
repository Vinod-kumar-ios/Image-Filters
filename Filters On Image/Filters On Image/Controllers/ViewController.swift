//
//  ViewController.swift
//  XMP_On_Image
//
//  Created by Vinod Kumar on 27/06/20.
//  Copyright © 2020 Vinod Kumar. All rights reserved.
//

import UIKit
import CoreImage


class ViewController: UIViewController {

    @IBOutlet weak var imgOriginal: UIImageView!
    @IBOutlet weak var imgAfterFilters: UIImageView!
    
    var arrFilters :  [[String:Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readJsonFile()
    }

    @IBAction func btnApplyFilters(_ sender: UIButton) {
      applyFilters()
      
    }
    
    func readJsonFile()  {
        if let path = Bundle.main.path(forResource: "BCPCITYLIGHTSPARIS", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? [String:Any]{
                    if let arrFilters = jsonResult["filters"] as? [[String:Any]]{
                        self.arrFilters.append(contentsOf: arrFilters)
                    }
                }
            } catch {
                // handle error
            }
        }
    }
    
    func applyFilters()  {
        var filteredImage:CIImage!
        
        for filter in arrFilters {
            let filterKey = filter["key"] as? String
            let filterParams = filter["parameters"] as? [[String:Any]]
            
            switch filterKey {
            case "CIExposureAdjust":
                let dictFilterParams = filterParams?.first!
                let value = dictFilterParams!["val"] as? Double
                let imgFilter = CIFilter(name: "CIExposureAdjust")
                imgFilter?.setValue(value, forKey: kCIInputEVKey)
                let image = apply(imgFilter, for: CIImage.init(image: imgOriginal.image!)!)
                filteredImage = image
            case "SaturationFilter":
                let dictFilterParams = filterParams?.first!
                let value = dictFilterParams!["val"] as? Double
                let imgFilter = CIFilter(name: "CIColorControls")
                imgFilter?.setValue(value, forKey: kCIInputSaturationKey)
                let image = apply(imgFilter, for: filteredImage)
                filteredImage = image
            case "CISharpenLuminance":
                let dictFilterParams = filterParams?.first!
                let value = dictFilterParams!["val"] as? Double
                let imgFilter = CIFilter(name: "CISharpenLuminance")
                imgFilter?.setValue(value, forKey: kCIInputSharpnessKey)
                let image = apply(imgFilter, for: filteredImage)
                filteredImage = image
            case "CIHighlightShadowAdjust":
                let imgFilter = CIFilter(name: "CIHighlightShadowAdjust")
                for filterValue in filterParams! {
                    if let key = filterValue["key"] as? String, let inputShadow = filterValue["val"] as? Double{
                        imgFilter?.setValue(inputShadow, forKey: key)
                    }                }
                let image = apply(imgFilter, for: filteredImage)
                filteredImage = image
            case "CIToneCurve":
                let imgFilter = CIFilter(name: "CIToneCurve")
                for filterValue in filterParams! {
                    if let valuesOfVector = filterValue["val"] as? [Double], let key = filterValue["key"] as? String{
                        let vector = CIVector.init(x: CGFloat(valuesOfVector.first!), y: CGFloat(valuesOfVector.last!))
                        imgFilter?.setValue(vector, forKey: key)
                    }
                }
                let image = apply(imgFilter, for: filteredImage)
                filteredImage = image
                
            case "MultiBandHSV":
                let imgFilter = MultiBandHSV()
                for filterValue in filterParams! {
                    if let valuesOfVector = filterValue["val"] as? [CGFloat], let key = filterValue["key"] as? String{
                        let vector =  CIVector.init(x: valuesOfVector.first!, y: valuesOfVector[1], z: valuesOfVector.last!)
                        imgFilter.setValue(vector, forKey: key)
                    }
                }
                let image = apply(imgFilter, for: filteredImage)
                filteredImage = image
                imgAfterFilters.image = UIImage.init(ciImage: filteredImage)
                break
            default:
                break
            }
        }
    }

    
    
    func apply(_ filter: CIFilter?, for image: CIImage) -> CIImage {
        guard let filter = filter else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        guard let filteredImage = filter.value(forKey: kCIOutputImageKey) else { return image }
        return filteredImage as! CIImage
    }
    
    func CIExposureAdjustFilter(beginImage:CIImage, value:Double) ->  CIImage{
        let filter = CIFilter(name: "CIUnsharpMask")
        filter?.setValue(beginImage, forKey: kCIInputImageKey)
        filter?.setValue(2.0, forKey: "inputIntensity")
        filter?.setValue(1.0, forKey: "inputRadius")
        return (filter?.outputImage)!
    }
    
    
}


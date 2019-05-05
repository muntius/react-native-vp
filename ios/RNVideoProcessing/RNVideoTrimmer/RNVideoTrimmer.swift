    
    //
    //  RNVideoTrimmer.swift
    //  RNVideoProcessing
    //
    import UIKit
    import Foundation
    import AVFoundation
    import Photos
    
    enum QUALITY_ENUM: String {
      case QUALITY_LOW = "low"
      case QUALITY_MEDIUM = "medium"
      case QUALITY_HIGHEST = "highest"
      case QUALITY_640x480 = "640x480"
      case QUALITY_960x540 = "960x540"
      case QUALITY_1280x720 = "1280x720"
      case QUALITY_1920x1080 = "1920x1080"
      case QUALITY_3840x2160 = "3840x2160"
      case QUALITY_PASS_THROUGH = "passthrough"
    }
    
    
    @objc(RNVideoTrimmer)
    class RNVideoTrimmer: NSObject {
      
      @objc
      static func requiresMainQueueSetup() -> Bool {
        return false
      }
      
      @objc func getVideoOrientationFromAsset(asset : AVAsset) -> UIImage.Orientation {
        let videoTrack: AVAssetTrack? = asset.tracks(withMediaType: AVMediaType.video)[0]
        //        let size = videoTrack!.naturalSize
        
        //        let txf: CGAffineTransform = videoTrack!.preferredTransform
        
        //        if (size.width == txf.tx && size.height == txf.ty) {
        //          return UIImageOrientation.left;
        //        } else if (txf.tx == 0 && txf.ty == 0) {
        //          return UIImageOrientation.right;
        //        } else if (txf.tx == 0 && txf.ty == size.width) {
        //          return UIImageOrientation.down;
        //        } else {
        //          return UIImageOrientation.up;
        //        }
        
        let orientationTransform = videoTrack!.preferredTransform
        
        var videoAssetOrientation_: UIImage.Orientation
        var isVideoAssetPortrait_: Bool
        if (orientationTransform.a == 0.0 && orientationTransform.b == 1.0 && orientationTransform.c == -1.0 && orientationTransform.d == 0)
        {
          isVideoAssetPortrait_ = true
          return UIImage.Orientation.up;
          
        }
        else if(orientationTransform.a == 0.0 && orientationTransform.b == -1.0 && orientationTransform.c == 1.0 && orientationTransform.d == 0) {
          isVideoAssetPortrait_ = true
          return UIImage.Orientation.down;
        }
          
        else if orientationTransform.a == 0 && orientationTransform.b == 1.0 && orientationTransform.c == -1.0 && orientationTransform.d == 0 {
          videoAssetOrientation_ = .right
          isVideoAssetPortrait_ = true
          return UIImage.Orientation.right;
        }
        else if orientationTransform.a == 0 && orientationTransform.b == -1.0 && orientationTransform.c == 1.0 && orientationTransform.d == 0 {
          videoAssetOrientation_ = .left
          isVideoAssetPortrait_ = true
          return UIImage.Orientation.up;
        }
        else if orientationTransform.a == 1.0 && orientationTransform.b == 0 && orientationTransform.c == 0 && orientationTransform.d == 1.0 {
          videoAssetOrientation_ = .up
          return UIImage.Orientation.right;
        }
        else if orientationTransform.a == -1.0 && orientationTransform.b == 0 && orientationTransform.c == 0 && orientationTransform.d == -1.0 {
          isVideoAssetPortrait_ = false
          videoAssetOrientation_ = .left
          return UIImage.Orientation.left;
        }
        else {
          isVideoAssetPortrait_ = true
          return UIImage.Orientation.up;
        }
        
        //        var naturalSize = CGSize()
        //
        //        if isVideoAssetPortrait_ {
        //          naturalSize = CGSize(width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.width)
        //          print("it is portrait")
        //        } else {
        //          naturalSize = clipVideoTrack.naturalSize
        //          print("it is not")
        //        }
        
        
        
        
        
        
      }
      
      @objc func crop(_ source: String, options: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
        
        var sTime:Float?
        var eTime:Float?
        
        let cropOffsetXInt = options.object(forKey: "cropOffsetX") as! Int
        let cropOffsetYInt = options.object(forKey: "cropOffsetY") as! Int
        let cropWidthInt = options.object(forKey: "cropWidth") as? Int
        let cropHeightInt = options.object(forKey: "cropHeight") as? Int
        var cropRatio = options.object(forKey: "cropRatio") as? String
        let cropWidthSizeInt = options.object(forKey: "cropWidthSize") as? Int
        let cropHeightSizeInt = options.object(forKey: "cropHeightSize") as? Int
        if ( cropWidthInt == nil ) {
          callback(["Invalid cropWidth", NSNull()])
          return
        }
        
        if ( cropHeightInt == nil ) {
          callback(["Invalid cropHeight", NSNull()])
          return
        }
        
        if ( cropRatio == nil ) {
          cropRatio = "SQUARE"
        }
        
        
        if let num = options.object(forKey: "startTime") as? NSNumber {
          sTime = num.floatValue
        }
        if let num = options.object(forKey: "endTime") as? NSNumber {
          eTime = num.floatValue
        }
        
        let cropOffsetX : CGFloat = CGFloat(cropOffsetXInt);
        let cropOffsetY : CGFloat = CGFloat(cropOffsetYInt);
        var cropWidth : CGFloat = CGFloat(cropWidthInt!);
        var cropHeight : CGFloat = CGFloat(cropHeightInt!);
        let cropWidthOrigin : CGFloat = CGFloat(cropWidthInt!);
        let cropHeightOrigin : CGFloat = CGFloat(cropHeightInt!);
        let cropWidthSize  : CGFloat = CGFloat(cropWidthSizeInt!);
        let cropHeightSize : CGFloat = CGFloat(cropHeightSizeInt!);
        
        //        let quality = ((options.object(forKey: "quality") as? String) != nil) ? options.object(forKey: "quality") as! String : ""
        
        var sourceURL = getSourceURL(source: source)
        let asset = AVAsset(url: sourceURL as URL)
        
        let clipVideoTrack: AVAssetTrack! = asset.tracks(withMediaType: AVMediaType.video)[0]
        let videoOrientation = self.getVideoOrientationFromAsset(asset: asset)
        
        let fileName = ProcessInfo.processInfo.globallyUniqueString
        let outputURL = "\(NSTemporaryDirectory())\(fileName).mp4"
        
        //Trim rime range
        if eTime == nil {
          eTime = Float(asset.duration.seconds)
        }
        if sTime == nil {
          sTime = 0
        }
        
        let startTime = CMTime(seconds: Double(sTime!), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(eTime!), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        guard
          let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)
          else {
            callback(["Error creating AVAssetExportSession", NSNull()])
            return
        }
        
        exportSession.outputURL = NSURL.fileURL(withPath: outputURL)
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        cropHeight = cropHeightSize
        cropWidth = cropWidthSize
        videoComposition.renderSize = CGSize(width: cropWidthOrigin, height: cropHeightOrigin)
        let instruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: CMTime.zero, end: asset.duration)
        
        
        var scale1: CGFloat = 0
        scale1 = cropWidthOrigin / cropWidthSize
        
        
        var t1 = CGAffineTransform.identity
        var t2 = CGAffineTransform.identity
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        switch videoOrientation {
          
        case UIImage.Orientation.up:
          t1 = CGAffineTransform(translationX: (clipVideoTrack.naturalSize.height - cropOffsetX)*scale1, y: (0 - cropOffsetY)*scale1 );
          t2 = t1.rotated(by: CGFloat(Double.pi / 2) );
          break;
        case UIImage.Orientation.left:
          t1 = CGAffineTransform(translationX: (clipVideoTrack.naturalSize.width - cropOffsetX)*scale1, y: (clipVideoTrack.naturalSize.height - cropOffsetY)*scale1 );
          t2 = t1.rotated(by: CGFloat(Double.pi)  );
          break;
        case UIImage.Orientation.right:
          t1 = CGAffineTransform(translationX: (0 - cropOffsetX)*scale1, y: (0 - cropOffsetY)*scale1 );
          t2 = t1;
          break;
        case UIImage.Orientation.down:
          t1 = CGAffineTransform(translationX: (0 - cropOffsetX)*scale1, y: (clipVideoTrack.naturalSize.width - cropOffsetY)*scale1 );
          t2 = t1.rotated(by: -(CGFloat)(Double.pi / 2) );
          break;
        default:
          NSLog("no supported orientation has been found in this video");
          break;
        }
        
        let t3: CGAffineTransform = t2.scaledBy(x: scale1, y: scale1)
        let finalTransform: CGAffineTransform = t3
        transformer.setTransform(finalTransform, at: CMTime.zero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        exportSession.videoComposition = videoComposition
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously {
          switch exportSession.status {
          case .completed:
            
            sourceURL = self.getSourceURL(source: outputURL)
            //          guard let track = AVAsset(url: sourceURL).tracks(withMediaType: AVMediaTypeVideo).first else { return  }
            //          let size = track.naturalSize.applying(track.preferredTransform)
            //           print("dimensions new 2")
            //           print(fabs(size.width))
            //           print(fabs(size.height))
            callback( [NSNull(), sourceURL.absoluteString] )
          case .failed:
            callback( ["Failed: \(String(describing: exportSession.error))", NSNull()] )
            
          case .cancelled:
            callback( ["Cancelled: \(String(describing: exportSession.error))", NSNull()] )
            
          default: break
          }
        }
        
        // do something here when loop finished
      }
      
      func resize(_ source: String, _ options: [String:Float], completion: @escaping (_ result: String)->()) {
        
        var width = options["width"]
        var height = options["height"]
        let bitrateMultiplier = options["bitrateMultiplier"] ?? 1
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          else {
            completion("Error creating FileManager")
            return
        }
        
        let sourceURL = getSourceURL(source: source)
        let asset = AVAsset(url: sourceURL as URL)
        
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else  {
          completion("Error getting track info")
          return
        }
        
        let naturalSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let bps = videoTrack.estimatedDataRate
        width = width ?? Float(abs(naturalSize.width))
        height = height ?? Float(abs(naturalSize.height))
        let averageBitrate = bps / bitrateMultiplier
        
        var outputURL = documentDirectory.appendingPathComponent("output")
        do {
          try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
          let name = randomString()
          outputURL = outputURL.appendingPathComponent("\(name)-compressed.mp4")
        } catch {
          completion(error.localizedDescription)
          print(error)
        }
        
        //Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        let compressionEncoder = SDAVAssetExportSession(asset: asset)
        if compressionEncoder == nil {
          completion("Error creating AVAssetExportSession")
          return
        }
        compressionEncoder!.outputFileType = AVFileType.mp4.rawValue
        compressionEncoder!.outputURL = NSURL.fileURL(withPath: outputURL.path)
        compressionEncoder!.shouldOptimizeForNetworkUse = true
        compressionEncoder?.videoSettings = [
          AVVideoCodecKey: AVVideoCodecH264,
          AVVideoWidthKey: NSNumber.init(value: width!),
          AVVideoHeightKey: NSNumber.init(value: height!),
          AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: NSNumber.init(value: averageBitrate),
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
          ]
        ]
        compressionEncoder!.exportAsynchronously(completionHandler: {
          switch compressionEncoder!.status {
          case .completed:
            completion(outputURL.absoluteString)
          case .failed:
            completion("Failed: \(String(describing: compressionEncoder!.error))")
            
          case .cancelled:
            completion("Cancelled: \(String(describing: compressionEncoder!.error))")
            
          default: break
          }
        })
      }
      
      @objc func trim(_ source: String, options: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
        
        var sTime:Float?
        var eTime:Float?
        if let num = options.object(forKey: "startTime") as? NSNumber {
          sTime = num.floatValue
        }
        if let num = options.object(forKey: "endTime") as? NSNumber {
          eTime = num.floatValue
        }
        
        let quality = ((options.object(forKey: "quality") as? String) != nil) ? options.object(forKey: "quality") as! String : ""
        let saveToCameraRoll = options.object(forKey: "saveToCameraRoll") as? Bool ?? false
        let saveWithCurrentDate = options.object(forKey: "saveWithCurrentDate") as? Bool ?? false
        
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          else {
            callback(["Error creating FileManager", NSNull()])
            return
        }
        
        let sourceURL = getSourceURL(source: source)
        let asset = AVAsset(url: sourceURL as URL)
        if eTime == nil {
          eTime = Float(asset.duration.seconds)
        }
        if sTime == nil {
          sTime = 0
        }
        var outputURL = documentDirectory.appendingPathComponent("output")
        do {
          try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
          let name = randomString()
          outputURL = outputURL.appendingPathComponent("\(name).mp4")
        } catch {
          callback([error.localizedDescription, NSNull()])
          print(error)
        }
        
        //Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        let useQuality = getQualityForAsset(quality: quality, asset: asset)
        
        //print("RNVideoTrimmer passed quality: \(quality). useQuality: \(useQuality)")
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: useQuality)
          else {
            callback(["Error creating AVAssetExportSession", NSNull()])
            return
        }
        exportSession.outputURL = NSURL.fileURL(withPath: outputURL.path)
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        if saveToCameraRoll && saveWithCurrentDate {
          let metaItem = AVMutableMetadataItem()
          metaItem.key = AVMetadataKey.commonKeyCreationDate as (NSCopying & NSObjectProtocol)?
          metaItem.keySpace = AVMetadataKeySpace.common
          metaItem.value = NSDate() as (NSCopying & NSObjectProtocol)?
          exportSession.metadata = [metaItem]
        }
        
        let startTime = CMTime(seconds: Double(sTime!), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(eTime!), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously{
          switch exportSession.status {
          case .completed:
            callback( [NSNull(), outputURL.absoluteString] )
            if saveToCameraRoll {
              UISaveVideoAtPathToSavedPhotosAlbum(outputURL.relativePath, self, nil, nil)
            }
            
          case .failed:
            callback( ["Failed: \(String(describing: exportSession.error))", NSNull()] )
            
          case .cancelled:
            callback( ["Cancelled: \(String(describing: exportSession.error))", NSNull()] )
            
          default: break
          }
        }
      }
      
      @objc func boomerang(_ source: String, options: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
        
        let quality = ""
        
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          else {
            callback(["Error creating FileManager", NSNull()])
            return
        }
        
        let sourceURL = getSourceURL(source: source)
        let firstAsset = AVAsset(url: sourceURL as URL)
        
        let mixComposition = AVMutableComposition()
        let track = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        
        var outputURL = documentDirectory.appendingPathComponent("output")
        var finalURL = documentDirectory.appendingPathComponent("output")
        do {
          try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
          try manager.createDirectory(at: finalURL, withIntermediateDirectories: true, attributes: nil)
          let name = randomString()
          outputURL = outputURL.appendingPathComponent("\(name).mp4")
          finalURL = finalURL.appendingPathComponent("\(name)merged.mp4")
        } catch {
          callback([error.localizedDescription, NSNull()])
          print(error)
        }
        
        //Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        _ = try? manager.removeItem(at: finalURL)
        
        let useQuality = getQualityForAsset(quality: quality, asset: firstAsset)
        
        //    print("RNVideoTrimmer passed quality: \(quality). useQuality: \(useQuality)")
        
        AVUtilities.reverse(firstAsset, outputURL: outputURL, completion: { [unowned self] (reversedAsset: AVAsset) in
          
          
          let secondAsset = reversedAsset
          
          // Credit: https://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
          do {
            try track?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration), of: firstAsset.tracks(withMediaType: AVMediaType.video)[0], at: CMTime.zero)
          } catch _ {
            callback( ["Failed: Could not load 1st track", NSNull()] )
            return
          }
          
          do {
            try track?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: secondAsset.duration), of: secondAsset.tracks(withMediaType: AVMediaType.video)[0], at: mixComposition.duration)
          } catch _ {
            callback( ["Failed: Could not load 2nd track", NSNull()] )
            return
          }
          
          
          guard let exportSession = AVAssetExportSession(asset: mixComposition, presetName: useQuality) else {
            callback(["Error creating AVAssetExportSession", NSNull()])
            return
          }
          exportSession.outputURL = NSURL.fileURL(withPath: finalURL.path)
          exportSession.outputFileType = AVFileType.mp4
          exportSession.shouldOptimizeForNetworkUse = true
          let startTime = CMTime(seconds: Double(0), preferredTimescale: 1000)
          let endTime = CMTime(seconds: mixComposition.duration.seconds, preferredTimescale: 1000)
          let timeRange = CMTimeRange(start: startTime, end: endTime)
          
          exportSession.timeRange = timeRange
          
          exportSession.exportAsynchronously{
            switch exportSession.status {
            case .completed:
              callback( [NSNull(), finalURL.absoluteString] )
              
            case .failed:
              callback( ["Failed: \(String(describing: exportSession.error))", NSNull()] )
              
            case .cancelled:
              callback( ["Cancelled: \(String(describing: exportSession.error))", NSNull()] )
              
            default: break
            }
          }
        })
      }
      
      @objc func reverse(_ source: String, options: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
        
        let quality = ""
        
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          else {
            callback(["Error creating FileManager", NSNull()])
            return
        }
        
        let sourceURL = getSourceURL(source: source)
        let asset = AVAsset(url: sourceURL as URL)
        
        var outputURL = documentDirectory.appendingPathComponent("output")
        do {
          try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
          let name = randomString()
          outputURL = outputURL.appendingPathComponent("\(name).mp4")
        } catch {
          callback([error.localizedDescription, NSNull()])
          print(error)
        }
        
        //Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        let useQuality = getQualityForAsset(quality: quality, asset: asset)
        
        print("RNVideoTrimmer passed quality: \(quality). useQuality: \(useQuality)")
        
        AVUtilities.reverse(asset, outputURL: outputURL, completion: { [unowned self] (asset: AVAsset) in
          callback( [NSNull(), outputURL.absoluteString] )
        })
      }
      
      @objc func compress(_ source: String, options: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
        
        var width = options.object(forKey: "width") as? Float
        var height = options.object(forKey: "height") as? Float
        let bitrateMultiplier = options.object(forKey: "bitrateMultiplier") as? Float ?? 1
        let saveToCameraRoll = options.object(forKey: "saveToCameraRoll") as? Bool ?? false
        let minimumBitrate = options.object(forKey: "minimumBitrate") as? Float
        let saveWithCurrentDate = options.object(forKey: "saveWithCurrentDate") as? Bool ?? false
        let removeAudio = options.object(forKey: "removeAudio") as? Bool ?? false
        
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          else {
            callback(["Error creating FileManager", NSNull()])
            return
        }
        
        let sourceURL = getSourceURL(source: source)
        let asset = AVAsset(url: sourceURL as URL)
        
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else  {
          callback(["Error getting track info", NSNull()])
          return
        }
        
        let naturalSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let bps = videoTrack.estimatedDataRate
        width = width ?? Float(abs(naturalSize.width))
        height = height ?? Float(abs(naturalSize.height))
        var averageBitrate = bps / bitrateMultiplier
        if minimumBitrate != nil {
          if averageBitrate < minimumBitrate! {
            averageBitrate = minimumBitrate!
          }
          if bps < minimumBitrate! {
            averageBitrate = bps
          }
        }
        
        var outputURL = documentDirectory.appendingPathComponent("output")
        do {
          try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
          let name = randomString()
          outputURL = outputURL.appendingPathComponent("\(name)-compressed.mp4")
        } catch {
          callback([error.localizedDescription, NSNull()])
          print(error)
        }
        
        //Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        let compressionEncoder = SDAVAssetExportSession(asset: asset)
        if compressionEncoder == nil {
          callback(["Error creating AVAssetExportSession", NSNull()])
          return
        }
        compressionEncoder!.outputFileType = AVFileType.mp4.rawValue
        compressionEncoder!.outputURL = NSURL.fileURL(withPath: outputURL.path)
        compressionEncoder!.shouldOptimizeForNetworkUse = true
        if saveToCameraRoll && saveWithCurrentDate {
          let metaItem = AVMutableMetadataItem()
          metaItem.key = AVMetadataKey.commonKeyCreationDate as (NSCopying & NSObjectProtocol)?
          metaItem.keySpace = AVMetadataKeySpace.common
          metaItem.value = NSDate() as (NSCopying & NSObjectProtocol)?
          compressionEncoder!.metadata = [metaItem]
        }
        compressionEncoder?.videoSettings = [
          AVVideoCodecKey: AVVideoCodecH264,
          AVVideoWidthKey: NSNumber.init(value: width!),
          AVVideoHeightKey: NSNumber.init(value: height!),
          AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: NSNumber.init(value: averageBitrate),
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
          ]
        ]
        if !removeAudio {
          compressionEncoder?.audioSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 128000
          ]
        }
        compressionEncoder!.exportAsynchronously(completionHandler: {
          switch compressionEncoder!.status {
          case .completed:
            callback( [NSNull(), outputURL.absoluteString] )
            if saveToCameraRoll {
              UISaveVideoAtPathToSavedPhotosAlbum(outputURL.relativePath, self, nil, nil)
            }
          case .failed:
            callback( ["Failed: \(String(describing: compressionEncoder!.error))", NSNull()] )
            
          case .cancelled:
            callback( ["Cancelled: \(String(describing: compressionEncoder!.error))", NSNull()] )
            
          default: break
          }
        })
      }
      
      @objc func getAssetInfo(_ source: String, callback: RCTResponseSenderBlock) {
        let sourceURL = getSourceURL(source: source)
        let asset = AVAsset(url: sourceURL)
        var assetInfo: [String: Any] = [
          "duration" : asset.duration.seconds
        ]
        if let track = asset.tracks(withMediaType: AVMediaType.video).first {
          let naturalSize = track.naturalSize
          let t = track.preferredTransform
          let isPortrait = t.a == 0 && abs(t.b) == 1 && t.d == 0
          let size = [
            "width": isPortrait ? naturalSize.height : naturalSize.width,
            "height": isPortrait ? naturalSize.width : naturalSize.height
          ]
          assetInfo["size"] = size
          assetInfo["frameRate"] = Int(round(track.nominalFrameRate))
          assetInfo["bitrate"] = Int(round(track.estimatedDataRate))
        }
        callback( [NSNull(), assetInfo] )
      }
      
      @objc func getPreviewImageAtPosition(_ source: String, atTime: Float = 0, maximumSize: NSDictionary, format: String = "base64", callback: @escaping RCTResponseSenderBlock) {
        let sourceURL = getSourceURL(source: source)
        let asset = AVAsset(url: sourceURL)
        //        NSMutableArray *result = [[NSMutableArray alloc] init];
        var result = [String]()
        
        var width: CGFloat = 1080
        if let _width = maximumSize.object(forKey: "width") as? CGFloat {
          width = _width
        }
        var height: CGFloat = 1080
        if let _height = maximumSize.object(forKey: "height") as? CGFloat {
          height = _height
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.maximumSize = CGSize(width: width, height: height)
        imageGenerator.appliesPreferredTrackTransform = true
        
        
        var interval = Int(atTime / 9)
        if(interval < 1 ){
          interval = 1
        }
        let first = 0
        let last = Int(atTime)
        let sequence = stride(from: first, to: last, by: interval)
        
        for element in sequence {
          var second = element
          
          if Float(element) > Float(asset.duration.seconds) || Float(element) < 0 {
            second = 0
          }
          let timestamp = CMTime(seconds: Double(second), preferredTimescale: 600)
          do {
            let imageRef = try imageGenerator.copyCGImage(at: timestamp, actualTime: nil)
            let image = UIImage(cgImage: imageRef)
            if ( format == "base64" ) {
              let imgData = image.pngData()
              let base64string = imgData?.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
              if base64string != nil {
                callback( [NSNull(), base64string!] )
              } else {
                callback( ["Unable to convert to base64)", NSNull()]  )
              }
            } else if ( format == "JPEG" ) {
              let imgData = image.jpegData(compressionQuality: 1.0)
              let fileName = ProcessInfo.processInfo.globallyUniqueString
              let fullPath = "\(NSTemporaryDirectory())\(fileName).jpg"
              try imgData?.write(to: URL(fileURLWithPath: fullPath), options: .atomic)
              let imageWidth = imageRef.width
              let imageHeight = imageRef.height
              let imageFormattedData: [AnyHashable: Any] = ["uri": fullPath, "width": imageWidth, "height": imageHeight]
              result.append(
                fullPath);
              if( atTime < 9){
                result.append(
                  fullPath);
              }
              
            } else {
              callback( ["Failed format. Expected one of 'base64' or 'JPEG'", NSNull()] )
            }
            
          } catch {
            callback( ["Failed to convert base64: \(error.localizedDescription)", NSNull()] )
          }
        }
        callback( [NSNull(), result] )
        
      }
      
      @objc func isAssetStoredLocally(_ source: String, callback: @escaping RCTResponseSenderBlock) {
        let assetUrl = URL(string: source)!
        // retrieve the image for the first result
        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetUrl], options: nil)
        if let video = fetchResult.firstObject {
          var isLocally = false
          let opt=PHVideoRequestOptions()
          opt.version = .original
          opt.deliveryMode = .fastFormat;
          opt.isNetworkAccessAllowed=false
          PHImageManager.default().requestAVAsset(forVideo: video, options: opt, resultHandler: { (asset, audioMix, info) in
            if (asset as? AVURLAsset) != nil {
              print("asset found")
              DispatchQueue.main.async {
                if (info!["PHImageFileSandboxExtensionTokenKey"] != nil) {
                  isLocally=true
                }else if((info![PHImageResultIsInCloudKey]) != nil) {
                  isLocally=false
                }else{
                  isLocally=true
                }
                callback( [NSNull(), isLocally] )
              }
            } else {
              print("no asset")
              isLocally = false
              callback( [NSNull(), isLocally] )
            }
          })
        }
      }
      
      @objc func saveAssetLocally (_ source: String, callback: @escaping RCTResponseSenderBlock) {
        print("saveAssetLocally")
        let assetUrl = URL(string: source)!
        // retrieve the image for the first result
        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetUrl], options: nil)
        if let video = fetchResult.firstObject {
          var downloaded = false
          let options: PHVideoRequestOptions = PHVideoRequestOptions()
          options.version = .original
          options.isNetworkAccessAllowed = true
          options.deliveryMode = .fastFormat;
          options.progressHandler = {  (progress, error, stop, info) in
            print("progress")
            print(progress)
            if(Int(progress) == 1){
              print("downloaded")
              downloaded = true
            }
            if((error) != nil){
              print("error in progress")
            }
          }
          PHImageManager.default().requestAVAsset(forVideo: video, options: options, resultHandler: { (asset, audioMix, info) in
            if let urlAsset = asset as? AVURLAsset {
              print("media here")
               print(urlAsset)
              if(downloaded){
                callback( [NSNull(), downloaded] )
              }
              print(urlAsset)
            } else {
              callback( [NSNull(), false] )
              print("error compplete")
            }
          })
        }
      }
      
      
      func randomString() -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: 20)
        let s:String = "RNTrimmer-Temp-Video"
        for _ in 0...19 {
          randomString.appendFormat("%C", letters.character(at: Int(arc4random_uniform(UInt32(letters.length)))))
        }
        return s.appending(randomString as String)
      }
      
      
      func getSourceURL(source: String) -> URL {
        var sourceURL: URL
        if source.contains("assets-library") {
          sourceURL = NSURL(string: source)! as URL
        } else {
          let bundleUrl = Bundle.main.resourceURL!
          sourceURL = URL(string: source, relativeTo: bundleUrl)!
        }
        return sourceURL
      }
      
      
      //      func getAsset(source: String, completion: @escaping ((_ url: URL) -> ())) {
      //        getSourceURL = URL(string: source)!
      //        let initialRequestOptions = PHVideoRequestOptions()
      //        initialRequestOptions.isNetworkAccessAllowed = true
      //        initialRequestOptions.deliveryMode = .fastFormat
      //
      //        // retrieve the image for the first result
      //        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [sourceURL], options: nil)
      //        if let video = fetchResult.firstObject {
      //          getUrlsFromPHAssets(asset: video, completion: { url in
      //            sourceURL  = url
      //            print("sourceURL")
      //            print(sourceURL)
      //          }
      //          )
      //        }
      //      }
      
      
//      func fetchAssetsFromPHAssets(asset: PHAsset, completion: @escaping ((_ url: URL) -> ())) {
//        var assetUrl : URL = URL(fileURLWithPath: "")
//        let group = DispatchGroup()
//        group.enter()
//        getURL(ofPhotoWith: asset) { url in
//          // I changed this from force unwrapping.
//          // Seems like it totally possible to get back a nil URL,
//          // in which case, you don't want to crash
//          if let url = url {
//            assetUrl = url
//          }
//          group.leave()
//        }
//        // This closure will be called once group.leave() is called
//        // for every asset in the above for loop
//        group.notify(queue: .main) {
//          completion(assetUrl )
//        }
//      }
      
      
//      func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
//
//        if mPhasset.mediaType == .image {
//          let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
//          options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
//            return true
//          }
//          mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
//            if(contentEditingInput != nil){
//              print(contentEditingInput!.fullSizeImageURL!.absoluteURL)
//              completionHandler(contentEditingInput!.fullSizeImageURL!.absoluteURL)
//            }
//          })
//        } else if mPhasset.mediaType == .video {
//          let options: PHVideoRequestOptions = PHVideoRequestOptions()
//          options.version = .original
//          options.isNetworkAccessAllowed = true
//          options.deliveryMode = .fastFormat;
//          options.progressHandler = {  (progress, error, stop, info) in
//            print("progress: \(progress)")
//
//          }
//          PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
//            if let urlAsset = asset as? AVURLAsset {
//              let localVideoUrl = urlAsset.url
//              print("download compplete")
//              print("download compplete")
//              completionHandler(localVideoUrl)
//            } else {
//              completionHandler(nil)
//            }
//          })
//        }
//
//      }
      
      
      func getQualityForAsset(quality: String, asset: AVAsset) -> String {
        var useQuality: String
        
        switch quality {
        case QUALITY_ENUM.QUALITY_LOW.rawValue:
          useQuality = AVAssetExportPresetLowQuality
          
        case QUALITY_ENUM.QUALITY_MEDIUM.rawValue:
          useQuality = AVAssetExportPresetMediumQuality
          
        case QUALITY_ENUM.QUALITY_HIGHEST.rawValue:
          useQuality = AVAssetExportPresetHighestQuality
          
        case QUALITY_ENUM.QUALITY_640x480.rawValue:
          useQuality = AVAssetExportPreset640x480
          
        case QUALITY_ENUM.QUALITY_960x540.rawValue:
          useQuality = AVAssetExportPreset960x540
          
        case QUALITY_ENUM.QUALITY_1280x720.rawValue:
          useQuality = AVAssetExportPreset1280x720
          
        case QUALITY_ENUM.QUALITY_1920x1080.rawValue:
          useQuality = AVAssetExportPreset1920x1080
          
        case QUALITY_ENUM.QUALITY_3840x2160.rawValue:
          if #available(iOS 9.0, *) {
            useQuality = AVAssetExportPreset3840x2160
          } else {
            useQuality = AVAssetExportPresetPassthrough
          }
          
        default:
          useQuality = AVAssetExportPresetPassthrough
        }
        
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        if !compatiblePresets.contains(useQuality) {
          useQuality = AVAssetExportPresetPassthrough
        }
        return useQuality
      }
    }
    

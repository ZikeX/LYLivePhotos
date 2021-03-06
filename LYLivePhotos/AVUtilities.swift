import UIKit
import AVFoundation

let videoQueue = DispatchQueue(label: "com.martinli.video")

class AVUtilities {
    
    static func reverse(_ original: AVAsset, outputURL: URL, completion: @escaping (AVAsset) -> Void) {
        
        // Initialize the reader

        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: original)
        } catch {
            print("could not initialize reader.")
            return
        }
        
        guard let videoTrack = original.tracks(withMediaType: AVMediaType.video).last else {
            print("could not retrieve the video track.")
            return
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.add(readerOutput)
        
        reader.startReading()
        
        // read in samples
        
        var samples: [CMSampleBuffer] = []
        while let sample = readerOutput.copyNextSampleBuffer() {
            samples.append(sample)
        }
        
        // Initialize the writer
        
        let writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        let videoCompositionProps = [AVVideoAverageBitRateKey: videoTrack.estimatedDataRate]
        var writerOutputSettings = [String : Any]()
        if #available(iOS 11.0, *) {
            writerOutputSettings = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: videoTrack.naturalSize.width,
                AVVideoHeightKey: videoTrack.naturalSize.height,
                AVVideoCompressionPropertiesKey: videoCompositionProps
                ] as [String : Any]
        } else {
            writerOutputSettings = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoWidthKey: videoTrack.naturalSize.width,
                AVVideoHeightKey: videoTrack.naturalSize.height,
                AVVideoCompressionPropertiesKey: videoCompositionProps
                ] as [String : Any]
        }
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: writerOutputSettings)
        writerInput.expectsMediaDataInRealTime = false
        writerInput.transform = videoTrack.preferredTransform
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(samples.first!))
        
        videoQueue.async {
            for (index, sample) in samples.enumerated() {
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample)
                let imageBufferRef = CMSampleBufferGetImageBuffer(samples[samples.count - 1 - index])
                while !writerInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                pixelBufferAdaptor.append(imageBufferRef!, withPresentationTime: presentationTime)
                
            }
            
            writer.finishWriting {
                DispatchQueue.main.async {
                    completion(AVAsset(url: outputURL))
                }
            }
        }
        
        
    }
    
    static func loop(_ original: AVAsset, outputURL: URL, completion: @escaping (AVAsset) -> Void) {
        
        // Initialize the reader
        videoQueue.async {
        
            var reader: AVAssetReader! = nil
            do {
                reader = try AVAssetReader(asset: original)
            } catch {
                print("could not initialize reader.")
                return
            }
            
            guard let videoTrack = original.tracks(withMediaType: AVMediaType.video).last else {
                print("could not retrieve the video track.")
                return
            }
            
            let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
            reader.add(readerOutput)
            
            reader.startReading()
            
            // read in samples
            
            var samples: [CMSampleBuffer] = []
            while let sample = readerOutput.copyNextSampleBuffer() {
                samples.append(sample)
            }
            
            // Initialize the writer
            
            let writer: AVAssetWriter
            do {
                writer = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
            } catch let error {
                fatalError(error.localizedDescription)
            }
            
            let videoCompositionProps = [AVVideoAverageBitRateKey: videoTrack.estimatedDataRate]
            var writerOutputSettings = [String : Any]()
            if #available(iOS 11.0, *) {
                writerOutputSettings = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: videoTrack.naturalSize.width,
                    AVVideoHeightKey: videoTrack.naturalSize.height,
                    AVVideoCompressionPropertiesKey: videoCompositionProps
                    ] as [String : Any]
            } else {
                writerOutputSettings = [
                    AVVideoCodecKey: AVVideoCodecH264,
                    AVVideoWidthKey: videoTrack.naturalSize.width,
                    AVVideoHeightKey: videoTrack.naturalSize.height,
                    AVVideoCompressionPropertiesKey: videoCompositionProps
                    ] as [String : Any]
            }
            
            let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: writerOutputSettings)
            writerInput.expectsMediaDataInRealTime = false
            writerInput.transform = videoTrack.preferredTransform
            
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
            
            writer.add(writerInput)
            writer.startWriting()
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(samples.first!))
    
        
            for sample in samples {
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample)
                let imageBufferRef = CMSampleBufferGetImageBuffer(sample)
                while !writerInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                pixelBufferAdaptor.append(imageBufferRef!, withPresentationTime: presentationTime)
            }
            var time = CMSampleBufferGetPresentationTimeStamp(samples.last!)
            time.value += 20
            for sample in samples {
                var presentationTime = time
                presentationTime.value += CMSampleBufferGetPresentationTimeStamp(sample).value
                let imageBufferRef = CMSampleBufferGetImageBuffer(sample)
                while !writerInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                pixelBufferAdaptor.append(imageBufferRef!, withPresentationTime: presentationTime)
            }
            
            writer.finishWriting {
                DispatchQueue.main.async {
                    completion(AVAsset(url: outputURL))
                }
            }
        }
    }
    
    static func playback(_ original: AVAsset, outputURL: URL, completion: @escaping (AVAsset) -> Void) {
        
        videoQueue.async {
            // Initialize the reader
            
            var reader: AVAssetReader! = nil
            do {
                reader = try AVAssetReader(asset: original)
            } catch {
                print("could not initialize reader.")
                return
            }
            
            guard let videoTrack = original.tracks(withMediaType: AVMediaType.video).last else {
                print("could not retrieve the video track.")
                return
            }
            
            let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
            reader.add(readerOutput)
            
            reader.startReading()
            
            // read in samples
            
            var samples: [CMSampleBuffer] = []
            while let sample = readerOutput.copyNextSampleBuffer() {
                samples.append(sample)
            }
            
            // Initialize the writer
            
            let writer: AVAssetWriter
            do {
                writer = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
            } catch let error {
                fatalError(error.localizedDescription)
            }
            
            let videoCompositionProps = [AVVideoAverageBitRateKey: videoTrack.estimatedDataRate]
            var writerOutputSettings = [String : Any]()
            if #available(iOS 11.0, *) {
                writerOutputSettings = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: videoTrack.naturalSize.width,
                    AVVideoHeightKey: videoTrack.naturalSize.height,
                    AVVideoCompressionPropertiesKey: videoCompositionProps
                    ] as [String : Any]
            } else {
                writerOutputSettings = [
                    AVVideoCodecKey: AVVideoCodecH264,
                    AVVideoWidthKey: videoTrack.naturalSize.width,
                    AVVideoHeightKey: videoTrack.naturalSize.height,
                    AVVideoCompressionPropertiesKey: videoCompositionProps
                    ] as [String : Any]
            }
            
            let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: writerOutputSettings)
            writerInput.expectsMediaDataInRealTime = false
            writerInput.transform = videoTrack.preferredTransform
            
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
            
            writer.add(writerInput)
            writer.startWriting()
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(samples.first!))
        
        
            for sample in samples {
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample)
                let imageBufferRef = CMSampleBufferGetImageBuffer(sample)
                while !writerInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                pixelBufferAdaptor.append(imageBufferRef!, withPresentationTime: presentationTime)
            }
            var time = CMSampleBufferGetPresentationTimeStamp(samples.last!)
            time.value += 20
            for (index, sample) in samples.enumerated() {
                var presentationTime = time
                presentationTime.value += CMSampleBufferGetPresentationTimeStamp(sample).value
                let imageBufferRef = CMSampleBufferGetImageBuffer(samples[samples.count - 1 - index])
                while !writerInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                pixelBufferAdaptor.append(imageBufferRef!, withPresentationTime: presentationTime)
                
            }
            
            writer.finishWriting {
                DispatchQueue.main.async {
                    completion(AVAsset(url: outputURL))
                }
            }
        }
    }
}


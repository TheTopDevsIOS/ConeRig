//
//  VideoViewController.swift
//  ConeRig
//
//  Created by Mac on 05.07.2022.
//

import UIKit
import MLKitVision
import MLKitPoseDetection
import AVKit

class VideoViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var linesView: LinesView!
    @IBOutlet weak var linesViewHeightConstraint: NSLayoutConstraint!
    
//    let linesView = LinesView()

    let captureSessionQueue = DispatchQueue(label: "CaptureSessionQueue")
    let captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var visionImage: VisionImage?
    
    var poseDetector:PoseDetector = {
        let options = PoseDetectorOptions()
        options.detectorMode = .stream
        return PoseDetector.poseDetector(options: options)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLivePreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.captureSession.startRunning()
    }
    
    func setupLivePreview() {
        captureSession.sessionPreset = .medium
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video) else { print("Unable to access back camera!"); return }
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(backCamera.activeFormat.formatDescription)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            self.captureSession.addInput(input)
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: captureSessionQueue)
        self.captureSession.addOutput(output)
        
        

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer)
        
        //        let dimensions = CMVideoFormatDescriptionGetDimensions(backCamera.activeFormat.formatDescription)
        //
        //        self.linesViewHeightConstraint.constant = CGFloat(dimensions.height) * videoPreviewLayer.frame.size.width / CGFloat(dimensions.width)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {[weak self]in
                guard let self = self else {return}
                self.videoPreviewLayer.frame = self.previewView.bounds
                self.linesView.frame = self.previewView.bounds
            }
        }
    }
    
    func imageOrientation(deviceOrientation: UIDeviceOrientation, cameraPosition: AVCaptureDevice.Position) -> UIImage.Orientation {
      switch deviceOrientation {
      case .portrait:
        return cameraPosition == .front ? .leftMirrored : .right
      case .landscapeLeft:
        return cameraPosition == .front ? .downMirrored : .up
      case .portraitUpsideDown:
        return cameraPosition == .front ? .rightMirrored : .left
      case .landscapeRight:
        return cameraPosition == .front ? .upMirrored : .down
      case .faceDown, .faceUp, .unknown:
        return .up
      }
    }
    
    func process(withBuffer sampleBuffer: CMSampleBuffer) {
        let image = VisionImage(buffer: sampleBuffer)
//        image.orientation = imageOrientation(deviceOrientation: UIDevice.current.orientation, cameraPosition: cameraPosition)
    }
}


extension VideoViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard nil == visionImage else { return }
        visionImage = VisionImage(buffer: sampleBuffer)
        
    }
}
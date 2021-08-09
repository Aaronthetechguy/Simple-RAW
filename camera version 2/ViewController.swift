//
//  ViewController.swift
//  camera version 2
//
//  Created by Aaron Goldgewert on 11/5/20.
//


import UIKit
import AVFoundation

class ViewController: UIViewController {
    //MARK:- Vars
    var captureSession : AVCaptureSession!
    
    var backCamera : AVCaptureDevice!
    var frontCamera : AVCaptureDevice!
    var backInput : AVCaptureInput!
    var frontInput : AVCaptureInput!
    
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    var videoOutput : AVCaptureVideoDataOutput!
    var photoOutput = AVCapturePhotoOutput()
    var takePicture = false
    var backCameraOn = true
    

    //MARK:- View Components
    let switchCameraButton : UIButton = {
            let button = UIButton()
            let image = UIImage(named: "switchcamera")?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
            button.tintColor = .white
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
        
        let captureImageButton : UIButton = {
            let button = UIButton()
            button.backgroundColor = .white
            button.tintColor = .white
            button.layer.cornerRadius = 25
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
//MARK:- Life Cycle
    let capturedImageView = CapturedImageView()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
        setupAndStartCaptureSession()
    }
    //MARK:- Camera Setup
       func setupAndStartCaptureSession(){
           DispatchQueue.global(qos: .userInitiated).async{
               //init session
               self.captureSession = AVCaptureSession()
               //start configuration
               self.captureSession.beginConfiguration()
               
               //session specific configuration
               if self.captureSession.canSetSessionPreset(.photo) {
                   self.captureSession.sessionPreset = .photo
               }
               self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
               
               //setup inputs
               self.setupInputs()
               
               DispatchQueue.main.async {
                   //setup preview layer
                   self.setupPreviewLayer()
               }
            self.setupOutput()
               //commit configuration
               self.captureSession.commitConfiguration()
               //start running it
               self.captureSession.startRunning()
           }
       }
       
    func setupInputs(){
        //get back camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            //handle this appropriately for production purposes
            fatalError("no back camera")
        }
        
        //get front camera
      /*  if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            fatalError("no front camera")
        }*/
        
        //now we need to create an input objects from our devices
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }
        
       /* guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("could not create input device from front camera")
        }
        frontInput = fInput
        if !captureSession.canAddInput(frontInput) {
            fatalError("could not add front camera input to capture session")
        }*/
        
        //connect back camera input to session
        captureSession.addInput(backInput)
    }
    func setupOutput() {
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "video queue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if captureSession.canAddOutput(videoOutput){
            captureSession.addOutput(videoOutput) } else {
                fatalError("could not add video output")
            }
        videoOutput.connections.first?.videoOrientation = .portrait
       photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported

        guard self.captureSession.canAddOutput(photoOutput) else { return }
        self.captureSession.sessionPreset = .photo
        self.captureSession.addOutput(photoOutput)
        if #available(iOS 14.3, *) {
            photoOutput.isAppleProRAWEnabled = photoOutput.isAppleProRAWSupported
        } else {
            // Fallback on earlier versions
            fatalError("u are using an old ios version.")
        }

        
    }
       func setupPreviewLayer(){
           previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
           view.layer.insertSublayer(previewLayer, below: switchCameraButton.layer)
           previewLayer.frame = self.view.layer.frame
       }
    func switchCameraInput() {
        switchCameraButton.isUserInteractionEnabled = false
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            backCameraOn = true
        }
        videoOutput.connections.first?.videoOrientation = .portrait
        videoOutput.connections.first?.isVideoMirrored = !backCameraOn
        captureSession.commitConfiguration()
        switchCameraButton.isUserInteractionEnabled = true
        
    }
    
    @objc func captureImage(_ sender: UIButton?){
        takePicture = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

    }
    @objc func switchCamera(_ sender: UIButton?){
        switchCameraInput()
    }
    

}

var captureDelegates = Dictionary<Int64, RAWCaptureDelegate>()

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !takePicture {return}
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        let uiImage = UIImage(ciImage: ciImage)
        DispatchQueue.main.async {
            self.capturedImageView.image = uiImage
        }
        if #available(iOS 14.3, *) {
            let query = self.photoOutput.isAppleProRAWEnabled ?
                { AVCapturePhotoOutput.isAppleProRAWPixelFormat($0) } :
                { AVCapturePhotoOutput.isBayerRAWPixelFormat($0) }
            
            // Retrieve the RAW format, favoring Apple ProRAW when enabled.
            guard let rawFormat =
                    self.photoOutput.availableRawPhotoPixelFormatTypes.first(where: query) else {
                fatalError("No RAW format found.")
            }

            // Capture a RAW format photo, along with a processed format photo.
            let processedFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
            let photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat, processedFormat: processedFormat)

            // Create a delegate to monitor the capture process.
            let delegate = RAWCaptureDelegate()
            captureDelegates[photoSettings.uniqueID] = delegate

            // Remove the delegate reference when it finishes its processing.
            delegate.didFinish = {
                captureDelegates[photoSettings.uniqueID] = nil
            }

            // Tell the output to capture the photo.
            photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
            
            takePicture = !takePicture
        } else {
            // Fallback on earlier versions
            fatalError("ios version too old and I'm too lazy to fix it")
        }
   
         
    }
}

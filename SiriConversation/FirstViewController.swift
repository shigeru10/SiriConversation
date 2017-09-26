//
//  FirstViewController.swift
//  SiriConversation
//
//  Created by SuzukiShigeru on 2017/08/16.
//  Copyright © 2017年 Shigeru Suzuki. All rights reserved.
//

import Foundation
import UIKit
import Speech
import RealmSwift

class FirstViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    let realm = try! Realm()
    var words: [Word]? = nil
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var correctAnswerLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var answerImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var word = realm.objects(Word.self).first
        
        correctAnswerLabel.isHidden = true
        answerImage.isHidden = true
        
        speechRecognizer.delegate = self
        answerLabel.text = ""
        
        questionLabel.text = word?.question
        correctAnswerLabel.text = word?.answer
        
        recordButton.setTitle("Start Recording", for: [])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation { [weak self] in
                guard let strongSelf = self else { return }
                switch authStatus {
                case .authorized:
                    strongSelf.recordButton.isEnabled = true
                    strongSelf.recordButton.setTitle("Start Recording", for: .disabled)
                case .denied:
                    strongSelf.recordButton.isEnabled = false
                    strongSelf.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                case .restricted:
                    strongSelf.recordButton.isEnabled = false
                    strongSelf.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                case .notDetermined:
                    strongSelf.recordButton.isEnabled = false
                    strongSelf.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    
    private func startRecording() throws {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audiosession = AVAudioSession.sharedInstance()
        try audiosession.setCategory(AVAudioSessionCategoryRecord)
        try audiosession.setMode(AVAudioSessionModeMeasurement)
        try audiosession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let strongSelf = self else { return }
            var isFinal = false
            
            if let _result = result {
                strongSelf.answerLabel.text = _result.bestTranscription.formattedString + "."
                
                if strongSelf.answerLabel.text == strongSelf.correctAnswerLabel.text {
                    strongSelf.audioEngine.stop()
                    recognitionRequest.endAudio()
                    strongSelf.recordButton.isEnabled = false
                    strongSelf.recordButton.setTitle("Stopping", for: .disabled)
                    strongSelf.answerImage.image = UIImage(named: "correct")
                    strongSelf.answerImage.isHidden = false
                    strongSelf.correctAnswerLabel.isHidden = false
                }
                isFinal = _result.isFinal
                if isFinal && strongSelf.answerImage.isHidden {
                    strongSelf.answerImage.image = UIImage(named: "incorrect")
                    strongSelf.answerImage.isHidden = false
                    strongSelf.correctAnswerLabel.isHidden = false
                }
            } else {
                if strongSelf.answerImage.isHidden {
                    strongSelf.answerLabel.text = "No answer..."
                    strongSelf.answerImage.image = UIImage(named: "incorrect")
                    strongSelf.answerImage.isHidden = false
                    strongSelf.correctAnswerLabel.isHidden = false
                }
            }
            
            if error != nil || isFinal {
                strongSelf.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                strongSelf.recognitionRequest = nil
                strongSelf.recognitionTask = nil
                
                strongSelf.recordButton.isEnabled = true
                strongSelf.recordButton.setTitle("Start next question", for: [])
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        answerLabel.text = "Let's talk!!"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("Start Recording", for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition not available", for: .disabled)
        }
    }
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        recordButton.setTitle("Stop", for: .normal)
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Stopping", for: .disabled)
        } else {
            do {
                try startRecording()
            } catch {
                fatalError("uneble start recording")
            }
            
            answerImage.isHidden = true
            correctAnswerLabel.isHidden = true
        }
    }
    
}


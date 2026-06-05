import Flutter
import AVFoundation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let tonePlayer = ScaleBuddyTonePlayer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScaleBuddyAudio") else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "scale_buddy/audio",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "playTone":
        guard
          let arguments = call.arguments as? [String: Any],
          let frequency = arguments["frequency"] as? Double,
          let durationMs = arguments["durationMs"] as? Int
        else {
          result(FlutterError(code: "bad_args", message: "Missing tone arguments", details: nil))
          return
        }

        self?.tonePlayer.play(frequency: frequency, durationMs: durationMs)
        result(nil)
      case "stop":
        self?.tonePlayer.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

final class ScaleBuddyTonePlayer {
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private let sampleRate: Double = 44100

  init() {
    engine.attach(player)
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    engine.connect(player, to: engine.mainMixerNode, format: format)
  }

  func play(frequency: Double, durationMs: Int) {
    stop()

    let frameCount = AVAudioFrameCount(sampleRate * Double(durationMs) / 1000)
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
      return
    }

    buffer.frameLength = frameCount
    let samples = buffer.floatChannelData![0]
    let fadeFrames = max(1, min(Int(sampleRate / 100), Int(frameCount) / 2))

    for frame in 0..<Int(frameCount) {
      let fadeIn = min(1.0, Double(frame) / Double(fadeFrames))
      let fadeOut = min(1.0, Double(Int(frameCount) - frame) / Double(fadeFrames))
      let envelope = Float(min(fadeIn, fadeOut))
      let wave = sin(2.0 * Double.pi * Double(frame) * frequency / sampleRate)
      samples[frame] = Float(wave) * envelope * 0.28
    }

    do {
      if !engine.isRunning {
        try engine.start()
      }
      player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
      player.play()
    } catch {
      stop()
    }
  }

  func stop() {
    player.stop()
  }
}

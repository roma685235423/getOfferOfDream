import Foundation
import AVFoundation

// MARK: - AudioPlayerService
/**
 Сервис воспроизведения аудио файлов.

 Данный сервис предоставляет функционал для воспроизведения аудио файлов в приложении.
 Он позволяет добавлять аудио события в очередь воспроизведения с учетом их приоритета и времени добавления.

 - Warning: **Важно!** Все звуковые файлы должны находиться в ресурсах приложения
 и быть предварительно загружены в приложение.
 Переименование звуковых файлов **СТРОГО ЗАПРЕЩЕНО**

 # Использование

 Для использования сервиса необходимо создать экземпляр класса `AudioPlayerService`, который является синглтоном.
 Далее, можно вызывать метод `playAudio(for:)`, передавая в него экземпляр типа `AudioEventType`,
 который описывает аудио событие.

 # Пример использования
 ```
 let audioService = AudioPlayerService.shared
 audioService.playAudio(for: .kilometerReached(10))
 ```
 Этот код добавит событие о достижении дистанции 10 км в очередь
 воспроизведения аудио файлов и начнет его воспроизведение.

 # Автоматическое воспроизведение

 Сервис автоматически переходит к следующему аудио файлу из очереди после завершения воспроизведения текущего файла.
 Это позволяет воспроизводить аудио файлы последовательно без необходимости вмешательства извне.

 # Приоритет событий

 Каждое аудио событие имеет свой приоритет. При добавлении нового события в очередь,
 оно помещается в соответствующее место в очереди с учетом приоритета.
 Более приоритетные события воспроизводятся раньше, чем менее приоритетные.

 # Отслеживание очереди

 Очередь воспроизведения можно отслеживать при необходимости, реализуя протокол `AudioPlayerServiceDelegate`.
 Этот протокол определяет метод `audioPlayerService(didUpdateQueue:)`,
 который вызывается при обновлении очереди воспроизведения.
 ```
 extension YourClass: AudioPlayerServiceDelegate {
 func audioPlayerService(didUpdateQueue eventQueue: [AudioEventType]) {
 // Обработка обновления очереди
 }
 }
 ```
 */
public final class AudioPlayerService: NSObject {

    // MARK: - Public Properties
    public weak var delegate: AudioPlayerServiceDelegate?
    public static let shared = AudioPlayerService()

    override init() {
        super.init()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    // MARK: - Private Properties
    private var player: AVAudioPlayer?
    private var eventQueue: [AudioEventType] = [] {
        didSet {
            delegate?.audioPlayerService(didUpdateQueue: eventQueue)
        }
    }

    // MARK: - Public Methods
    /**
     Добавляет аудио событие в очередь воспроизведения и начинает его воспроизведение.

     Этот метод добавляет указанное аудио событие в очередь воспроизведения аудио файлов.
     Очередь управляется сервисом воспроизведения, и события воспроизводятся в
     порядке их добавления с учетом их приоритета.
     После добавления события в очередь, его воспроизведение начинается автоматически,
     если в данный момент не проигрывается другой аудио файл.

     - Parameter event: Аудио событие, которое необходимо добавить в очередь воспроизведения.
     Это экземпляр типа `AudioEventType`, описывающий конкретное аудио событие.

     # Пример использования

     ```
     let audioService = AudioPlayerService.shared
     audioService.playAudio(for: .kilometerReached(10))
     ```

     Этот код добавит событие о достижении дистанции 10 км в
     очередь воспроизведения аудио файлов и начнет его воспроизведение.
     */
    public func playAudio(for event: AudioEventType) {
        let fileName = event.audioFileName
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Audio file \(fileName) not found")
            return
        }

        var insertIndex = eventQueue.count
        for (index, existingEvent) in eventQueue.enumerated() where event.priority() < existingEvent.priority() {
            insertIndex = index
            break
        }
        eventQueue.insert(event, at: insertIndex)

        guard player == nil || !player!.isPlaying else { return }
        play(fileURL: fileURL)

    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerService: AVAudioPlayerDelegate {

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let nextEvent = eventQueue.first else { return }

        if let fileURL = Bundle.main.url(forResource: nextEvent.audioFileName, withExtension: nil) {
            play(fileURL: fileURL)
        }
    }
}

// MARK: - Private Methods
private extension AudioPlayerService {

    func play(fileURL: URL) {
        do {
            self.player = try AVAudioPlayer(contentsOf: fileURL)
            self.player?.delegate = self
            self.player?.prepareToPlay()
            self.player?.play()
        } catch let error {
            print("Error playing audio: \(error.localizedDescription)")
        }
        eventQueue.removeFirst()
    }
}

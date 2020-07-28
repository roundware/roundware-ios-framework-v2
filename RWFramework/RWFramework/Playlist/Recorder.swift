
public class Recorder {
    /** Launches a background task to upload any pending recordings. */
    func start() {
    }

    /** Path of the given recording name as saved on disk. */
    private func recordingPath(for name: String) -> String {
        let parent = FileManager.default.url(for: .documentDirectory, in: .userDomainMask)
        return parent.appendingPathComponent("recordings")
          .appendingPathComponent(name)
    }

    /** List of recorded audio files to upload as assets. */
    private var pendingRecordings: [URL] {
        let fm = FileManager.default
        let parent = fm.url(for: .documentDirectory, in: .userDomainMask)
          .appendingPathComponent("recordings")
        return fm.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil)
    }
}

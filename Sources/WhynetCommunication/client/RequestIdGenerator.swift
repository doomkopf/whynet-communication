import Foundation

actor RequestIdGenerator {
    private var id = UUID().uuidString
    private var n = 0

    func generate() -> CommandRequestId {
        "\(id):\(nextNumber())"
    }

    private func nextNumber() -> Int {
        if n >= 999999 {
            n = 0
            id = UUID().uuidString
        }

        n += 1

        return n
    }
}

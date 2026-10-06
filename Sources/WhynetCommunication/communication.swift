struct Command: Codable {
    let pl: String
    let cmd: Int
    let id: CommandRequestId?
}

struct CommandResponse: Codable {
    let id: CommandRequestId
    let err: RequestErrorResultType?
    let pl: String?
}

public typealias CommandRequestId = String

public enum RequestErrorResultType: Int, Codable, Sendable {
    case ERROR = 0
    case TIMEOUT = 1
}

public struct RequestResult: Sendable {
    public let error: RequestErrorResultType?
    public let data: String?
}

public protocol Logger: Sendable {
    func logError(_ message: String, _ error: Error?)
}

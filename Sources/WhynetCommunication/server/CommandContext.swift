import WhynetCommons
import WhynetConnection

public struct CommandContext: Sendable {
    private let log: Logger
    private let jsonEncoder: StringJSONEncoder
    private let connection: Connection
    private let requestId: CommandRequestId

    init(
        log: Logger,
        jsonEncoder: StringJSONEncoder,
        connection: Connection,
        requestId: CommandRequestId,
    ) {
        self.log = log
        self.jsonEncoder = jsonEncoder
        self.connection = connection
        self.requestId = requestId
    }

    public func respond(_ result: String) async {
        let frame: String
        do {
            frame = try jsonEncoder.encode(
                CommandResponse(
                    id: requestId,
                    err: nil,
                    pl: result,
                ))
        } catch {
            log.logError("Error serializing Command", error)
            return
        }
        _ = await connection.write(frame)
    }
}

import WhynetCommons
import WhynetConnection

/// The server-side reception handling for commands through CommandHandlers.
public struct RequestCommandHandler: ReceptionListener {
    private let log: Logger
    private let jsonEncoder = StringJSONEncoder()
    private let jsonDecoder = StringJSONDecoder()
    private let commandHandlers: [Int: CommandHandler]

    public init(
        log: Logger,
        commandHandlers: [Int: CommandHandler],
    ) {
        self.log = log
        self.commandHandlers = commandHandlers
    }

    public func onReceived(connection: Connection, frame: String) async {
        let command: Command
        do {
            command = try jsonDecoder.decode(Command.self, frame)
        } catch {
            log.logError("Error deserializing Command", error)
            return
        }

        guard let handler = commandHandlers[command.cmd] else {
            log.logError("Unknown command \(command.cmd)", nil)
            await errorResponse(socket: connection, error: .ERROR, requestId: command.id)
            return
        }

        var ctx: CommandContext?
        if let requestId = command.id {
            ctx = CommandContext(
                log: log,
                jsonEncoder: jsonEncoder,
                connection: connection,
                requestId: requestId,
            )
        }

        await handler.handle(payload: command.pl, ctx: ctx)
    }

    private func errorResponse(
        socket: Connection, error: RequestErrorResultType, requestId: CommandRequestId?
    ) async {
        if let requestId {
            let frame: String
            do {
                frame = try jsonEncoder.encode(
                    CommandResponse(
                        id: requestId,
                        err: error,
                        pl: nil,
                    ))
            } catch {
                log.logError("Error serializing Command", error)
                return
            }
            _ = await socket.write(frame)
        }
    }
}

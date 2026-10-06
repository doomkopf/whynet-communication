import WhynetCommons
import WhynetConnection

struct ResponseCommandHandler: ReceptionListener {
    private let log: Logger
    private let jsonDecoder = StringJSONDecoder()
    private let resultCallbacks: ResultCallbacks

    init(
        log: Logger,
        resultCallbacks: ResultCallbacks,
    ) {
        self.log = log
        self.resultCallbacks = resultCallbacks
    }

    func onReceived(connection: Connection, frame: String) async {
        let response: CommandResponse
        do {
            response = try jsonDecoder.decode(CommandResponse.self, frame)
        } catch {
            log.logError("Error deserializing command=\(frame)", error)
            return
        }

        if let callback = await resultCallbacks.remove(response.id) {
            callback(RequestResult(error: response.err, data: response.pl))
            return
        }
    }
}

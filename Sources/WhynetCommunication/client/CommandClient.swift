import WhynetCommons
import WhynetConnection

/// Client for sending requests to process a specific command on a server and getting a result.
public struct CommandClient: Sendable {
    private let log: Logger
    private let jsonEncoder = StringJSONEncoder()
    private let requestIdGenerator = RequestIdGenerator()
    private let resultCallbacks: ResultCallbacks
    private let client: MultiClient

    public init(
        log: Logger,
        clientCacheEvictionTimeMillis: Int64,
        maxClients: Int,
        requestTimeoutMillis: Int64,
        resultCallbacksCacheMaxEntries: Int,
        resultCallbacksCacheScheduleIntervalMillis: Int64,
    ) throws {
        self.log = log

        resultCallbacks = try ResultCallbacks(
            requestTimeoutMillis: requestTimeoutMillis,
            cacheMaxEntries: resultCallbacksCacheMaxEntries,
            cacheScheduleIntervalMillis: resultCallbacksCacheScheduleIntervalMillis,
        )

        client = try MultiClient(
            sendQueueMaxEntries: resultCallbacksCacheMaxEntries,
            sendQueueEntryEvictionTimeMillis: requestTimeoutMillis,
            sendQueueScheduleIntervalMillis: resultCallbacksCacheScheduleIntervalMillis,
            clientCacheEvictionTimeMillis: clientCacheEvictionTimeMillis,
            maxClients: maxClients,
            receptionListener: ResponseCommandHandler(
                log: log,
                resultCallbacks: resultCallbacks,
            ),
        )
    }

    /// Requests to process a specific command on a server.
    public func request(host: HostAddress, cmd: Int, payload: String) async -> RequestResult {
        await withCheckedContinuation { c in
            Task {
                await requestCallback(host: host, cmd: cmd, payload: payload) { result in
                    c.resume(returning: result)
                }
            }
        }
    }

    private func requestCallback(
        host: HostAddress, cmd: Int, payload: String, callback: @escaping ResultCallback
    ) async {
        let requestId = await requestIdGenerator.generate()

        await resultCallbacks.put(requestId: requestId, callback: callback)

        let frame: String
        do {
            frame = try jsonEncoder.encode(Command(pl: payload, cmd: cmd, id: requestId))
        } catch {
            log.logError("Error serializing Command", error)
            return
        }
        await client.sendCallback(host: host, frame: frame) { success in
            if !success {
                Task {
                    if let removedCallback = await self.resultCallbacks.remove(requestId) {
                        removedCallback(
                            RequestResult(
                                error: .TIMEOUT, data: nil))
                    }
                }
            }
        }
    }

    public func shutdown() async {
        await client.shutdown()
        await resultCallbacks.shutdown()
    }
}

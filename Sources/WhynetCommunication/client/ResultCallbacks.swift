import WhynetCommons

typealias ResultCallback = @Sendable (_ result: RequestResult) -> Void

actor ResultCallbacks: CacheListener {
    private let cache: any Cache<CommandRequestId, ResultCallback>
    private let cacheCleanTask: ScheduledTask

    init(
        requestTimeoutMillis: Int64,
        cacheMaxEntries: Int,
        cacheScheduleIntervalMillis: Int64,
    ) throws {
        cache = try CacheImpl<CommandRequestId, ResultCallback>(
            entryEvictionTimeMillis: requestTimeoutMillis,
            maxEntries: cacheMaxEntries,
        )
        cacheCleanTask = scheduleInterval(millis: cacheScheduleIntervalMillis)

        cache.setListener(self)
        cacheCleanTask.setFuncNotAwaiting {
            await self.cleanCache()
        }
    }

    private func cleanCache() {
        cache.cleanup()
    }

    nonisolated func onEntryEvicted(key: CommandRequestId, value: ResultCallback) {
        value(RequestResult(error: .TIMEOUT, data: nil))
    }

    func remove(_ requestId: CommandRequestId) -> ResultCallback? {
        return cache.remove(requestId)
    }

    func put(requestId: CommandRequestId, callback: @escaping ResultCallback) {
        cache.put(key: requestId, value: callback)
    }

    func shutdown() async {
        await cacheCleanTask.cancel()
    }
}

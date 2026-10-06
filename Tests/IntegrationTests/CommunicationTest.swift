import Testing
import WhynetConnection

@testable import WhynetCommunication

private let PORT = 9693

struct CommunicationTest {

    @Test
    func test() async throws {
        struct EchoCommandHandler: CommandHandler {
            func handle(payload: String, ctx: CommandContext?) async {
                await ctx?.respond(payload)
            }
        }

        struct NoopCommandHandler: CommandHandler {
            func handle(payload: String, ctx: CommandContext?) async {
            }
        }

        struct NoopLogger: Logger {
            func logError(_ message: String, _ error: Error?) {
            }
        }

        let UNKNOWN_COMMAND = 0
        let ECHO_COMMAND = 1
        let NOOP_COMMAND = 2

        let server = Server()
        try await server.start(
            port: PORT,
            receptionListener: RequestCommandHandler(
                log: NoopLogger(),
                commandHandlers: [
                    ECHO_COMMAND: EchoCommandHandler(),
                    NOOP_COMMAND: NoopCommandHandler(),
                ],
            ),
        )

        let client = try CommandClient(
            log: NoopLogger(),
            clientCacheEvictionTimeMillis: 10000,
            maxClients: 1,
            requestTimeoutMillis: 250,
            resultCallbacksCacheMaxEntries: 100,
            resultCallbacksCacheScheduleIntervalMillis: 100,
        )

        let host = HostAddress(
            host: "127.0.0.1",
            port: PORT,
        )

        var result = await client.request(host: host, cmd: ECHO_COMMAND, payload: "Hello")
        #expect(result.data == "Hello")

        result = await client.request(host: host, cmd: UNKNOWN_COMMAND, payload: "")
        #expect(result.error == .ERROR)

        result = await client.request(host: host, cmd: NOOP_COMMAND, payload: "")
        #expect(result.error == .TIMEOUT)

        await client.shutdown()
        await server.shutdown()
    }
}

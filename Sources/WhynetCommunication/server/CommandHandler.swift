public protocol CommandHandler: Sendable {
    func handle(payload: String, ctx: CommandContext?) async
}

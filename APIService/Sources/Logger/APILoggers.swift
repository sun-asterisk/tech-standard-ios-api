/// A namespace for different API loggers.
public enum APILoggers {
    
}

public extension APILoggers {
    /// Provides a shared instance of `CompactLogger`.
    ///
    /// - Returns: The shared instance of `CompactLogger`.
    static var compact: CompactLogger { CompactLogger.shared }
    
    /// Provides a shared instance of `IntermediateLogger`.
    ///
    /// - Returns: The shared instance of `IntermediateLogger`.
    static var intermediate: IntermediateLogger { IntermediateLogger.shared }
    
    /// Provides a shared instance of `VerboseLogger`.
    ///
    /// - Returns: The shared instance of `VerboseLogger`.
    static var verbose: VerboseLogger { VerboseLogger.shared }
}

import Foundation

/// A protocol for types that can be converted to JSON strings.
public protocol JSONConvertible {
    func toJSONString(prettyPrinted: Bool, maxLength: Int) -> String?
}

extension JSONConvertible {
    /// Converts the conforming type to a JSON string.
    ///
    /// - Parameters:
    ///   - prettyPrinted: Determines if the JSON string should be pretty printed.
    ///   - maxLength: The maximum length of the resulting string. Defaults to 0 (no limit).
    /// - Returns: A JSON string if the conversion is successful, otherwise nil.
    public func toJSONString(prettyPrinted: Bool = false, maxLength: Int = 0) -> String? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }
        
        let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted] : []
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: options)
            return jsonData.toUTF8String(maxLength: maxLength)
        } catch {
            return nil
        }
    }
}

/// Conforms Dictionary to JSONConvertible protocol.
extension Dictionary: JSONConvertible {

}

extension Data: JSONConvertible {
    /// Converts Data to a JSON string.
    ///
    /// - Parameters:
    ///   - prettyPrinted: Determines if the JSON string should be pretty printed.
    ///   - maxLength: The maximum length of the resulting string. Defaults to 0 (no limit).
    /// - Returns: A JSON string if the conversion is successful, otherwise nil.
    public func toJSONString(prettyPrinted: Bool = false, maxLength: Int = 0) -> String? {
        guard let jsonObject: Any = toJSON() ?? toJSONArray() else {
            return self.toUTF8String(maxLength: maxLength)
        }
        
        let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted] : []
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
            return jsonData.toUTF8String(maxLength: maxLength)
        } catch {
            return nil
        }
    }
}

extension Data {
    /// Converts Data to a JSON dictionary.
    ///
    /// - Returns: A dictionary if the Data can be successfully converted to JSON, otherwise nil.
    public func toJSON() -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
    }
    
    /// Converts Data to a JSON array.
    ///
    /// - Returns: An array if the Data can be successfully converted to JSON, otherwise nil.
    public func toJSONArray() -> [[String: Any]]? {
        try? JSONSerialization.jsonObject(with: self, options: []) as? [[String: Any]]
    }
    
    /// Converts Data to a UTF-8 string.
    ///
    /// - Parameters:
    ///   - maxLength: The maximum length of the resulting string. Defaults to 0 (no limit).
    ///   - addingEllipsisIfNeeded: Determines if ellipsis should be added if the string is truncated.
    /// - Returns: A UTF-8 string if the conversion is successful, otherwise nil.
    public func toUTF8String(maxLength: Int = 0, addingEllipsisIfNeeded: Bool = true) -> String? {
        let jsonString = String(data: self, encoding: .utf8)
        
        if let jsonString {
            if maxLength > 0 {
                return String(jsonString.prefix(maxLength))
                    + ((addingEllipsisIfNeeded && jsonString.count > maxLength) ? " ..." : "")
            }
            
            return jsonString
        }
        
        return nil
    }
}

import Foundation

extension Dictionary: JSONConvertible {

}

extension Data {
    func toJSONString(prettyPrinted: Bool, maxLength: Int = 0) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []) else {
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
    
    func toUTF8String(maxLength: Int = 0, addingEllipsisIfNeeded: Bool = true) -> String? {
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

protocol JSONConvertible {

}

extension JSONConvertible {
    func toJSONString(prettyPrinted: Bool = false, maxLength: Int = 0) -> String? {
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

import Foundation

/// One TLV8 entry: a 1-byte type, a 1-byte length and the value bytes.
///
/// HAP framing. A value of 255 bytes or less is a single entry. A longer
/// value is split into fragments of at most 255 bytes that share the entry
/// type; a multi-fragment value is terminated by a zero-length fragment of
/// the same type.
public struct TLV8Entry: Equatable {
    public let type: UInt8
    public let value: Data

    public init(type: UInt8, value: Data) {
        self.type = type
        self.value = value
    }
}

public enum TLV8 {

    /// Encodes `entries` into wire bytes. Values of more than 255 bytes are
    /// fragmented as described on `TLV8Entry`.
    public static func encode(_ entries: [TLV8Entry]) -> Data {
        var out = Data()
        for entry in entries {
            let value = entry.value
            if value.count <= 255 {
                out.append(entry.type)
                out.append(UInt8(value.count))
                out.append(contentsOf: value)
            } else {
                var offset = 0
                while offset < value.count {
                    let take = min(value.count - offset, 255)
                    out.append(entry.type)
                    out.append(UInt8(take))
                    out.append(contentsOf: value.subdata(in: offset..<offset + take))
                    offset += take
                }
                out.append(entry.type)
                out.append(0)
            }
        }
        return out
    }

    /// Decodes wire bytes back into entries. Returns `nil` when the input is
    /// truncated or malformed.
    public static func decode(_ data: Data) -> [TLV8Entry]? {
        var entries: [TLV8Entry] = []
        var pendingType: UInt8?
        var pending = Data()
        var awaiting = false // true while `pending` is part of an open fragmented value
        var i = 0

        while i + 2 <= data.count {
            let type = data[i]
            let length = Int(data[i + 1])
            i += 2
            guard i + length <= data.count else {
                return nil
            }
            let value = data.subdata(in: i..<i + length)
            i += length

            if length == 0 {
                if awaiting, pendingType == type {
                    // The zero-length fragment terminates the fragmented value.
                    entries.append(TLV8Entry(type: type, value: pending))
                    pendingType = nil
                    pending = Data()
                } else {
                    if let open = pendingType {
                        entries.append(TLV8Entry(type: open, value: pending))
                        pendingType = nil
                        pending = Data()
                    }
                    entries.append(TLV8Entry(type: type, value: Data()))
                }
                awaiting = false
            } else if awaiting, pendingType == type {
                // Continuation fragment of the fragmented value.
                pending.append(contentsOf: value)
            } else {
                if let open = pendingType {
                    entries.append(TLV8Entry(type: open, value: pending))
                }
                pendingType = type
                pending = value
                awaiting = length == 255
            }
        }

        if i != data.count {
            return nil
        }
        if let open = pendingType {
            entries.append(TLV8Entry(type: open, value: pending))
        }
        return entries
    }
}

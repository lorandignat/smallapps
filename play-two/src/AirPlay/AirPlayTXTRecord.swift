import Foundation
import Network

/// The TXT record published with the `_airplay._tcp` Bonjour service.
///
/// It carries no name: the advertised name is the Bonjour service instance name
/// (TASK-004), so it is not repeated here. The device id comes from
/// ``DeviceIdentity`` and is the only input, which keeps one install's record
/// identical across launches.
struct AirPlayTXTRecord: Equatable {

    /// `features`, folded into a single 64-bit value.
    ///
    /// AirPlay devices publish the mask as `0xLOWER,0xUPPER`, the pair being the
    /// 64-bit value `0xUPPERLOWER` (airplay2-rs, AIRPLAY_2_SPEC §2.1). Bit 38 is
    /// set here — `0x40` in the upper word — which is the unified media control
    /// bit every AirPlay 2 audio receiver advertises; the mask itself is the
    /// observed HomePod value `0x4A7FCA00,0x3C356BD0` from that document's
    /// "Known Device Feature Values" table, which is how
    /// openairplay/airplay2-receiver and shairport-sync describe themselves.
    /// Source chain: `docs/SPIKE-001-airplay2.md` names those two receiver
    /// implementations; this constant is their AP2 audio-receiver mask.
    static let features: UInt64 = 0x3C356BD04A7FCA00

    /// Model string. `AudioAccessory1,1` is the HomePod model the mask above
    /// belongs to: an AirPlay 2 audio receiver, not a TV.
    static let model = "AudioAccessory1,1"

    /// AirPlay software version. `366.0` is the first version that gates PTP
    /// (feature bit 41) and is well above the buffered-audio gate `354.54.6`.
    static let srcvers = "366.0"

    /// AirPlay 2 protocol version advertised as `vv`.
    static let version = "2"

    /// The canonical `AA:BB:CC:DD:EE:FF` device id this record describes.
    let deviceID: String

    /// Builds the record, or `nil` when `deviceID` is empty or not a valid
    /// device id. A caller with no record advertises nothing; it must report
    /// `.failed` rather than publish a malformed record.
    init?(deviceID: String) {
        guard DeviceIdentity.isValidDeviceID(deviceID) else { return nil }
        self.deviceID = deviceID
    }

    /// The record as Bonjour carries it: exactly `deviceid`, `features`,
    /// `model`, `srcvers` and `vv`.
    var dictionary: [String: String] {
        [
            "deviceid": deviceID,
            "features": "0x" + String(Self.features, radix: 16, uppercase: true),
            "model": Self.model,
            "srcvers": Self.srcvers,
            "vv": Self.version,
        ]
    }

    /// The record in the form `NWListener.Service` takes.
    var txtRecord: NWTXTRecord {
        NWTXTRecord(dictionary)
    }
}

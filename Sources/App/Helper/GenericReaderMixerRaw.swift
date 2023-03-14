import Foundation

protocol GenericVariableMixable: RawRepresentableString {
    /// Soil moisture or snow depth are cumulative processes and have offests if mutliple models are mixed
    var requiresOffsetCorrectionForMixing: Bool { get }
}

/// Mix differnet domains together, that offer the same or similar variable set
protocol GenericReaderMixerRaw {
    associatedtype Reader: GenericReaderProtocol
    
    var reader: [Reader] { get }
    init(reader: [Reader])
}

protocol GenericReaderMixer: GenericReaderMixerRaw {
    static func makeReader(domain: Reader.Domain, lat: Float, lon: Float, elevation: Float, mode: GridSelectionMode) throws -> Reader?
}

struct GenericReaderMixerSameDomain<Reader: GenericReaderProtocol>: GenericReaderMixerRaw, GenericReaderProtocol {    
    typealias MixingVar = Reader.MixingVar
    
    typealias Domain = Reader.Domain
    
    let reader: [Reader]
    
    init(reader: [Reader]) {
        self.reader = reader
    }
}

/// Requirements to the reader in order to mix. Could be a GenericReaderDerived or just GenericReader
protocol GenericReaderProtocol {
    associatedtype MixingVar: GenericVariableMixable
    associatedtype Domain
    
    var modelLat: Float { get }
    var modelLon: Float { get }
    var modelElevation: ElevationOrSea { get }
    var targetElevation: Float { get }
    var modelDtSeconds: Int { get }
    var domain: Domain { get }
    
    func get(variable: MixingVar, time: TimerangeDt) throws -> DataAndUnit
    func prefetchData(variable: MixingVar, time: TimerangeDt) throws

    //init?(domain: Domain, lat: Float, lon: Float, elevation: Float, mode: GridSelectionMode) throws
    //init(domain: Domain, position: Range<Int>)
}

extension GenericReaderMixer {
    public init?(domains: [Reader.Domain], lat: Float, lon: Float, elevation: Float, mode: GridSelectionMode) throws {
        /// Initiaise highest resolution domain first. If `elevation` is NaN, use the elevation of the highest domain,
        var elevation = elevation
        
        let reader: [Reader] = try domains.reversed().compactMap { domain -> (Reader?) in
            guard let domain = try Self.makeReader(domain: domain, lat: lat, lon: lon, elevation: elevation, mode: mode) else {
                return nil
            }
            if elevation.isNaN {
                elevation = domain.modelElevation.numeric
            }
            return domain
        }.reversed()
        
        guard !reader.isEmpty else {
            return nil
        }
        self.init(reader: reader)
    }
}

extension GenericReaderMixerRaw {
    var modelLat: Float {
        reader.last!.modelLat
    }
    var modelLon: Float {
        reader.last!.modelLon
    }
    var modelElevation: ElevationOrSea {
        reader.last!.modelElevation
    }
    var targetElevation: Float {
        reader.last!.targetElevation
    }
    var modelDtSeconds: Int {
        reader.first!.modelDtSeconds
    }
    var domain: Reader.Domain {
        reader.last!.domain
    }

    /// Last domain is supposed to be the highest resolution domain
    /*public init?(domains: [Reader.Domain], lat: Float, lon: Float, elevation: Float, mode: GridSelectionMode) throws {
        /// Initiaise highest resolution domain first. If `elevation` is NaN, use the elevation of the highest domain,
        var elevation = elevation
        
        let reader: [Reader] = try domains.reversed().compactMap { domain -> (Reader?) in
            guard let domain = try Reader(domain: domain, lat: lat, lon: lon, elevation: elevation, mode: mode) else {
                return nil
            }
            if elevation.isNaN {
                elevation = domain.modelElevation.numeric
            }
            return domain
        }.reversed()
        
        guard !reader.isEmpty else {
            return nil
        }
        self.init(reader: reader)
    }*/
    
    func prefetchData(variable: Reader.MixingVar, time: TimerangeDt) throws {
        for reader in reader {
            try reader.prefetchData(variable: variable, time: time)
        }
    }
    
    func prefetchData(variables: [Reader.MixingVar], time: TimerangeDt) throws {
        try variables.forEach { variable in
            try prefetchData(variable: variable, time: time)
        }
    }
    
    func get(variable: Reader.MixingVar, time: TimerangeDt) throws -> DataAndUnit {
        // Last reader return highest resolution data. therefore reverse iteration
        // Integrate now lower resolution models
        var data: [Float]? = nil
        var unit: SiUnit? = nil
        if variable.requiresOffsetCorrectionForMixing {
            for r in reader.reversed() {
                let d = try r.get(variable: variable, time: time)
                if data == nil {
                    // first iteration
                    data = d.data
                    unit = d.unit
                    data?.deltaEncode()
                } else {
                    data?.integrateIfNaNDeltaCoded(d.data)
                }
                if data?.containsNaN() == false {
                    break
                }
            }
            // undo delta operation
            data?.deltaDecode()

        } else {
            // default case, just place new data in 1:1
            for r in reader.reversed() {
                let d = try r.get(variable: variable, time: time)
                if data == nil {
                    // first iteration
                    data = d.data
                    unit = d.unit
                } else {
                    data?.integrateIfNaN(d.data)
                }
                if data?.containsNaN() == false {
                    break
                }
            }
        }
        guard let data, let unit else {
            fatalError("Expected data in mixer for variable \(variable)")
        }
        return DataAndUnit(data, unit)
    }
}

extension VariableOrDerived: GenericVariableMixable where Raw: GenericVariableMixable, Derived: GenericVariableMixable {
    var requiresOffsetCorrectionForMixing: Bool {
        switch self {
        case .raw(let raw):
            return raw.requiresOffsetCorrectionForMixing
        case .derived(let derived):
            return derived.requiresOffsetCorrectionForMixing
        }
    }
}


extension Array where Element == Float {
    mutating func integrateIfNaN(_ other: [Float]) {
        for x in other.indices {
            if other[x].isNaN || !self[x].isNaN {
                continue
            }
            self[x] = other[x]
        }
    }
    mutating func integrateIfNaNDeltaCoded(_ other: [Float]) {
        for x in other.indices {
            if other[x].isNaN || !self[x].isNaN {
                continue
            }
            if x > 0 {
                self[x] = other[x-1] - other[x]
            } else {
                self[x] = other[x]
            }
        }
    }
}
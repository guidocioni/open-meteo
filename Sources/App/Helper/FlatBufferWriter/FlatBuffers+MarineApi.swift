import Foundation
import FlatBuffers
import OpenMeteoSdk


extension IconWaveDomainApi: ModelFlatbufferSerialisable {
    typealias HourlyVariable = IconWaveVariable
    
    typealias HourlyPressureType = ForecastPressureVariableType
    
    typealias DailyVariable = IconWaveVariableDaily
    
    static func encodeHourly(section: ApiSection<ForecastapiResult<Self>.SurfaceAndPressureVariable>, _ fbb: inout FlatBufferBuilder) -> Offset {
        let offsets = ForecastapiResult.encode(section: section, &fbb)
        let start = openmeteo_sdk_MarineHourly.startMarineHourly(&fbb)
        openmeteo_sdk_MarineHourly.add(time: section.timeFlatBuffers(), &fbb)
        for (surface, offset) in offsets.surface {
            switch surface {
            case .wave_height:
                openmeteo_sdk_MarineHourly.add(waveHeight: offset, &fbb)
            case .wave_period:
                openmeteo_sdk_MarineHourly.add(wavePeriod: offset, &fbb)
            case .wave_direction:
                openmeteo_sdk_MarineHourly.add(waveDirection: offset, &fbb)
            case .wind_wave_height:
                openmeteo_sdk_MarineHourly.add(windWaveHeight: offset, &fbb)
            case .wind_wave_period:
                openmeteo_sdk_MarineHourly.add(windWavePeriod: offset, &fbb)
            case .wind_wave_peak_period:
                openmeteo_sdk_MarineHourly.add(windWavePeakPeriod: offset, &fbb)
            case .wind_wave_direction:
                openmeteo_sdk_MarineHourly.add(windWaveDirection: offset, &fbb)
            case .swell_wave_height:
                openmeteo_sdk_MarineHourly.add(swellWaveHeight: offset, &fbb)
            case .swell_wave_period:
                openmeteo_sdk_MarineHourly.add(swellWavePeriod: offset, &fbb)
            case .swell_wave_peak_period:
                openmeteo_sdk_MarineHourly.add(swellWavePeakPeriod: offset, &fbb)
            case .swell_wave_direction:
                openmeteo_sdk_MarineHourly.add(swellWaveDirection: offset, &fbb)
            }
        }
        for (_, _) in offsets.pressure {
            fatalError("No pressure levels")
        }
        return openmeteo_sdk_MarineHourly.endMarineHourly(&fbb, start: start)
    }
    
    static func encodeCurrent(section: ApiSectionSingle<ForecastapiResult<Self>.SurfaceAndPressureVariable>, _ fbb: inout FlatBufferBuilder) throws -> Offset {
        let start = openmeteo_sdk_MarineCurrent.startMarineCurrent(&fbb)
        openmeteo_sdk_MarineCurrent.add(time: Int64(section.time.timeIntervalSince1970), &fbb)
        openmeteo_sdk_MarineCurrent.add(interval: Int32(section.dtSeconds), &fbb)
        for column in section.columns {
            switch column.variable {
            case .surface(let v):
                let offset = openmeteo_sdk_ValueAndUnit(value: column.value, unit: column.unit)
                switch v {
                case .wave_height:
                    openmeteo_sdk_MarineCurrent.add(waveHeight: offset, &fbb)
                case .wave_period:
                    openmeteo_sdk_MarineCurrent.add(wavePeriod: offset, &fbb)
                case .wave_direction:
                    openmeteo_sdk_MarineCurrent.add(waveDirection: offset, &fbb)
                case .wind_wave_height:
                    openmeteo_sdk_MarineCurrent.add(windWaveHeight: offset, &fbb)
                case .wind_wave_period:
                    openmeteo_sdk_MarineCurrent.add(windWavePeriod: offset, &fbb)
                case .wind_wave_peak_period:
                    openmeteo_sdk_MarineCurrent.add(windWavePeakPeriod: offset, &fbb)
                case .wind_wave_direction:
                    openmeteo_sdk_MarineCurrent.add(windWaveDirection: offset, &fbb)
                case .swell_wave_height:
                    openmeteo_sdk_MarineCurrent.add(swellWaveHeight: offset, &fbb)
                case .swell_wave_period:
                    openmeteo_sdk_MarineCurrent.add(swellWavePeriod: offset, &fbb)
                case .swell_wave_peak_period:
                    openmeteo_sdk_MarineCurrent.add(swellWavePeakPeriod: offset, &fbb)
                case .swell_wave_direction:
                    openmeteo_sdk_MarineCurrent.add(swellWaveDirection: offset, &fbb)
                }
                
            case .pressure(_):
                throw ForecastapiError.generic(message: "Pressure level variables currently not supported for flatbuffers encoding in current block")
            }
        }
        return openmeteo_sdk_MarineCurrent.endMarineCurrent(&fbb, start: start)
    }
    
    
    static func encodeDaily(section: ApiSection<DailyVariable>, _ fbb: inout FlatBufferBuilder) -> Offset {
        let offsets = ForecastapiResult<Self>.encode(section: section, &fbb)
        let start = openmeteo_sdk_MarineDaily.startMarineDaily(&fbb)
        openmeteo_sdk_MarineDaily.add(time: section.timeFlatBuffers(), &fbb)
        for (variable, offset) in zip(section.columns, offsets) {
            switch variable.variable {
            case .wave_height_max:
                openmeteo_sdk_MarineDaily.add(waveHeightMax: offset, &fbb)
            case .wind_wave_height_max:
                openmeteo_sdk_MarineDaily.add(windWaveHeightMax: offset, &fbb)
            case .swell_wave_height_max:
                openmeteo_sdk_MarineDaily.add(swellWaveHeightMax: offset, &fbb)
            case .wave_direction_dominant:
                openmeteo_sdk_MarineDaily.add(waveDirectionDominant: offset, &fbb)
            case .wind_wave_direction_dominant:
                openmeteo_sdk_MarineDaily.add(windWaveDirectionDominant: offset, &fbb)
            case .swell_wave_direction_dominant:
                openmeteo_sdk_MarineDaily.add(swellWaveDirectionDominant: offset, &fbb)
            case .wave_period_max:
                openmeteo_sdk_MarineDaily.add(wavePeriodMax: offset, &fbb)
            case .wind_wave_period_max:
                openmeteo_sdk_MarineDaily.add(windWavePeriodMax: offset, &fbb)
            case .wind_wave_peak_period_max:
                openmeteo_sdk_MarineDaily.add(windWavePeakPeriodMax: offset, &fbb)
            case .swell_wave_period_max:
                openmeteo_sdk_MarineDaily.add(swellWaveHeightMax: offset, &fbb)
            case .swell_wave_peak_period_max:
                openmeteo_sdk_MarineDaily.add(swellWavePeakPeriodMax: offset, &fbb)
            }
        }
        return openmeteo_sdk_MarineDaily.endMarineDaily(&fbb, start: start)
    }
    
    static func writeToFlatbuffer(section: ForecastapiResult<Self>.PerModel, _ fbb: inout FlatBufferBuilder, timezone: TimezoneWithOffset, fixedGenerationTime: Double?) throws {
        let generationTimeStart = Date()
        let hourly = (try section.hourly?()).map { encodeHourly(section: $0, &fbb) } ?? Offset()
        let current = try (try section.current?()).map { try encodeCurrent(section: $0, &fbb) } ?? Offset()
        let generationTimeMs = fixedGenerationTime ?? (Date().timeIntervalSince(generationTimeStart) * 1000)
        
        let result = openmeteo_sdk_MarineApiResponse.createMarineApiResponse(
            &fbb,
            latitude: section.latitude,
            longitude: section.longitude,
            elevation: section.elevation ?? .nan,
            model: section.model.flatBufferModel,
            generationtimeMs: Float32(generationTimeMs),
            utcOffsetSeconds: Int32(timezone.utcOffsetSeconds),
            timezoneOffset: timezone.identifier == "GMT" ? Offset() : fbb.create(string: timezone.identifier),
            timezoneAbbreviationOffset: timezone.abbreviation == "GMT" ? Offset() : fbb.create(string: timezone.abbreviation),
            hourlyOffset: hourly,
            currentOffset: current
        )
        fbb.finish(offset: result, addPrefix: true)
    }
    
    var flatBufferModel: openmeteo_sdk_MarineModel {
        switch self {
        case.best_match:
            return .bestMatch
        case .gwam:
            return .gwam
        case .ewam:
            return .ewam
        }
    }
}

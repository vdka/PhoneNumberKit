//
//  PhoneNumberKit.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 03/10/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import Foundation
#if os(iOS)
import CoreTelephony
#endif
    
public class PhoneNumberKit: NSObject {
    
    let metadata = Metadata.sharedInstance
    let regex = RegularExpressions.sharedInstance

    // MARK: Multiple Parsing
    
    public func parse(rawNumber: String, region: String? = nil) throws -> PhoneNumber {
        return try ParseManager().parsePhoneNumber(rawNumber, region: region ?? PhoneNumberKit().defaultRegionCode())
    }
    
    /**
    Fastest way to parse an array of phone numbers. Uses default region code.
    - Parameter rawNumbers: An array of raw number strings.
    - Returns: An array of valid PhoneNumber objects.
    */
    public func parseMultiple(_ rawNumbers: [String]) -> [PhoneNumber] {
        return self.parseMultiple(rawNumbers, region: self.defaultRegionCode())
    }
    
    /**
    Fastest way to parse an array of phone numbers. Uses custom region code.
    - Parameter rawNumbers: An array of raw number strings.
    - Parameter region: ISO 639 compliant region code.
    - Returns: An array of valid PhoneNumber objects.
    */
    public func parseMultiple(_ rawNumbers: [String], region: String) -> [PhoneNumber] {
        return ParseManager().parseMultiple(rawNumbers, region: region)
    }


    // MARK: Country and region code
    
    /**
    Get a list of all the countries in the metadata database
    - Returns: An array of ISO 639 compliant region codes.
    */
    public func allCountries() -> [String] {
        let results = metadata.items.map{$0.codeID}
        return results
    }
    
    /**
    Get an array of ISO 639 compliant region codes corresponding to a given country code.
    - Parameter code: An international country code (e.g 44 for the UK).
    - Returns: An optional array of ISO 639 compliant region codes.
    */
    public func countriesForCode(_ code: UInt64) -> [String]? {
        let results = metadata.fetchCountriesForCode(code)?.map{$0.codeID}
        return results
    }
    
    /**
    Get an main ISO 639 compliant region code for a given country code.
    - Parameter code: An international country code (e.g 1 for the US).
    - Returns: A ISO 639 compliant region code string.
    */
    public func mainCountryForCode(_ code: UInt64) -> String? {
        let country = metadata.fetchMainCountryMetadataForCode(code)
        return country?.codeID
    }

    /**
    Get the region code for the given phone number
    - Parameter number: The phone number
    - Returns: Region code, eg "US", or nil if the region cannot be determined
    */
    public func regionCodeForNumber(_ number: PhoneNumber) -> String? {
        let countryCode = number.countryCode
        let regions = metadata.items.filter { $0.countryCode == countryCode }
        if regions.count == 1 {
            return regions[0].codeID
        }

        return getRegionCodeForNumber(number, fromRegionList: regions)
    }

    private func getRegionCodeForNumber(_ number: PhoneNumber, fromRegionList regions: [MetadataTerritory]) -> String? {
        let nationalNumber = String(number.nationalNumber)
        let parser = PhoneNumberParser()
        for region in regions {
            if let leadingDigits = region.leadingDigits {
                if regex.matchesAtStart(leadingDigits, string: nationalNumber) {
                    return region.codeID
                }
            }
            if number.leadingZero && parser.checkNumberType("0" + nationalNumber, metadata: region) != .unknown {
                return region.codeID
            }
            if parser.checkNumberType(nationalNumber, metadata: region) != .unknown {
                return region.codeID
            }
        }
        return nil
    }
    
    /**
    Get an international country code for an ISO 639 compliant region code
    - Parameter country: ISO 639 compliant region code.
    - Returns: An international country code (e.g. 33 for France).
    */
    public func codeForCountry(_ country: String) -> UInt64? {
        let results = metadata.fetchMetadataForCountry(country)?.countryCode
        return results
    }
    
    /**
    Get a user's default region code,
    - Returns: A computed value for the user's current region - based on the iPhone's carrier and if not available, the device region.
    */
    public func defaultRegionCode() -> String {
#if os(iOS)
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        if let isoCountryCode = carrier?.isoCountryCode {
            return isoCountryCode.uppercased()
        }
#endif
        let currentLocale = Locale.current
        if #available(iOS 10.0, *) {
            let countryCode = currentLocale.countryCode
            return countryCode.uppercased()
        } else {
            if let countryCode = currentLocale.object(forKey: .countryCode) as? String {
                return countryCode.uppercased()
            }
        }
        return PhoneNumberConstants.defaultCountry
    }

}

//
//  Storage.swift
//  Cadence
//
//  Created by Ankush Sharma on 12/10/26.
//

import Foundation

// Saves and loads any Codable value as a JSON file.
enum Storage {
    private static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("Cadence", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder,
                                                 withIntermediateDirectories: true)
        return folder
    }

    static func save<T: Encodable>(_ value: T, as name: String) {
        let url = folder.appendingPathComponent("\(name).json")
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Could not save \(name): \(error)")
        }
    }

    static func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        let url = folder.appendingPathComponent("\(name).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

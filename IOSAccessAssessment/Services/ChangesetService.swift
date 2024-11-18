//
//  ChangesetService.swift
//  IOSAccessAssessment
//
//  Created by Mariana Piz on 11.11.2024.
//

import Foundation

class ChangesetService {
    
    private enum Constants {
        static let baseUrl = "https://osm.workspaces-stage.sidewalks.washington.edu/api/0.6"
        static let workspaceId = "168"
    }
    
    static let shared = ChangesetService()
    private init() {}
    
    private(set) var changesetId: String?
    
    func openChangeset(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseUrl)/changeset/create"),
              let accessToken = KeychainService().getValue(for: .accessToken) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.workspaceId, forHTTPHeaderField: "X-Workspace")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        
        guard let xmlData = """
            <osm>
                <changeset>
                    <tag k="created_by" v="GIG 1.0(4)" />
                    <tag k="comment" v="iOS OSM client" />
                </changeset>
            </osm>
            """
            .data(using: .utf8)
        else {
            print("Failed to create XML data.")
            return
        }

        request.httpBody = xmlData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data, let changesetId = String(data: data, encoding: .utf8) {
                self.changesetId = changesetId
                completion(.success(changesetId))
            } else {
                completion(.failure(NSError(domain: "ChangesetError",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Failed to open changeset"])))
            }
        }.resume()
    }
    
}

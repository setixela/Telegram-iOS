import Foundation
import SwiftSignalKit

// MARK: - TimeEndpoint

public struct TimeEndpoint: EndpointProtocol {
    public let endPoint = "http://worldtimeapi.org/api/timezone/Europe/Moscow"
    public let method: HTTPMethod = .get
}

// MARK: - ApiFetcher

public protocol ApiFetcherProtocol {
    func process(endpoint: EndpointProtocol) -> Signal<Data, ApiFetcherError>
}

public final class ApiFetcher: ApiFetcherProtocol {
    public func process(endpoint: EndpointProtocol) -> Signal<Data, ApiFetcherError> {
        return Signal { subsriber in
            guard let url = URL(string: endpoint.endPoint) else {
                subsriber.putError(.unknown)
                return EmptyDisposable
            }

            let method = endpoint.method
            let params = endpoint.body
            let headers = endpoint.headers

            var request = URLRequest(url: url)

            request.httpMethod = method.rawValue

            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            request.httpBody = params
                .map { (key: String, value: Any) in
                    key + "=\(value)"
                }
                .joined(separator: "&")
                .data(using: .utf8)

            let task = URLSession.shared.dataTask(with: request) { data, _, _ in

                guard let data = data else {
                    subsriber.putError(.unknown)
                    return
                }

                subsriber.putNext(data)
            }

            task.resume()

            return EmptyDisposable
        }
    }
}

// MARK: - HTTPMethod

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

// MARK: - Endpoints

public protocol EndpointProtocol {
    var endPoint: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: [String: Any] { get }
}

public extension EndpointProtocol {
    var headers: [String: String] { [:] }
    var body: [String: Any] { [:] }
}

// MARK: - ApiEngineResult

public struct ApiEngineResult {
    let data: Data?
    let response: URLResponse?
}

// MARK: - ApiFetcherError

public enum ApiFetcherError: Error {
    case unknown
}

// MARK: - TimeDateResult

public struct TimeDateResult: Codable {
    public let date: Date

    public enum CodingKeys: String, CodingKey {
        case date = "datetime"
    }
}

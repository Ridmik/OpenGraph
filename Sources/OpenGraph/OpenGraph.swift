import Foundation

public class OpenGraph {
    
    var session: URLSession?
    public static let shared = OpenGraph()
    
    private init() {}
    
    @discardableResult
    public func fetch(url: URL, headers: [String: String]? = nil, configuration: URLSessionConfiguration = .default, completion: @escaping (Result<[OpenGraphMetadata: String], Error>) -> Void) -> URLSessionDataTask {
        var mutableURLRequest = URLRequest(url: url)
        headers?.compactMapValues { $0 }.forEach {
            mutableURLRequest.setValue($1, forHTTPHeaderField: $0)
        }
        session?.invalidateAndCancel()
        session = URLSession(configuration: configuration)
        let task = session?.dataTask(with: mutableURLRequest, completionHandler: { [self] data, response, error in
            if let error = error {
                completion(.failure(error))
            } else {
                handleFetchResult(data: data, response: response, completion: completion)
            }
        })
        task?.resume()
        return task!
    }
    
    private func handleFetchResult(data: Data?, response: URLResponse?, completion: @escaping (Result<[OpenGraphMetadata: String], Error>) -> Void) {
        guard let data = data, let response = response as? HTTPURLResponse else {
            return
        }
        if !(200..<300).contains(response.statusCode) {
            completion(.failure(OpenGraphResponseError.unexpectedStatusCode(response.statusCode)))
        } else {
            guard let htmlString = String(data: data, encoding: String.Encoding.utf8) else {
                completion(.failure(OpenGraphParseError.encodingError))
                return
            }
            completion(.success(process(htmlString: htmlString)))
        }
    }

//    public init(htmlString: String) {
//        self = OpenGraph(htmlString: htmlString, parser: DefaultOpenGraphParser())
//    }
    
    func process(htmlString: String) -> [OpenGraphMetadata: String] {
        return DefaultOpenGraphParser().parse(htmlString: htmlString)
    }
    
//    public subscript (attributeName: OpenGraphMetadata) -> String? {
//        return source[attributeName]
//    }
}

private struct DefaultOpenGraphParser: OpenGraphParser {
}

import Vapor
import Menkyo
import CNIOOpenSSL
import Crypto

public struct Checkpoint: Middleware, Service {

    private var signatureCertChainUrlHeader = HTTPHeaderName("SignatureCertChainUrl")
    private var signatureHeader = HTTPHeaderName("Signature")
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        guard let bodyData = request.http.body.data,
            let signatureCertUrl = request.http.headers.firstValue(name: signatureCertChainUrlHeader),
            let signature = request.http.headers.firstValue(name: signatureHeader)
            else { throw Abort(.badRequest) }

        guard verifySignatureCertURL(url: signatureCertUrl) else { throw Abort(.badRequest) }

        //get pem
        let pemHTTPRequest = HTTPRequest(method: .GET, url: signatureCertUrl)
        let pemRequest = Request(http: pemHTTPRequest, using: request.sharedContainer)

        return try request.make(Client.self).send(pemRequest).flatMap { response in
            guard let data = response.http.body.data,
                let pemString = String(data: data, encoding: .utf8),
                let cert = self.getCertificate(pemString: pemString) else { throw Abort(.badRequest) }

            guard let altNames = cert.alternateNames,
                altNames.contains("echo-api.amazon.com"),
                let isValid = cert.valid,
                isValid else { throw Abort(.badRequest) }

            //validate
            guard try self.validate(signature: signature, ofBody: bodyData, usingCertificate: pemString) else {
                throw Abort(.badRequest)
            }

             //I sortreturn try next.respond(to: request)

            //verify timestamp
            return try request.content.decode(AmazonRequest.self).flatMap { amazonReq in
                guard self.validAlexaTimestamp(dateString: amazonReq.request.timestamp) else { throw Abort(.badRequest) }
                //finally, all is cleared, we can pass the request along

                return try next.respond(to: request)
            }
        }
    }

    private func validAlexaTimestamp(dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let currentDate = Date()
        guard let amazonDate = dateFormatter.date(from: dateString) else {
            return false
        }
        let toleranceDate = amazonDate.addingTimeInterval(150)
        return currentDate.isBetween(date: amazonDate, andDate: toleranceDate)
    }

    private func validate(signature: String, ofBody body: Data, usingCertificate cert: String) throws -> Bool {
        let decodedSignature = Data(base64Encoded: signature) ?? Data()
        let key = try RSAKey.public(certificate: cert)
        return try RSA(algorithm: .sha1).verify(decodedSignature, signs: body, key: key)
    }

    private func getCertificate(pemString: String) -> Certificate? {
        let bio = BIO_new(BIO_s_mem())
        defer {
            BIO_free(bio)
        }
        BIO_puts(bio, pemString)
        guard let certificate = PEM_read_bio_X509(bio, nil, nil, nil) else { return nil }
        defer {
            X509_free(certificate)
        }
        return readCertificateFile(certificate)
    }
    
    
    private func verifySignatureCertURL(url: String) -> Bool {
        guard let urlComponents = URLComponents(string: url) else { return false }
        guard urlComponents.scheme?.lowercased() == "https" else { return false }
        guard urlComponents.host?.lowercased() == "s3.amazonaws.com" else { return false }
        guard urlComponents.path.starts(with: "/echo.api/") else { return false }
        
        if let port = urlComponents.port {
            guard port == 443 else { return false }
        }
        
        return true
    }
}

extension Date {
    func isBetween(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self).rawValue * self.compare(date2).rawValue >= 0
    }
}

struct AmazonTimestamp: Content {
    var timestamp: String
}

struct AmazonRequest: Content {
    var request: AmazonTimestamp
}


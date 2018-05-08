import XCTest
@testable import Checkpoint
@testable import Vapor

final class CheckpointTests: XCTestCase {


    func testAlexa() throws {
        var headers = HTTPHeaders()
        headers.add(name: "SignatureCertChainUrl", value: "https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem")
        headers.add(name: "Signature", value: TestValues.signature)
        var request = HTTPRequest(method: .GET, url: URL(string: "/test/")!)
        request.body = HTTPBody(string: TestValues.body)
        request.headers = headers

        let response = try makeTestResponse(for: request)

        print(response.http.status)
    }


    private func makeTestResponse(for request: HTTPRequest) throws -> Response {
        var services = Services.default()
        var middlewareConfig = MiddlewareConfig()
        middlewareConfig.use(Checkpoint.self)
        services.register(Checkpoint())
        services.register(middlewareConfig)

        let app = try Application(services: services)
        let router = try app.make(Router.self)
        router.get("test") { req in
            return "TEST"
        }

        let responder = try app.make(Responder.self)
        let middleware = try app.make(MiddlewareConfig.self).resolve(for: app)
        let responderMiddleware = middleware.makeResponder(chainedto: responder)

        let wrappedRequest = Request(http: request, using: app)
        return try responderMiddleware.respond(to: wrappedRequest).wait()
    }
}

public struct TestValues {

    static let signature = "L2oiEsYrooddawZ5XvMI2ZLd+fTG/ARrr7phCVScFWTxqY1htbl9LXcOVroLop77VTjsMDw7j1CVzuynevhSbo7vWLc8L0K5TBV6guPxHNiRkCVARWMcwal2uZkBvGhFcBpvBmjNIUFKN8lWjCaAmpEbGSZHDomtFZONPzJm0nfJhzmrjVJr5vXNdxX0Al/r9qUGdbaWBVndnDbxilsAYTj8qq6/w6HmEUQc3zHEI1wG+KwXqHDP/rLbECWxfMi/whsOEdbCSoWPTAv59By3qzhE3bEVt0/I58+URI3lHqf3kdF6iANzTvfw5LGoTSCZLPtkPUWs9uG8XB4wHv0p+w=="

    static let body = """
{"version":"1.0","session":{"new":true,"sessionId":"amzn1.echo-api.session.708f5772-d1ea-4935-96b4-9c5fa110f465","application":{"applicationId":"amzn1.ask.skill.d8b05d0a-a771-4256-8c36-6017cf141e08"},"user":{"userId":"amzn1.ask.account.AGU5GV225RSQCNPUDKRHO7GDXGQ4LD2U6YDOFYO4S7XQQSHIIFQSSZWK6KRFHTBSQT7WYXMHKNWYGY4X7CCHY2Q7JWL32ACFMWG55KEFSSHY2FEN27JPD5BJ2KV34DJB5OCYFONWKF22YIMBDSHPBC2NGPEWVA6H2OGDEXWI4SD4VOYOTASEQSKGKUNAECXVGRJMFGF6OU642LY","accessToken":"sjFRJc25OJfYtq1gTKQ0EWoPlro1"}},"context":{"AudioPlayer":{"playerActivity":"IDLE"},"Display":{},"System":{"application":{"applicationId":"amzn1.ask.skill.d8b05d0a-a771-4256-8c36-6017cf141e08"},"user":{"userId":"amzn1.ask.account.AGU5GV225RSQCNPUDKRHO7GDXGQ4LD2U6YDOFYO4S7XQQSHIIFQSSZWK6KRFHTBSQT7WYXMHKNWYGY4X7CCHY2Q7JWL32ACFMWG55KEFSSHY2FEN27JPD5BJ2KV34DJB5OCYFONWKF22YIMBDSHPBC2NGPEWVA6H2OGDEXWI4SD4VOYOTASEQSKGKUNAECXVGRJMFGF6OU642LY","accessToken":"sjFRJc25OJfYtq1gTKQ0EWoPlro1"},"device":{"deviceId":"amzn1.ask.device.AHGA7IR5Y4RNEEM3OHX3UNKKSMBFHL4X7UY7GYKST2IXELCQXZZU6JY3DYWIZCTCFIRSALT2YD72GXKGHSVZOF56URPUL4XS7O3WG25BB5C4CKVW56FYBGVGOIX7CJ5BXJNY4R2PV4WOUBIKRIZRGCOLX5SKNREEWVXEAAMQBZ7QQ2SZ2QPLU","supportedInterfaces":{"AudioPlayer":{},"Display":{"templateVersion":"1.0","markupVersion":"1.0"}}},"apiEndpoint":"https://api.amazonalexa.com","apiAccessToken":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjEifQ.eyJhdWQiOiJodHRwczovL2FwaS5hbWF6b25hbGV4YS5jb20iLCJpc3MiOiJBbGV4YVNraWxsS2l0Iiwic3ViIjoiYW16bjEuYXNrLnNraWxsLmQ4YjA1ZDBhLWE3NzEtNDI1Ni04YzM2LTYwMTdjZjE0MWUwOCIsImV4cCI6MTUyNTcwNjYzNCwiaWF0IjoxNTI1NzAzMDM0LCJuYmYiOjE1MjU3MDMwMzQsInByaXZhdGVDbGFpbXMiOnsiY29uc2VudFRva2VuIjpudWxsLCJkZXZpY2VJZCI6ImFtem4xLmFzay5kZXZpY2UuQUhHQTdJUjVZNFJORUVNM09IWDNVTktLU01CRkhMNFg3VVk3R1lLU1QySVhFTENRWFpaVTZKWTNEWVdJWkNUQ0ZJUlNBTFQyWUQ3MkdYS0dIU1ZaT0Y1NlVSUFVMNFhTN08zV0cyNUJCNUM0Q0tWVzU2RllCR1ZHT0lYN0NKNUJYSk5ZNFIyUFY0V09VQklLUklaUkdDT0xYNVNLTlJFRVdWWEVBQU1RQlo3UVEyU1oyUVBMVSIsInVzZXJJZCI6ImFtem4xLmFzay5hY2NvdW50LkFHVTVHVjIyNVJTUUNOUFVES1JITzdHRFhHUTRMRDJVNllET0ZZTzRTN1hRUVNISUlGUVNTWldLNktSRkhUQlNRVDdXWVhNSEtOV1lHWTRYN0NDSFkyUTdKV0wzMkFDRk1XRzU1S0VGU1NIWTJGRU4yN0pQRDVCSjJLVjM0REpCNU9DWUZPTldLRjIyWUlNQkRTSFBCQzJOR1BFV1ZBNkgyT0dERVhXSTRTRDRWT1lPVEFTRVFTS0dLVU5BRUNYVkdSSk1GR0Y2T1U2NDJMWSJ9fQ.BHt96fCCZMGix-ZtWJnFSFPB3N746qS5qRlUkfVSiA4ntZlPBNjzcoqsOI20vKgIwIPpmjA9tmkt-amQQ4G29HxGO-_8ZlRY0oQjWybpKgFz_A0K-_vD06iaV8e3u7IdRDe1z8bRJxU5j36QCW7trwi9iO6vEPmsVu7wkSzUa5hxGod2G9t6WBZemZ1I_Qs8eOcbf6eHCcCWcH623JZstZd4IZizyVV6w7I8ttsA3Eh7DJP6SYVPXSdec_O0B8rjfynXOVxVB_B7XabOloSL8OXasyhKCgzeff2QMiIb-QVJY2M6px1vfCQN8OtX6roJf-HsqZ809qW41oTLWAvYsQ"}},"request":{"type":"IntentRequest","requestId":"amzn1.echo-api.request.971be73a-921a-40bf-b38b-49edba584f63","timestamp":"2018-05-07T14:23:54Z","locale":"en-US","intent":{"name":"GetSentenceIntent","confirmationStatus":"NONE"}}}
"""
}

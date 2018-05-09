# Checkpoint ✅
Checkpoint verifies incoming Alexa requests as requested By Amazon - [Amazon doc](https://developer.amazon.com/docs/custom-skills/host-a-custom-skill-as-a-web-service.html)

## Usage
  1. In `Package.swift` add 
  ```swift
  .package(url: "https://github.com/AAAstorga/alexa-verifier-provider.git", from: "0.1.0")
  ```
  
  2. You should only use this middleware on the route Amazon will be calling for your skill. To do this you can do something like this:
  ```swift
  import Checkpoint
  ...
  let alexa = router.grouped(Checkpoint.self)
  
  //Alexa.self would be your struct you use to decode the request send by Amazon to your service
  //You would need to most likely return a json following the specifications Amazon set
  alexa.post(Alexa.self, at: "alexa") { req, alexa -> String in
    //do stuff with alexa and return the proper response
    return "Hi Alexa!"
  }
  ```
  
  ## Authors

* **Austin Astorga** - *Main developer* - [My Github](https://github.com/aaastorga)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Vapor Discord (for helping me with all my issues <3)
* Shoutout to @vzsg for helping me with all the certificate stuff! Appreciate it.
  

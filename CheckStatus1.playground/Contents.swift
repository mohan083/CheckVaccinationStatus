import Foundation
import PlaygroundSupport
import AVFoundation
/*

 Get State IDs from here
//https://cdn-api.co-vin.in/api/v2/admin/location/states


 Get Districts IDs from mere

 use state ID (here it is `21`) from above APIs

 https://cdn-api.co-vin.in/api/v2/admin/location/districts/21

 */

func playNotification(){
  let player = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "blackberry_sms_tone", withExtension: "mp3")!)
  player.prepareToPlay()
  player.play() //The "some audio" mp3 file is in Resources folder
}

extension Date {
  func today(format : String = "dd-MM-YYYY") -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: date)
  }

  func dateAfter(days: Int, format : String = "dd-MM-YYYY") -> String {
    let date = Calendar.current.date(byAdding: .day, value: days, to: Date())!
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: date)
  }
}

struct Session: Decodable {
  let available_capacity: Int
  let min_age_limit: Int
  let available_capacity_dose1: Int
  let available_capacity_dose2: Int
}

struct Center: Decodable {
  let center_id: Int
  let name: String
  let address: String
  let pincode: Int
  let sessions: [Session]
}

struct Centers: Decodable {
  let centers: [Center]
}

struct APIError: Decodable {
  let error: String
}

let searchFor18PlusOnly = true
let searchForDose1Only = true
let daysAfter: Int = 0

let detailsedLogs = false

func fetchAllTheCenters() {

  print("Fetching Centers ...")

  URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
  PlaygroundPage.current.needsIndefiniteExecution = true
  let todayDateString = Date().dateAfter(days: daysAfter)
  let timeStamp = Date().timeIntervalSince1970

  let queryItems = [URLQueryItem(name: "district_id", value: "363"), URLQueryItem(name: "date", value: todayDateString), URLQueryItem(name: "_timestamp", value: "\(timeStamp)")]
  var urlComps = URLComponents(string: "https://cdn-api.co-vin.in/api/v2/appointment/sessions/calendarByDistrict")!
  urlComps.queryItems = queryItems
  let result = urlComps.url!
  let session = URLSession.shared
  let urlRequest = URLRequest(url: result)

  let task = session.dataTask(with: urlRequest) { (data, response, error) in

    // check for any errors
    guard error == nil else {
      print(error!)
      return
    }

    guard let responseData = data else {
      print("Error: did not receive data")
      return
    }

    do {
      let ageLimit: Int = searchFor18PlusOnly ? 18 : 45

      let results = try JSONDecoder().decode(Centers.self, from: responseData)
      for aCenter in results.centers {
        for aSession in aCenter.sessions {
          let forDoseOne: Int = searchForDose1Only ? aSession.available_capacity_dose1 : aSession.available_capacity_dose2
          if aSession.min_age_limit == ageLimit && forDoseOne > 0 {
            print("check this pincode \(aCenter.pincode)")
            playNotification()
            if detailsedLogs {
              print("Availability min_age_limit :\(aSession.min_age_limit) And OnlyFor Dose1? \(searchForDose1Only)")
            }
          }
        }
      }
      print("Fetching Done!")
    } catch  {

      do {
        let apiError = try JSONDecoder().decode(APIError.self, from: responseData)
        print("There is an API Error :  \(apiError.error)")
        return
      }
      catch  {
        print("error trying to convert error data \(error)")
        return
      }
    }
    PlaygroundPage.current.finishExecution()
  }
  task.resume()
}
  fetchAllTheCenters()


import Foundation
import HealthKit
import WatchKit
import Combine

class HeartRateMonitor: NSObject, ObservableObject {
    static let shared = HeartRateMonitor()
    
    private let healthStore = HKHealthStore()
    private var query: HKAnchoredObjectQuery?
    
    @Published var currentHeartRate: Double = 0.0
    
    private override init() {
        super.init()
    }
    
    // ✅ 1. Request permission
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set = [heartRateType]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit auth error: \(error.localizedDescription)")
            } else {
                print("HealthKit authorization success: \(success)")
            }
        }
    }
    
    // ✅ 2. Start monitoring
    func startMonitoring() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )
        
        query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] (_, samples, _, _, _) in
            self?.process(samples: samples)
        }
        
        query?.updateHandler = { [weak self] (_, samples, _, _, _) in
            self?.process(samples: samples)
        }
        
        if let query = query {
            healthStore.execute(query)
        }
    }
    
    // ✅ 3. Stop monitoring
    func stopMonitoring() {
        if let query = query {
            healthStore.stop(query)
        }
        query = nil
    }
    
    // ✅ 4. Process heart rate samples
    private func process(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        guard let sample = heartRateSamples.last else { return }
        let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        DispatchQueue.main.async {
            self.currentHeartRate = bpm
        }
    }
}


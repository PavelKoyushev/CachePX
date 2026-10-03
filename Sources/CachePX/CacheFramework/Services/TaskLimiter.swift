//
//  TaskLimiter.swift
//  CachePX
//
//  Created by Pavel on 27.09.2026.
//

/// Limits how many tasks run concurrently; extra callers queue and wait their turn.
///
/// Pair every `acquire()` with exactly one `release()`.
/// Waiting tasks do not observe cancellation until they're resumed.
actor TaskLimiter {
    
    private let maxConcurrentTasks: Int
    private var runningTasks = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(maxConcurrentTasks: Int) {
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    /// Reserves a slot, suspending until one is free.
    func acquire() async {
        if runningTasks < maxConcurrentTasks {
            runningTasks += 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        
        runningTasks += 1
    }
    
    /// Frees a slot and resumes the next waiter, if any.
    func release() {
        runningTasks -= 1
        
        guard !waiters.isEmpty else { return }
        let next = waiters.removeFirst()
        next.resume()
    }
}

import Foundation

open class UrlSessionTaskOperation: Operation {

    fileprivate let task: URLSessionTask
    fileprivate let lock: NSRecursiveLock

    fileprivate var isExecutingValue = false
    fileprivate var isCancelledValue = false
    fileprivate var isFinishedValue = false

    fileprivate static var taskStateKvoContext = 0

    public init(task: URLSessionTask) {
        assert(task.state == .suspended,
               "Task wrapped in `Operation` should not be started manually, " +
                   "else behaviour is undefined. Check that whole task lifecycle is handled only by this wrapper")
        self.task = task
        lock = NSRecursiveLock()
        super.init()
        task.addObserver(self, forKeyPath: #keyPath(URLSessionTask.state), options: [], context: &UrlSessionTaskOperation.taskStateKvoContext)
    }

    deinit {
        task.removeObserver(self, forKeyPath: #keyPath(URLSessionTask.state), context: &UrlSessionTaskOperation.taskStateKvoContext)
    }

    open override var isAsynchronous: Bool {
        return true
    }

    open override var isExecuting: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isExecutingValue
    }

    open override var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelledValue
    }

    open override var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isFinishedValue
    }

    open override func start() {
        lock.lock()
        defer { lock.unlock() }

        if !isExecutingValue {
            willChangeValue(forKey: #keyPath(isExecuting))
            isExecutingValue = true
            didChangeValue(forKey: #keyPath(isExecuting))

            if isCancelled {
                finish()
            } else {
                task.resume()
            }
        }
    }

    open override func cancel() {
        lock.lock()
        defer { lock.unlock() }

        if !isCancelledValue {
            willChangeValue(forKey: #keyPath(isCancelled))
            isCancelledValue = true
            didChangeValue(forKey: #keyPath(isCancelled))

            task.cancel()
        }
    }

    open func finish() {
        lock.lock()
        defer { lock.unlock() }

        if !isFinishedValue {
            willChangeValue(forKey: #keyPath(isExecuting))
            willChangeValue(forKey: #keyPath(isFinished))
            isExecutingValue = false
            isFinishedValue = true
            didChangeValue(forKey: #keyPath(isExecuting))
            didChangeValue(forKey: #keyPath(isFinished))
        }
    }

    open override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey: Any]?,
                                    context: UnsafeMutableRawPointer?) {

        if context == &UrlSessionTaskOperation.taskStateKvoContext {
            switch task.state {
            case .completed:
                if isExecuting {
                    finish()
                } else {
                    assert(isCancelled)
                    // do nothing as we should finish operation right away in start method
                }
            case .canceling where !isCancelled:
                cancel()
            default:
                break
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

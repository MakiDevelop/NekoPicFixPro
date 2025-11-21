//
//  MemoryMonitor.swift
//  NekoPicFixPro
//
//  系統記憶體壓力監控器
//

import Foundation
import Combine

/// 記憶體壓力等級
enum MemoryPressureLevel {
    case normal     // 正常
    case warning    // 警告
    case critical   // 危險
}

/// 記憶體監控器
class MemoryMonitor: ObservableObject {

    // MARK: - Singleton

    static let shared = MemoryMonitor()

    // MARK: - Published Properties

    @Published var memoryPressure: MemoryPressureLevel = .normal
    @Published var usedMemoryMB: Double = 0
    @Published var availableMemoryMB: Double = 0
    @Published var totalMemoryMB: Double = 0

    // MARK: - Properties

    private var dispatchSource: DispatchSourceMemoryPressure?
    private var updateTimer: Timer?

    /// 是否應該暫停處理（記憶體壓力過高）
    var shouldPauseProcessing: Bool {
        return memoryPressure == .critical
    }

    // MARK: - Initialization

    private init() {
        setupMemoryPressureMonitoring()
        startMemoryStatsUpdating()
        print("🧠 MemoryMonitor initialized")
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// 取得記憶體使用百分比
    var memoryUsagePercentage: Double {
        guard totalMemoryMB > 0 else { return 0 }
        return (usedMemoryMB / totalMemoryMB) * 100
    }

    /// 取得記憶體壓力描述
    var pressureDescription: String {
        switch memoryPressure {
        case .normal:
            return L10n.string("memory.normal")
        case .warning:
            return L10n.string("memory.warning")
        case .critical:
            return L10n.string("memory.critical")
        }
    }

    /// 停止監控
    func stopMonitoring() {
        dispatchSource?.cancel()
        dispatchSource = nil
        updateTimer?.invalidate()
        updateTimer = nil
        print("🧠 MemoryMonitor stopped")
    }

    // MARK: - Private Methods

    /// 設定記憶體壓力監控
    private func setupMemoryPressureMonitoring() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)

        source.setEventHandler { [weak self] in
            guard let self = self else { return }

            let event = source.data

            if event.contains(.critical) {
                self.memoryPressure = .critical
                print("🚨 Memory pressure: CRITICAL")
            } else if event.contains(.warning) {
                self.memoryPressure = .warning
                print("⚠️ Memory pressure: WARNING")
            } else {
                self.memoryPressure = .normal
                print("✅ Memory pressure: NORMAL")
            }
        }

        source.resume()
        dispatchSource = source
    }

    /// 開始定期更新記憶體統計
    private func startMemoryStatsUpdating() {
        updateMemoryStats()

        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMemoryStats()
        }
    }

    /// 更新記憶體統計資料
    private func updateMemoryStats() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, ptr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            print("⚠️ Failed to get memory statistics")
            return
        }

        // Calculate memory in MB
        let pageSize = Double(vm_kernel_page_size)
        let pageSizeMB = pageSize / 1024.0 / 1024.0

        let freePages = Double(stats.free_count)
        let activePages = Double(stats.active_count)
        let inactivePages = Double(stats.inactive_count)
        let wiredPages = Double(stats.wire_count)
        let compressedPages = Double(stats.compressor_page_count)

        // Total physical memory
        var size: UInt64 = 0
        var sizeLength = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &sizeLength, nil, 0)
        totalMemoryMB = Double(size) / 1024.0 / 1024.0

        // Available memory
        availableMemoryMB = freePages * pageSizeMB

        // Used memory
        usedMemoryMB = (activePages + inactivePages + wiredPages + compressedPages) * pageSizeMB

        // Auto-detect memory pressure based on usage
        let usagePercentage = memoryUsagePercentage

        // Update pressure level based on usage if not already critical
        if memoryPressure != .critical {
            if usagePercentage > 90 {
                memoryPressure = .warning
            } else if usagePercentage > 95 {
                memoryPressure = .critical
            } else if usagePercentage < 80 && memoryPressure == .warning {
                memoryPressure = .normal
            }
        }
    }

    /// 格式化記憶體大小顯示
    func formatMemorySize(_ mb: Double) -> String {
        if mb < 1024 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.2f GB", mb / 1024.0)
        }
    }
}

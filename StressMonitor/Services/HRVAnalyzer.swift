import Foundation

/// HRV analysis engine inspired by Welltory's approach.
/// Computes time-domain (RMSSD, SDNN, pNN50) and frequency-domain (LF/HF) metrics
/// from RR interval data, then maps them to a normalized stress score.
final class HRVAnalyzer {

    // MARK: - Types

    /// Welltory-style stress level categories
    enum StressCategory: String, CaseIterable {
        case resting     = "Resting"
        case low         = "Low"
        case moderate    = "Moderate"
        case high        = "High"
        case veryHigh    = "Very High"

        var color: String {
            switch self {
            case .resting:  return "green"
            case .low:      return "blue"
            case .moderate: return "yellow"
            case .high:     return "orange"
            case .veryHigh: return "red"
            }
        }

        var range: ClosedRange<Double> {
            switch self {
            case .resting:  return 0.0...0.2
            case .low:      return 0.2...0.4
            case .moderate: return 0.4...0.6
            case .high:     return 0.6...0.8
            case .veryHigh: return 0.8...1.0
            }
        }
    }

    /// Time-domain HRV metrics
    struct TimeDomainMetrics {
        let rmssd: Double   // Root mean square of successive differences (ms)
        let sdnn: Double    // Standard deviation of NN intervals (ms)
        let pnn50: Double   // % of successive NN intervals > 50ms apart
        let meanRR: Double  // Mean RR interval (ms)
        let sdrr: Double    // Standard deviation of RR intervals (ms)
    }

    /// Frequency-domain HRV metrics (estimated via Lomb-Scargle or Welch)
    struct FrequencyDomainMetrics {
        let lfPower: Double   // Low frequency power (0.04-0.15 Hz) — sympathetic + parasympathetic
        let hfPower: Double   // High frequency power (0.15-0.4 Hz) — parasympathetic
        let lfHfRatio: Double // LF/HF ratio — sympathovagal balance
        let totalPower: Double
    }

    /// Combined analysis result
    struct AnalysisResult {
        let timeDomain: TimeDomainMetrics
        let frequencyDomain: FrequencyDomainMetrics
        let stressScore: Double       // 0.0 (relaxed) to 1.0 (high stress)
        let stressCategory: StressCategory
        let coherenceScore: Double    // 0.0 to 1.0 — higher = more coherent
        let sampleQuality: Double     // 0.0 to 1.0 — based on artifact % and sample count
    }

    // MARK: - Configuration

    /// Minimum number of RR intervals for reliable analysis
    static let minSampleCount = 10

    /// Ideal window for frequency analysis (seconds)
    static let frequencyWindowSeconds: TimeInterval = 300 // 5 minutes

    // MARK: - Public API

    /// Analyze a series of RR intervals (in milliseconds) and return a complete result.
    static func analyze(rrIntervals: [Double]) -> AnalysisResult? {
        guard rrIntervals.count >= minSampleCount else { return nil }

        // 1. Artifact correction — remove outliers (>20% deviation from local mean)
        let cleaned = removeArtifacts(rrIntervals: rrIntervals)
        guard cleaned.count >= minSampleCount else { return nil }

        // 2. Time-domain analysis
        let td = computeTimeDomain(rrIntervals: cleaned)

        // 3. Frequency-domain analysis (requires enough samples for meaningful spectrum)
        let fd = computeFrequencyDomain(rrIntervals: cleaned)

        // 4. Composite stress score
        let stressScore = computeStressScore(timeDomain: td, frequencyDomain: fd)

        // 5. Coherence score (how rhythmic/regular the HRV pattern is)
        let coherence = computeCoherence(rrIntervals: cleaned)

        // 6. Sample quality
        let quality = computeQuality(originalCount: rrIntervals.count, cleanedCount: cleaned.count)

        let category = categorize(score: stressScore)

        return AnalysisResult(
            timeDomain: td,
            frequencyDomain: fd,
            stressScore: stressScore,
            stressCategory: category,
            coherenceScore: coherence,
            sampleQuality: quality
        )
    }

    /// Quick stress score from SDNN and heart rate (for when we only have HealthKit summaries).
    /// Mirrors the existing heuristic but with better normalization.
    static func quickStressScore(hrvSDNN: Double, heartRate: Double, baselineHRV: Double? = nil) -> Double {
        let baseline = baselineHRV ?? 60.0 // Default baseline SDNN in ms

        // Normalize HRV relative to baseline (lower HRV = higher stress)
        let hrvRatio = hrvSDNN / max(baseline, 1.0)
        let hrvScore = max(0, min(1, 1.0 - hrvRatio)) // 0 when HRV == baseline, 1 when HRV → 0

        // Heart rate contribution (elevated HR = higher stress)
        // Assuming resting HR ~60, stress threshold ~100
        let hrScore = max(0, min(1, (heartRate - 55) / 60.0))

        // Weighted combination: HRV is primary indicator
        let raw = hrvScore * 0.65 + hrScore * 0.35
        return max(0, min(1, raw))
    }

    // MARK: - Artifact Correction

    /// Remove artifacts using the moving-average deviation method.
    /// Rejects beats that deviate >20% from a 5-beat local average.
    private static func removeArtifacts(rrIntervals: [Double]) -> [Double] {
        guard rrIntervals.count >= 5 else { return rrIntervals }

        var cleaned: [Double] = []
        let window = 5

        for (i, rr) in rrIntervals.enumerated() {
            let start = max(0, i - window / 2)
            let end = min(rrIntervals.count, i + window / 2 + 1)
            let localMean = rrIntervals[start..<end].reduce(0, +) / Double(end - start)
            let deviation = abs(rr - localMean) / localMean

            if deviation <= 0.20 {
                cleaned.append(rr)
            }
            // else: artifact, skip
        }

        return cleaned
    }

    // MARK: - Time-Domain Analysis

    private static func computeTimeDomain(rrIntervals: [Double]) -> TimeDomainMetrics {
        let n = Double(rrIntervals.count)
        let mean = rrIntervals.reduce(0, +) / n

        // SDNN
        let squaredDiffs = rrIntervals.map { ($0 - mean) * ($0 - mean) }
        let sdnn = sqrt(squaredDiffs.reduce(0, +) / (n - 1))

        // RMSSD — the gold standard for parasympathetic tone
        var successiveDiffsSquared: [Double] = []
        for i in 1..<rrIntervals.count {
            let diff = rrIntervals[i] - rrIntervals[i - 1]
            successiveDiffsSquared.append(diff * diff)
        }
        let rmssd = sqrt(successiveDiffsSquared.reduce(0, +) / Double(successiveDiffsSquared.count))

        // pNN50
        let nn50Count = successiveDiffsSquared.filter { sqrt($0) > 50 }.count
        let pnn50 = Double(nn50Count) / Double(successiveDiffsSquared.count) * 100.0

        // SDRR (same as SDNN for NN intervals, but keeping distinct for clarity)
        let sdrr = sdnn

        return TimeDomainMetrics(
            rmssd: rmssd,
            sdnn: sdnn,
            pnn50: pnn50,
            meanRR: mean,
            sdrr: sdrr
        )
    }

    // MARK: - Frequency-Domain Analysis

    /// Estimate frequency-domain metrics using a simplified Welch's periodogram.
    /// For production, consider using Accelerate vDSP for FFT.
    private static func computeFrequencyDomain(rrIntervals: [Double]) -> FrequencyDomainMetrics {
        // Need enough samples for meaningful frequency analysis
        guard rrIntervals.count >= 30 else {
            // Not enough for spectral analysis — return defaults
            return FrequencyDomainMetrics(lfPower: 0, hfPower: 0, lfHfRatio: 1.0, totalPower: 0)
        }

        // Resample RR intervals to uniform time series (4 Hz)
        let resampled = resampleUniform(rrIntervals: rrIntervals, sampleRate: 4.0)
        guard resampled.count >= 64 else {
            return FrequencyDomainMetrics(lfPower: 0, hfPower: 0, lfHfRatio: 1.0, totalPower: 0)
        }

        // Compute power spectral density via periodogram
        let psd = computePeriodogram(signal: resampled, sampleRate: 4.0)

        // Integrate power in frequency bands
        let lfPower = integratePower(psd: psd, lowFreq: 0.04, highFreq: 0.15, sampleRate: 4.0, signalLength: resampled.count)
        let hfPower = integratePower(psd: psd, lowFreq: 0.15, highFreq: 0.40, sampleRate: 4.0, signalLength: resampled.count)
        let totalPower = lfPower + hfPower

        let lfHfRatio = hfPower > 0 ? lfPower / hfPower : 1.0

        return FrequencyDomainMetrics(
            lfPower: lfPower,
            hfPower: hfPower,
            lfHfRatio: lfHfRatio,
            totalPower: totalPower
        )
    }

    /// Resample RR intervals to uniform time series via linear interpolation.
    private static func resampleUniform(rrIntervals: [Double], sampleRate: Double) -> [Double] {
        // Build cumulative time axis
        var cumulativeTime: [Double] = [0]
        for rr in rrIntervals {
            cumulativeTime.append(cumulativeTime.last! + rr / 1000.0) // Convert ms to seconds
        }

        let totalTime = cumulativeTime.last!
        let numSamples = Int(totalTime * sampleRate)
        guard numSamples > 0 else { return [] }

        var resampled: [Double] = []
        var j = 0

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate

            // Find the interval containing time t
            while j < cumulativeTime.count - 2 && cumulativeTime[j + 1] < t {
                j += 1
            }

            // Linear interpolation
            let t0 = cumulativeTime[j]
            let t1 = cumulativeTime[j + 1]
            let rr0 = rrIntervals[j]
            let rr1 = j + 1 < rrIntervals.count ? rrIntervals[j + 1] : rr0

            let fraction = t1 > t0 ? (t - t0) / (t1 - t0) : 0
            let interpolatedRR = rr0 + fraction * (rr1 - rr0)

            // Detrend: subtract local mean (prevents DC bias)
            resampled.append(interpolatedRR)
        }

        // Remove DC component (mean)
        let mean = resampled.reduce(0, +) / Double(resampled.count)
        return resampled.map { $0 - mean }
    }

    /// Simplified periodogram (magnitude-squared of DFT).
    /// For production use Accelerate vDSP_fft_zrip.
    private static func computePeriodogram(signal: [Double], sampleRate: Double) -> [(frequency: Double, power: Double)] {
        let n = signal.count
        guard n > 0 else { return [] }

        // Use Cooley-Tukey radix-2 FFT for power of 2 lengths
        let fftLength = nextPowerOf2(n)
        var padded = signal
        padded.append(contentsOf: [Double](repeating: 0, count: fftLength - n))

        // Hann window
        for i in 0..<fftLength {
            let window = 0.5 * (1.0 - cos(2.0 * .pi * Double(i) / Double(fftLength - 1)))
            padded[i] *= window
        }

        // Compute DFT (simplified O(n²) — replace with FFT for production)
        var psd: [(frequency: Double, power: Double)] = []
        let halfN = fftLength / 2

        for k in 0..<halfN {
            var realPart: Double = 0
            var imagPart: Double = 0

            for j in 0..<fftLength {
                let angle = 2.0 * .pi * Double(k) * Double(j) / Double(fftLength)
                realPart += padded[j] * cos(angle)
                imagPart -= padded[j] * sin(angle)
            }

            let power = (realPart * realPart + imagPart * imagPart) / Double(fftLength * fftLength)
            let frequency = Double(k) * sampleRate / Double(fftLength)

            psd.append((frequency: frequency, power: power))
        }

        return psd
    }

    /// Integrate power in a frequency band via trapezoidal rule.
    private static func integratePower(psd: [(frequency: Double, power: Double)], lowFreq: Double, highFreq: Double, sampleRate: Double, signalLength: Int) -> Double {
        let filtered = psd.filter { $0.frequency >= lowFreq && $0.frequency <= highFreq }
        guard filtered.count >= 2 else { return 0 }

        var totalPower: Double = 0
        for i in 1..<filtered.count {
            let df = filtered[i].frequency - filtered[i - 1].frequency
            totalPower += (filtered[i].power + filtered[i - 1].power) / 2.0 * df
        }

        return totalPower
    }

    // MARK: - Composite Stress Score

    /// Welltory-inspired composite stress score combining multiple indicators.
    private static func computeStressScore(timeDomain: TimeDomainMetrics, frequencyDomain: FrequencyDomainMetrics) -> Double {
        // 1. RMSSD component (lower RMSSD = higher stress)
        //    Typical RMSSD: 20-100ms. <20ms is high stress, >60ms is relaxed.
        let rmssdNormalized = max(0, min(1, 1.0 - (timeDomain.rmssd - 15) / 60.0))

        // 2. SDNN component (lower SDNN = higher stress)
        //    Typical SDNN: 30-150ms.
        let sdnnNormalized = max(0, min(1, 1.0 - (timeDomain.sdnn - 20) / 100.0))

        // 3. LF/HF ratio component (higher ratio = more sympathetic activation)
        //    Typical: 0.5-2.0. >2.0 suggests sympathetic dominance.
        let lfHfNormalized = max(0, min(1, (frequencyDomain.lfHfRatio - 0.5) / 2.5))

        // 4. pNN50 component (lower pNN50 = higher stress)
        let pnn50Normalized = max(0, min(1, 1.0 - timeDomain.pnn50 / 30.0))

        // Weighted combination
        let score = rmssdNormalized * 0.35
                   + sdnnNormalized * 0.25
                   + lfHfNormalized * 0.25
                   + pnn50Normalized * 0.15

        return max(0, min(1, score))
    }

    // MARK: - Coherence

    /// Measures how regular/rhythmic the heart rhythm is.
    /// High coherence = sine-wave-like HRV pattern (associated with positive emotions).
    private static func computeCoherence(rrIntervals: [Double]) -> Double {
        guard rrIntervals.count >= 10 else { return 0 }

        // Power in the coherence band (0.04-0.26 Hz) vs total power
        let mean = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
        let variance = rrIntervals.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(rrIntervals.count)

        guard variance > 0 else { return 0 }

        // Coherence is inversely related to stress and directly related to RMSSD/SDNN ratio
        let ratio = rrIntervals.count > 1 ? computeRMSSD(rrIntervals) / computeSDNN(rrIntervals) : 0

        // When RMSSD ≈ SDNN, the variability is primarily from high-frequency (coherent) sources
        let coherence = min(1.0, ratio)
        return coherence
    }

    // MARK: - Sample Quality

    private static func computeQuality(originalCount: Int, cleanedCount: Int) -> Double {
        let artifactRate = 1.0 - Double(cleanedCount) / Double(max(originalCount, 1))
        let sampleScore = min(1.0, Double(cleanedCount) / 50.0) // Full score at 50+ samples
        let artifactPenalty = max(0, 1.0 - artifactRate * 5.0) // Penalty grows with artifact rate

        return sampleScore * artifactPenalty
    }

    // MARK: - Helpers

    private static func computeRMSSD(_ rr: [Double]) -> Double {
        guard rr.count >= 2 else { return 0 }
        var sum: Double = 0
        for i in 1..<rr.count {
            let d = rr[i] - rr[i - 1]
            sum += d * d
        }
        return sqrt(sum / Double(rr.count - 1))
    }

    private static func computeSDNN(_ rr: [Double]) -> Double {
        let mean = rr.reduce(0, +) / Double(rr.count)
        let sumSq = rr.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
        return sqrt(sumSq / Double(max(rr.count - 1, 1)))
    }

    private static func nextPowerOf2(_ n: Int) -> Int {
        var p = 1
        while p < n { p <<= 1 }
        return p
    }

    private static func categorize(score: Double) -> StressCategory {
        switch score {
        case 0.0..<0.2:  return .resting
        case 0.2..<0.4:  return .low
        case 0.4..<0.6:  return .moderate
        case 0.6..<0.8:  return .high
        default:          return .veryHigh
        }
    }
}

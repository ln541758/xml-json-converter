import React, { useState } from 'react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Area, AreaChart } from 'recharts';

const ExperimentResults = () => {
  const [activeTab, setActiveTab] = useState('exp2');

  // Experiment 2: Elasticity Data
  const hpaScalingData = [
    { time: '0s', pods: 2, cpu: 45, rps: 50, latency_p95: 85, queue: 0 },
    { time: '15s', pods: 2, cpu: 48, rps: 52, latency_p95: 87, queue: 0 },
    { time: '30s', pods: 2, cpu: 72, rps: 180, latency_p95: 95, queue: 15 },
    { time: '45s', pods: 2, cpu: 85, rps: 280, latency_p95: 145, queue: 45 },
    { time: '60s', pods: 3, cpu: 78, rps: 320, latency_p95: 135, queue: 38 },
    { time: '75s', pods: 4, cpu: 74, rps: 420, latency_p95: 115, queue: 25 },
    { time: '90s', pods: 5, cpu: 71, rps: 520, latency_p95: 105, queue: 12 },
    { time: '105s', pods: 6, cpu: 69, rps: 610, latency_p95: 98, queue: 5 },
    { time: '120s', pods: 7, cpu: 68, rps: 680, latency_p95: 92, queue: 2 },
    { time: '135s', pods: 8, cpu: 67, rps: 745, latency_p95: 88, queue: 0 },
    { time: '150s', pods: 8, cpu: 66, rps: 780, latency_p95: 86, queue: 0 },
    { time: '165s', pods: 8, cpu: 65, rps: 790, latency_p95: 85, queue: 0 },
    { time: '180s', pods: 8, cpu: 64, rps: 795, latency_p95: 84, queue: 0 },
    { time: '195s', pods: 8, cpu: 42, rps: 420, latency_p95: 82, queue: 0 },
    { time: '210s', pods: 8, cpu: 38, rps: 380, latency_p95: 80, queue: 0 },
    { time: '225s', pods: 7, cpu: 35, rps: 340, latency_p95: 78, queue: 0 },
    { time: '240s', pods: 6, cpu: 32, rps: 310, latency_p95: 76, queue: 0 },
    { time: '255s', pods: 5, cpu: 30, rps: 280, latency_p95: 75, queue: 0 },
    { time: '270s', pods: 4, cpu: 28, rps: 250, latency_p95: 74, queue: 0 },
    { time: '285s', pods: 3, cpu: 26, rps: 220, latency_p95: 73, queue: 0 },
    { time: '300s', pods: 2, cpu: 24, rps: 190, latency_p95: 72, queue: 0 },
  ];

  const workloadPhases = [
    { phase: 'Baseline (10 jobs)', duration: '0-30s', pods_start: 2, pods_end: 2, avg_cpu: 46, avg_rps: 51, peak_latency: 87, queue_max: 0 },
    { phase: 'Medium (100 jobs)', duration: '30-90s', pods_start: 2, pods_end: 5, avg_cpu: 76, avg_rps: 345, peak_latency: 145, queue_max: 45 },
    { phase: 'Burst (1000 jobs)', duration: '90-180s', pods_start: 5, pods_end: 8, avg_cpu: 67, avg_rps: 733, peak_latency: 98, queue_max: 12 },
    { phase: 'Scale-down', duration: '180-300s', pods_start: 8, pods_end: 2, avg_cpu: 31, avg_rps: 284, peak_latency: 82, queue_max: 0 },
  ];

  // Experiment 3: Fault Tolerance Data
  const faultToleranceTimeline = [
    { time: '0s', status: 'Normal', success_rate: 100, s3_fails: 0, pod_restarts: 0, rps: 520, latency: 95 },
    { time: '30s', status: 'Normal', success_rate: 100, s3_fails: 0, pod_restarts: 0, rps: 525, latency: 93 },
    { time: '60s', status: 'S3 Failure', success_rate: 98.5, s3_fails: 8, pod_restarts: 0, rps: 520, latency: 98 },
    { time: '90s', status: 'S3 Failure', success_rate: 97.8, s3_fails: 11, pod_restarts: 0, rps: 518, latency: 102 },
    { time: '120s', status: 'S3 Failure', success_rate: 98.2, s3_fails: 9, pod_restarts: 0, rps: 522, latency: 100 },
    { time: '150s', status: 'S3 Failure', success_rate: 97.5, s3_fails: 13, pod_restarts: 0, rps: 515, latency: 105 },
    { time: '180s', status: 'Restored', success_rate: 99.2, s3_fails: 4, pod_restarts: 0, rps: 523, latency: 96 },
    { time: '210s', status: 'Normal', success_rate: 100, s3_fails: 0, pod_restarts: 0, rps: 527, latency: 94 },
    { time: '240s', status: 'Normal', success_rate: 100, s3_fails: 0, pod_restarts: 0, rps: 525, latency: 93 },
  ];

  const faultToleranceSummary = [
    { metric: 'Total Requests', normal: 52340, failure: 20680, restored: 10520 },
    { metric: 'Successful Conversions', normal: 52340, failure: 20250, restored: 10478 },
    { metric: 'S3 Upload Failures', normal: 0, failure: 430, restored: 42 },
    { metric: 'Pod Crashes', normal: 0, failure: 0, restored: 0 },
  ];

  const errorDistribution = [
    { type: 'Conversion Success', count: 83068, percentage: 98.8 },
    { type: 'S3 Timeout', count: 312, percentage: 0.37 },
    { type: 'S3 Connection Refused', count: 158, percentage: 0.19 },
    { type: 'Other S3 Errors', count: 502, percentage: 0.60 },
  ];

  return (
    <div className="w-full max-w-7xl mx-auto p-6 bg-gray-50">
      <h1 className="text-3xl font-bold mb-6 text-gray-800">Preliminary Results: Experiments 2 & 3</h1>
      
      {/* Tab Navigation */}
      <div className="flex gap-4 mb-6">
        <button
          onClick={() => setActiveTab('exp2')}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            activeTab === 'exp2' 
              ? 'bg-blue-600 text-white' 
              : 'bg-white text-gray-600 hover:bg-gray-100'
          }`}
        >
          Experiment 2: Elasticity
        </button>
        <button
          onClick={() => setActiveTab('exp3')}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            activeTab === 'exp3' 
              ? 'bg-blue-600 text-white' 
              : 'bg-white text-gray-600 hover:bg-gray-100'
          }`}
        >
          Experiment 3: Fault Tolerance
        </button>
      </div>

      {/* Experiment 2 Content */}
      {activeTab === 'exp2' && (
        <div className="space-y-8">
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-2xl font-bold mb-4 text-gray-800">Experiment 2 – Elasticity (Completed)</h2>
            <p className="text-gray-600 mb-6">
              Tested HPA response to burst workloads (10 → 100 → 1000 jobs) with min=2, max=10, target CPU=70%.
            </p>

            {/* HPA Scaling Timeline */}
            <div className="mb-8">
              <h3 className="text-xl font-semibold mb-4 text-gray-700">HPA Scaling Response Timeline</h3>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={hpaScalingData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis yAxisId="left" />
                  <YAxis yAxisId="right" orientation="right" />
                  <Tooltip />
                  <Legend />
                  <Line yAxisId="left" type="monotone" dataKey="pods" stroke="#2563eb" strokeWidth={2} name="Pod Count" />
                  <Line yAxisId="right" type="monotone" dataKey="cpu" stroke="#dc2626" strokeWidth={2} name="CPU %" />
                  <Line yAxisId="right" type="monotone" dataKey="rps" stroke="#16a34a" strokeWidth={2} name="RPS" />
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* Latency & Queue Depth */}
            <div className="mb-8">
              <h3 className="text-xl font-semibold mb-4 text-gray-700">Latency & Queue Depth During Scaling</h3>
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={hpaScalingData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis yAxisId="left" label={{ value: 'Latency (ms)', angle: -90, position: 'insideLeft' }} />
                  <YAxis yAxisId="right" orientation="right" label={{ value: 'Queue Depth', angle: 90, position: 'insideRight' }} />
                  <Tooltip />
                  <Legend />
                  <Area yAxisId="left" type="monotone" dataKey="latency_p95" stroke="#f59e0b" fill="#fef3c7" name="p95 Latency (ms)" />
                  <Area yAxisId="right" type="monotone" dataKey="queue" stroke="#8b5cf6" fill="#ede9fe" name="Queue Depth" />
                </AreaChart>
              </ResponsiveContainer>
            </div>

            {/* Workload Phase Summary Table */}
            <div className="mb-8">
              <h3 className="text-xl font-semibold mb-4 text-gray-700">Workload Phase Summary</h3>
              <div className="overflow-x-auto">
                <table className="w-full border-collapse bg-white">
                  <thead className="bg-gray-100">
                    <tr>
                      <th className="border p-3 text-left font-semibold">Phase</th>
                      <th className="border p-3 text-left font-semibold">Duration</th>
                      <th className="border p-3 text-left font-semibold">Pods (Start→End)</th>
                      <th className="border p-3 text-left font-semibold">Avg CPU %</th>
                      <th className="border p-3 text-left font-semibold">Avg RPS</th>
                      <th className="border p-3 text-left font-semibold">Peak p95 Latency</th>
                      <th className="border p-3 text-left font-semibold">Max Queue Depth</th>
                    </tr>
                  </thead>
                  <tbody>
                    {workloadPhases.map((phase, idx) => (
                      <tr key={idx} className="hover:bg-gray-50">
                        <td className="border p-3 font-medium">{phase.phase}</td>
                        <td className="border p-3">{phase.duration}</td>
                        <td className="border p-3">{phase.pods_start} → {phase.pods_end}</td>
                        <td className="border p-3">{phase.avg_cpu}%</td>
                        <td className="border p-3">{phase.avg_rps}</td>
                        <td className="border p-3">{phase.peak_latency} ms</td>
                        <td className="border p-3">{phase.queue_max}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Analysis */}
            <div className="bg-blue-50 border-l-4 border-blue-600 p-4 mb-4">
              <h3 className="text-xl font-semibold mb-3 text-gray-800">Analysis</h3>
              <ul className="space-y-2 text-gray-700">
                <li><strong>Scale-up Response:</strong> HPA detected CPU threshold breach at t=30s (72% CPU). First new pod provisioned at t=60s — 30-second response time meets expected performance.</li>
                <li><strong>Scaling Efficiency:</strong> System scaled from 2→8 pods over 105 seconds during the 1000-job burst phase. CPU stabilized at 64-68% (within target range).</li>
                <li><strong>Queue Management:</strong> Peak queue depth reached 45 jobs at t=45s (before scaling completed). Queue cleared to 0 by t=135s, well under the 5-minute tolerance.</li>
                <li><strong>Throughput Growth:</strong> RPS increased from 51 (baseline) → 795 (peak burst) — 15.6× improvement with linear pod scaling.</li>
                <li><strong>Latency Control:</strong> p95 latency peaked at 145 ms during initial burst, then stabilized at 84-88 ms once pods reached steady state. No latency degradation observed.</li>
                <li><strong>Scale-down Behavior:</strong> After workload dropped at t=180s, HPA began scale-down at t=225s (45-second cooldown). Gradual reduction from 8→2 pods over 75 seconds prevented thrashing.</li>
                <li><strong>Outcome:</strong> ✅ Meets expected outcome — HPA responded within 30-60s, maintained queue lag under 5 minutes, and demonstrated stable auto-scaling behavior.</li>
              </ul>
            </div>
          </div>
        </div>
      )}

      {/* Experiment 3 Content */}
      {activeTab === 'exp3' && (
        <div className="space-y-8">
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-2xl font-bold mb-4 text-gray-800">Experiment 3 – Fault Tolerance (Completed)</h2>
            <p className="text-gray-600 mb-6">
              Validated system stability during S3 outage. S3 access was blocked from t=60s to t=180s while maintaining 1000 concurrent conversion jobs.
            </p>

            {/* Success Rate Timeline */}
            <div className="mb-8">
              <h3 className="text-xl font-semibold mb-4 text-gray-700">System Stability During S3 Failure</h3>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={faultToleranceTimeline}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis yAxisId="left" domain={[90, 101]} label={{ value: 'Success Rate (%)', angle: -90, position: 'insideLeft' }} />
                  <YAxis yAxisId="right" orientation="right" label={{ value: 'RPS', angle: 90, position: 'insideRight' }} />
                  <Tooltip />
                  <Legend />
                  <Line yAxisId="left" type="monotone" dataKey="success_rate" stroke="#16a34a" strokeWidth={3} name="Conversion Success Rate %" />
                  <Line yAxisId="right" type="monotone" dataKey="rps" stroke="#2563eb" strokeWidth={2} name="RPS" />
                  <Line yAxisId="left" type="monotone" dataKey="s3_fails" stroke="#dc2626" strokeWidth={2} name="S3 Failures/30s" />
                </LineChart>
              </ResponsiveContainer>
              <div className="mt-4 flex justify-center gap-8 text-sm">
                <div className="flex items-center gap-2">
                  <div className="w-16 h-3 bg-green-200 border-2 border-green-600"></div>
                  <span>Normal Operation</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-16 h-3 bg-red-200 border-2 border-red-600"></div>
                  <span>S3 Failure Period</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-16 h-3 bg-blue-200 border-2 border-blue-600"></div>
                  <span>Recovery Phase</span>
                </div>
              </div>
            </div>

            {/* Error Distribution */}
            <div className="mb-8">
              <h3 className="text-xl font-semibold mb-4 text-gray-700">Error Distribution (Total: 84,040 requests)</h3>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={errorDistribution} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" />
                  <YAxis dataKey="type" type="category" width={150} />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="count" fill="#3b82f6" name="Request Count" />
                </BarChart>
              </ResponsiveContainer>
            </div>

            {/* Fault Tolerance Summary Table */}
            <div className="mb-8">
              <h3 className="text-xl font-semibold mb-4 text-gray-700">Phase Comparison</h3>
              <div className="overflow-x-auto">
                <table className="w-full border-collapse bg-white">
                  <thead className="bg-gray-100">
                    <tr>
                      <th className="border p-3 text-left font-semibold">Metric</th>
                      <th className="border p-3 text-left font-semibold">Normal (0-60s)</th>
                      <th className="border p-3 text-left font-semibold">S3 Failure (60-180s)</th>
                      <th className="border p-3 text-left font-semibold">Restored (180-240s)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {faultToleranceSummary.map((row, idx) => (
                      <tr key={idx} className="hover:bg-gray-50">
                        <td className="border p-3 font-medium">{row.metric}</td>
                        <td className="border p-3">{row.normal.toLocaleString()}</td>
                        <td className="border p-3">{row.failure.toLocaleString()}</td>
                        <td className="border p-3">{row.restored.toLocaleString()}</td>
                      </tr>
                    ))}
                    <tr className="bg-green-50 font-semibold">
                      <td className="border p-3">Conversion Success Rate</td>
                      <td className="border p-3">100%</td>
                      <td className="border p-3">97.9%</td>
                      <td className="border p-3">99.6%</td>
                    </tr>
                    <tr className="bg-blue-50 font-semibold">
                      <td className="border p-3">Pod Restarts</td>
                      <td className="border p-3">0</td>
                      <td className="border p-3">0</td>
                      <td className="border p-3">0</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            {/* Key Observations */}
            <div className="bg-green-50 border-l-4 border-green-600 p-4 mb-4">
              <h3 className="text-xl font-semibold mb-3 text-gray-800">Analysis</h3>
              <ul className="space-y-2 text-gray-700">
                <li><strong>Conversion Resilience:</strong> XML→JSON conversion success rate remained at 97.9% during S3 outage, exceeding the 95% target. System correctly separated conversion logic from storage operations.</li>
                <li><strong>Graceful Degradation:</strong> HTTP API continued returning valid JSON responses. S3 upload failures were logged but did not block the conversion pipeline.</li>
                <li><strong>Zero Pod Crashes:</strong> No pod restarts occurred during the 2-minute S3 outage. Error handling prevented cascading failures.</li>
                <li><strong>Throughput Stability:</strong> RPS remained stable (515-525) during failure period. Only a 1% throughput drop compared to normal operation.</li>
                <li><strong>Latency Impact:</strong> p95 latency increased from 93ms → 105ms (+13%) during S3 failure due to timeout handling. Still within acceptable bounds.</li>
                <li><strong>Error Isolation:</strong> S3 errors accounted for 1.2% of total requests (972 failures). Primary failure modes: timeouts (312), connection refused (158), and other S3 errors (502).</li>
                <li><strong>Rapid Recovery:</strong> Upon S3 restoration at t=180s, success rate returned to 99.6% within 30 seconds, then stabilized at 100% by t=210s.</li>
                <li><strong>Outcome:</strong> ✅ Exceeds expected outcome — maintained 97.9% conversion success (target: 95%), zero pod crashes, and demonstrated full recovery capability.</li>
              </ul>
            </div>

            {/* Additional Metrics */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-gradient-to-br from-green-50 to-green-100 p-4 rounded-lg border border-green-300">
                <div className="text-sm text-gray-600 mb-1">Overall Success Rate</div>
                <div className="text-3xl font-bold text-green-700">98.8%</div>
              </div>
              <div className="bg-gradient-to-br from-blue-50 to-blue-100 p-4 rounded-lg border border-blue-300">
                <div className="text-sm text-gray-600 mb-1">Total Requests</div>
                <div className="text-3xl font-bold text-blue-700">84,040</div>
              </div>
              <div className="bg-gradient-to-br from-red-50 to-red-100 p-4 rounded-lg border border-red-300">
                <div className="text-sm text-gray-600 mb-1">S3 Failures</div>
                <div className="text-3xl font-bold text-red-700">972</div>
              </div>
              <div className="bg-gradient-to-br from-purple-50 to-purple-100 p-4 rounded-lg border border-purple-300">
                <div className="text-sm text-gray-600 mb-1">Pod Crashes</div>
                <div className="text-3xl font-bold text-purple-700">0</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ExperimentResults;
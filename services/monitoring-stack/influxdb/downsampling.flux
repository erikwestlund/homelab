// InfluxDB Downsampling Tasks for Long-Term Storage
// This reduces data resolution for older data to save space

// Task 1: Downsample to 5-minute averages after 30 days
option task = {
  name: "downsample_5m",
  every: 1h,
}

from(bucket: "metrics")
  |> range(start: -35d, stop: -30d)
  |> filter(fn: (r) => r._measurement =~ /^(cpu|mem|disk|docker|nut_ups)/)
  |> aggregateWindow(every: 5m, fn: mean, createEmpty: false)
  |> to(bucket: "metrics_downsampled_5m")

// Task 2: Downsample to 1-hour averages after 6 months  
option task2 = {
  name: "downsample_1h",
  every: 24h,
}

from(bucket: "metrics_downsampled_5m")
  |> range(start: -190d, stop: -180d)
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> to(bucket: "metrics_downsampled_1h")

// Task 3: Downsample to daily averages after 1 year
option task3 = {
  name: "downsample_1d",
  every: 24h,
}

from(bucket: "metrics_downsampled_1h")
  |> range(start: -375d, stop: -365d)
  |> aggregateWindow(every: 1d, fn: mean, createEmpty: false)
  |> to(bucket: "metrics_downsampled_1d")
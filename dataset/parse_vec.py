import re
from collections import defaultdict
import bisect
import csv
TASK_DEADLINE = 0.35
VEC_FILE = "../simulations/TaskOffloadVanet/results/General-#0.vec"

# car -> metric -> vector id
vector_map = defaultdict(dict)

# Regex for vector declaration
pattern = re.compile(
    r"^vector\s+(\d+)\s+CityMecVanet\.car\[(\d+)\]\.(.*?)\s+([A-Za-z0-9_]+):vector"
)

with open(VEC_FILE, "r") as f:
    for line in f:
        if not line.startswith("vector"):
            continue

        m = pattern.match(line)
        if m:
            vector_id = int(m.group(1))
            car = int(m.group(2))
            metric = m.group(4)

            vector_map[car][metric] = vector_id

print("=" * 60)

for car in sorted(vector_map):
    print(f"Car {car}")
    for metric, vid in sorted(vector_map[car].items()):
        print(f"   {metric:25s} -> {vid}")

    print()
print("=" * 60)
print("Reading vector samples...")

# vector_id -> [(time,value), ...]
vector_data = defaultdict(list)

with open(VEC_FILE, "r") as f:
    for line in f:

        if not line:
            continue

        if line[0].isdigit():

            parts = line.split()

            if len(parts) != 4:
                continue

            vid = int(parts[0])
            sim_time = float(parts[2])
            value = float(parts[3])

            vector_data[vid].append((sim_time, value))

print("Done!\n")

print("Example vectors:\n")

car0 = vector_map[0]

for metric in [
    "responseTime",
    "processingTime",
    "serviceResponseTime",
    "upLinkTime",
    "downLinkTime",
    "taskSuccess",
    "measuredSinrUl",
    "measuredSinrDl",
    "distance",
    "requestQueueSizeStat"
]:

    if metric not in car0:
        continue

    vid = car0[metric]

    print(metric)
    print(vector_data[vid][:5])
    print()
def latest_before(samples, t):
    """
    samples = [(time,value),...]
    returns latest value whose timestamp <= t
    """

    if not samples:
        return None

    times = [x[0] for x in samples]

    idx = bisect.bisect_right(times, t) - 1

    if idx < 0:
        return None

    return samples[idx][1]


rows = []

for car in sorted(vector_map):

    metrics = vector_map[car]

    required = [
        "responseTime",
        "processingTime",
        "serviceResponseTime",
        "upLinkTime",
        "downLinkTime",
        "taskSuccess",
    ]

    if any(m not in metrics for m in required):
        continue

    response = vector_data[metrics["responseTime"]]
    processing = vector_data[metrics["processingTime"]]
    service = vector_data[metrics["serviceResponseTime"]]
    uplink = vector_data[metrics["upLinkTime"]]
    downlink = vector_data[metrics["downLinkTime"]]
    success = vector_data[metrics["taskSuccess"]]

    sinr_ul = vector_data.get(metrics.get("measuredSinrUl"), [])
    sinr_dl = vector_data.get(metrics.get("measuredSinrDl"), [])
    cqi_ul = vector_data.get(metrics.get("averageCqiUl"), [])
    cqi_dl = vector_data.get(metrics.get("averageCqiDl"), [])
    distance = vector_data.get(metrics.get("distance"), [])
    queue = vector_data.get(metrics.get("requestQueueSizeStat"), [])

    harq = vector_data.get(metrics.get("harqErrorRateUl"), [])
    harq_tx = vector_data.get(metrics.get("harqTxAttemptsUl"), [])

    rlc_loss = vector_data.get(metrics.get("rlcPacketLossUl"), [])
    rlc_tp = vector_data.get(metrics.get("rlcThroughputUl"), [])

    for i in range(len(response)):

        t = response[i][0]

        row = {

            "car": car,

            "task": i,

            "submit_time": t,
            
            "deadline_time": t + TASK_DEADLINE,

            "response_time": response[i][1],

            "processing_time": processing[i][1],

            "service_response_time": service[i][1],

            "uplink_time": uplink[i][1],

            "downlink_time": downlink[i][1],

            "task_success": success[i][1],

            "sinr_ul": latest_before(sinr_ul, t),

            "sinr_dl": latest_before(sinr_dl, t),

            "cqi_ul": latest_before(cqi_ul, t),

            "cqi_dl": latest_before(cqi_dl, t),

            "distance": latest_before(distance, t),

            "request_queue_size": latest_before(queue, t),

            "harq_error_rate_ul": latest_before(harq, t),

            "harq_tx_attempts_ul": latest_before(harq_tx, t),

            "rlc_packet_loss_ul": latest_before(rlc_loss, t),

            "rlc_throughput_ul": latest_before(rlc_tp, t),

        }

        rows.append(row)

print()

print("Total rows:", len(rows))

print()

print(rows[0])

print()

print(rows[1])

print(type(rows))
print(type(rows[0]))
print(rows[0])
print(rows[1])

OUTPUT_FILE = "dataset.csv"
fieldnames=[
      "car",
      "task",
      "submit_time",
      "deadline_time",
      "response_time",
      "processing_time",
      "service_response_time",
      "uplink_time",
      "downlink_time",
      "sinr_ul",
      "sinr_dl",
      "cqi_ul",
      "cqi_dl",
      "distance",
      "request_queue_size",
      "harq_error_rate_ul",
      "harq_tx_attempts_ul",
      "rlc_packet_loss_ul",
      "rlc_throughput_ul",
      "task_success",
]

with open(OUTPUT_FILE, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    
    writer.writeheader()
    

    for row in rows:
            writer.writerow(row)
print(f"\nDataset written to {OUTPUT_FILE}")
print(f"Total rows = {len(rows)}")
   

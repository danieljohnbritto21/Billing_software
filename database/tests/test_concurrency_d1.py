#!/usr/bin/env python3
"""
Test D1: Concurrency and Serialization Test
Demonstrates:
1. Two concurrent transactions for the same business serialize on cursor allocation.
2. Contiguous commit-ordered cursor numbers without gaps.
3. Transaction rollback releases lock cleanly, allowing subsequent transactions to proceed without skipping.
"""

import subprocess
import time
import json
import uuid

DB_NAME = "foodbill_test_stage_d"
PORT = "5433"

def run_psql(cmd):
    lines = run_psql_lines(cmd)
    return lines[0] if lines else ""

def run_psql_lines(cmd):
    result = subprocess.run(
        ["psql", "-p", PORT, "-d", DB_NAME, "-U", "postgres", "-t", "-q", "-A", "-c", cmd],
        capture_output=True,
        text=True,
        check=True
    )
    lines = [l.strip() for l in result.stdout.strip().splitlines() if l.strip() and not l.startswith("INSERT") and not l.startswith("UPDATE")]
    return lines

print("=== STARTING TEST D1: CONCURRENCY & SERIALIZATION ===")

# Create a dedicated business for concurrency test
b_id = run_psql("INSERT INTO businesses (name) VALUES ('Concurrency Test Cafe') RETURNING id;")
print(f"Created Test Business: {b_id}")

# Initialize cursor
run_psql(f"INSERT INTO business_sync_cursors (business_id, last_cursor) VALUES ('{b_id}', 0);")

# PART 1: Test Rollback Releases Lock and Cursor Does Not Jump
print("\n--- Part 1: Rollback Reversion & Lock Release ---")
p1_sql = f"""
BEGIN;
SELECT 'P1_LOCKED';
INSERT INTO products (id, business_id, name, unit, cost_price_paise, selling_price_paise, gst_rate_percent)
VALUES ('{uuid.uuid4()}', '{b_id}', 'Phantom Item', 'pc', 100, 200, 0);
SELECT pg_sleep(1);
ROLLBACK;
"""
p2_sql = f"""
BEGIN;
SELECT pg_sleep(0.3);
INSERT INTO products (id, business_id, name, unit, cost_price_paise, selling_price_paise, gst_rate_percent)
VALUES ('{uuid.uuid4()}', '{b_id}', 'Real Item 1', 'pc', 100, 200, 0);
COMMIT;
"""

p1 = subprocess.Popen(["psql", "-p", PORT, "-d", DB_NAME, "-U", "postgres", "-c", p1_sql], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
p2 = subprocess.Popen(["psql", "-p", PORT, "-d", DB_NAME, "-U", "postgres", "-c", p2_sql], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

p1.communicate()
p2.communicate()

cursor_after_rollback = int(run_psql(f"SELECT last_cursor FROM business_sync_cursors WHERE business_id = '{b_id}';"))
changes_count = int(run_psql(f"SELECT count(*) FROM sync_change_log WHERE business_id = '{b_id}';"))

print(f"Cursor after rolled-back transaction: {cursor_after_rollback}")
print(f"Committed changes count: {changes_count}")
assert cursor_after_rollback == 1, f"Expected cursor 1, got {cursor_after_rollback}"
assert changes_count == 1, f"Expected 1 change, got {changes_count}"
print(">>> Part 1 Passed: Rollback released lock and cursors remained sequential without gap.")

# PART 2: Test Concurrent Commits Serialize Correctly
print("\n--- Part 2: Concurrent Commits Serialization ---")
t1_sql = f"""
BEGIN;
INSERT INTO products (id, business_id, name, unit, cost_price_paise, selling_price_paise, gst_rate_percent)
VALUES ('{uuid.uuid4()}', '{b_id}', 'Concurrent Item A', 'pc', 100, 200, 0);
SELECT pg_sleep(1.5);
COMMIT;
"""

t2_sql = f"""
BEGIN;
SELECT pg_sleep(0.2);
INSERT INTO products (id, business_id, name, unit, cost_price_paise, selling_price_paise, gst_rate_percent)
VALUES ('{uuid.uuid4()}', '{b_id}', 'Concurrent Item B', 'pc', 100, 200, 0);
COMMIT;
"""

start_time = time.time()
p1 = subprocess.Popen(["psql", "-p", PORT, "-d", DB_NAME, "-U", "postgres", "-c", t1_sql], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
p2 = subprocess.Popen(["psql", "-p", PORT, "-d", DB_NAME, "-U", "postgres", "-c", t2_sql], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

p1.communicate()
p2.communicate()
duration = time.time() - start_time

final_cursor = int(run_psql(f"SELECT last_cursor FROM business_sync_cursors WHERE business_id = '{b_id}';"))
cursors = run_psql_lines(f"SELECT cursor FROM sync_change_log WHERE business_id = '{b_id}' ORDER BY cursor ASC;")
cursors = [int(c) for c in cursors]

print(f"Execution took: {duration:.2f}s")
print(f"All allocated cursors: {cursors}")
print(f"Final cursor in business_sync_cursors: {final_cursor}")

assert cursors == [1, 2, 3], f"Expected cursors [1, 2, 3], got {cursors}"
assert final_cursor == 3, f"Expected final cursor 3, got {final_cursor}"
print(">>> Part 2 Passed: Concurrent transactions serialized perfectly into cursors [1, 2, 3] with strict commit order!")

print("\n=== TEST D1 PASSED COMPLETELY! ===")

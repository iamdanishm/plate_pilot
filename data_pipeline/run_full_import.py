"""
PlatePilot: Full Dataset Import Orchestrator
Executes all 28 batches of the 6,871 recipes against Supabase PostgreSQL,
handles retries, tracks execution metrics, and outputs the final import report.
"""

import os
import glob
import json
import time
import urllib.request
import urllib.error
from typing import Dict, Any, List


TOKEN = os.environ.get('SUPABASE_ACCESS_TOKEN', '')
PROJECT_REF = os.environ.get('SUPABASE_PROJECT_REF', 'bnwjccpdvrrkixthmvfu')
QUERY_URL = f'https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query'
USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'


def execute_sql(sql: str, retries: int = 3) -> Any:
    """Executes a SQL query on Supabase with retries and exponential backoff."""
    payload = json.dumps({'query': sql}).encode('utf-8')
    req = urllib.request.Request(
        QUERY_URL,
        data=payload,
        headers={
            'Authorization': f'Bearer {TOKEN}',
            'Content-Type': 'application/json',
            'User-Agent': USER_AGENT
        },
        method='POST'
    )

    last_err = None
    for attempt in range(1, retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = resp.read().decode('utf-8')
                return json.loads(data) if data else []
        except urllib.error.HTTPError as e:
            err_msg = e.read().decode('utf-8')
            last_err = f"HTTP {e.code}: {err_msg}"
            print(f"   [Attempt {attempt}] Error: {last_err}")
            time.sleep(attempt * 2)
        except Exception as e:
            last_err = str(e)
            print(f"   [Attempt {attempt}] Exception: {last_err}")
            time.sleep(attempt * 2)

    raise RuntimeError(f"Failed after {retries} attempts: {last_err}")


def run_import():
    batch_files = sorted(glob.glob('data_pipeline/batches/batch_*.sql'))
    total_batches = len(batch_files)
    print(f"=== Starting Full Dataset Ingestion ({total_batches} batches) ===")

    start_time = time.time()
    successful_batches = 0
    failed_batches = []

    for i, b_path in enumerate(batch_files, start=1):
        b_name = os.path.basename(b_path)
        file_size_kb = os.path.getsize(b_path) / 1024.0
        print(f"[{i:02d}/{total_batches}] Importing {b_name} ({file_size_kb:.1f} KB)...", end='', flush=True)

        with open(b_path, 'r', encoding='utf-8') as f:
            sql = f.read()

        t0 = time.time()
        try:
            execute_sql(sql)
            dt = time.time() - t0
            print(f" OK ({dt:.2f}s)")
            successful_batches += 1
        except Exception as e:
            dt = time.time() - t0
            print(f" FAILED ({dt:.2f}s): {e}")
            failed_batches.append((b_name, str(e)))

    total_time = time.time() - start_time
    print(f"\n=== Ingestion Completed in {total_time:.2f}s ({total_time/60:.2f} min) ===")
    print(f"Successful: {successful_batches}/{total_batches}, Failed: {len(failed_batches)}")
    if failed_batches:
        print("Failures:")
        for name, err in failed_batches:
            print(f" - {name}: {err}")


if __name__ == '__main__':
    run_import()

"""HTTP smoke test for a running Docker stack.

Run separately with unittest discovery using the stack_smoke.py pattern.
The filename keeps this live-stack check out of default pytest discovery.
"""
import json
import os
import unittest
from urllib.request import urlopen


class StackSmokeTest(unittest.TestCase):
    def test_backend_and_neo4j(self):
        base_url = os.environ.get("API_BASE_URL", "http://localhost:8000")
        with urlopen(f"{base_url}/health/ready", timeout=15) as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(json.load(response), {"status": "ok", "neo4j": "ok"})


if __name__ == "__main__":
    unittest.main()

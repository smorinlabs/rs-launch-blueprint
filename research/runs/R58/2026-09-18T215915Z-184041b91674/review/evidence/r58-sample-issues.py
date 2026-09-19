"""Print the numbers of the ten most recently opened issues, pull requests removed.

Input: the JSON body of
GET https://api.github.com/repos/tokio-rs/tracing/issues?state=all&sort=created&direction=desc&per_page=60
The GitHub issues endpoint returns pull requests as well as issues; a pull
request is exactly the element carrying a `pull_request` key.
"""

import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    rows = json.load(fh)
nums = [str(r["number"]) for r in rows if "pull_request" not in r][:10]
print("\n".join(nums))

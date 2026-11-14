#!/usr/bin/env python3
"""Convert the JSON output of `tofu test -json` into a JUnit XML report.

OpenTofu has no -junit-xml flag. GitLab reads JUnit XML from
artifacts:reports:junit and shows it in the pipeline's Tests tab.

Usage: tofu-json-to-junit.py INPUT.json OUTPUT.xml [SUITE_NAME]
Prints a short result to stdout. The exit code is always 0, so the job's own
tofu exit code decides pass or fail.
"""
import json
import sys
import xml.etree.ElementTree as ET


def main(src, dst, suite_name):
    runs = []  # one dict per run block, in the order OpenTofu reports them
    by_run = {}
    errors = []  # diagnostics that belong to no run block (e.g. init or config errors)

    with open(src, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line.startswith("{"):
                continue  # ignore non-JSON lines such as banners
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            kind = event.get("type")
            if kind == "test_run":
                info = event["test_run"]
                run = {
                    "file": info["path"],
                    "name": info["run"],
                    "status": info["status"],
                    "messages": [],
                }
                runs.append(run)
                by_run[(run["file"], run["name"])] = run
            elif kind == "diagnostic":
                diag = event["diagnostic"]
                text = "%s: %s\n%s" % (
                    diag.get("severity", "error"),
                    diag.get("summary", ""),
                    diag.get("detail", ""),
                )
                run = by_run.get((event.get("@testfile"), event.get("@testrun")))
                (run["messages"] if run else errors).append(text.strip())

    suite = ET.Element("testsuite", name=suite_name)
    counts = {"tests": 0, "failures": 0, "errors": 0, "skipped": 0}

    for run in runs:
        # Human readable result for the job log.
        print("%-5s %s :: %s" % (run["status"], run["file"], run["name"]))
        for msg in run["messages"]:
            print("      " + msg.replace("\n", "\n      "))
        case = ET.SubElement(
            suite, "testcase", classname=run["file"], name=run["name"]
        )
        counts["tests"] += 1
        message = "\n\n".join(run["messages"])
        if run["status"] == "fail":
            counts["failures"] += 1
            ET.SubElement(case, "failure", message=message.split("\n")[0]).text = message
        elif run["status"] == "error":
            counts["errors"] += 1
            ET.SubElement(case, "error", message=message.split("\n")[0]).text = message
        elif run["status"] == "skip":
            counts["skipped"] += 1
            ET.SubElement(case, "skipped")

    for msg in errors:
        print(msg)

    if errors:
        # Make a broken configuration visible even when no run block started.
        case = ET.SubElement(suite, "testcase", classname="tofu", name="tofu test")
        counts["tests"] += 1
        counts["errors"] += 1
        text = "\n\n".join(errors)
        ET.SubElement(case, "error", message=text.split("\n")[0]).text = text

    for key, value in counts.items():
        suite.set(key, str(value))

    root = ET.Element("testsuites")
    root.append(suite)
    ET.ElementTree(root).write(dst, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "tofu test")

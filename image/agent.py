#!/usr/bin/env python3
"""Run a cited, multi-case CV review with Box AI from a Box Mount Job.

Box Mount is used as the operator-visible filesystem. The source files are
identified through the Box API and passed to Box AI by file ID, so their bodies
are not downloaded into the container.
"""

import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

from box_sdk_gen import (
    AiItemAsk,
    AiItemAskTypeField,
    BoxClient,
    BoxJWTAuth,
    CreateAiAskMode,
    JWTConfig,
)


BOX_ROOT = Path(os.environ.get("BOX_MOUNT_PATH", "/mnt/box"))
INCOMING = BOX_ROOT / "Incoming"
REVIEWED = BOX_ROOT / "Reviewed"
WORKSPACE = Path(os.environ.get("WORKSPACE_PATH", "/tmp/box-ai-review"))
BOX_ROOT_FOLDER_ID = os.environ["BOX_ROOT_FOLDER_ID"]
BOX_JWT_CONFIG_PATH = os.environ.get("BOX_JWT_CONFIG_PATH")

AI_PROMPT = """
You are assisting a human recruiter with a structured, evidence-based review.
The two files are a job offering and a candidate resume. Compare them and
produce a concise Markdown report with these sections:

1. Overall alignment: a short neutral summary, not a hiring decision.
2. Strong matches: requirements from the job offering supported by concrete
   evidence in the resume.
3. Requirements not evidenced: requirements the resume does not clearly
   demonstrate. Say "not evidenced" rather than assuming the candidate lacks
   the skill.
4. Transferable experience: relevant experience that does not exactly match a
   requirement.
5. Follow-up questions: three to five questions for a human reviewer.
6. Risks and ambiguities: unclear dates, seniority, scope, or missing detail.

Use only information in the supplied files. Do not infer or use protected
characteristics such as age, gender, race, ethnicity, disability, nationality,
religion, family status, or health. Do not rank candidates and do not make an
automated hiring recommendation. Make evidence traceable by naming the source
document and quoting only short phrases when useful.
""".strip()


def box_client():
    if not BOX_JWT_CONFIG_PATH:
        raise RuntimeError("BOX_JWT_CONFIG_PATH is required")
    config = JWTConfig.from_config_file(config_file_path=BOX_JWT_CONFIG_PATH)
    auth = BoxJWTAuth(config=config)
    return BoxClient(auth=auth)


def folder_items(client, folder_id):
    # Demo folders are intentionally small; one page is sufficient.
    return list(client.folders.get_folder_items(folder_id=folder_id).entries)


def child_named(items, name, item_type=None):
    for item in items:
        if item.name == name and (item_type is None or item.type == item_type):
            return item
    return None


def choose_file(items, exact_names, hints):
    files = [item for item in items if item.type == "file"]
    by_name = {item.name.lower(): item for item in files}
    for name in exact_names:
        if name in by_name:
            return by_name[name]

    scored = []
    for item in files:
        score = sum(hint in item.name.lower() for hint in hints)
        scored.append((score, item.name.lower(), item))
    scored.sort(key=lambda value: (-value[0], value[1]))
    return scored[0][2] if scored and scored[0][0] else None


def ask_box_ai(client, job_file, resume_file):
    response = client.ai.create_ai_ask(
        CreateAiAskMode.MULTIPLE_ITEM_QA,
        AI_PROMPT,
        [
            AiItemAsk(id=str(job_file.id), type=AiItemAskTypeField.FILE),
            AiItemAsk(id=str(resume_file.id), type=AiItemAskTypeField.FILE),
        ],
        include_citations=True,
    )
    if response is None:
        raise RuntimeError("Box AI returned no response")
    return response.to_dict()


def render_report(case_name, job_file, resume_file, answer):
    lines = [
        f"# Box AI Candidate Review: {case_name.replace('-', ' ').title()}",
        "",
        f"Generated: `{datetime.now(timezone.utc).isoformat()}`",
        "",
        "## Box AI answer",
        "",
        answer.get("answer", "Box AI returned no answer."),
        "",
        "## Source files",
        "",
        f"- Job offering: `{job_file.name}` (Box file ID `{job_file.id}`)",
        f"- Candidate resume: `{resume_file.name}` (Box file ID `{resume_file.id}`)",
        "",
        "## Box AI citations",
        "",
    ]
    citations = answer.get("citations") or []
    if citations:
        for citation in citations:
            content = " ".join(str(citation.get("content", "")).split())
            if len(content) > 300:
                content = content[:297] + "..."
            lines.append(
                f"- `{citation.get('name', 'unnamed source')}` "
                f"(Box file ID `{citation.get('id', 'unknown')}`): {content}"
            )
    else:
        lines.append("- Box AI returned no citation entries for this response.")

    lines += [
        "",
        "## Human review note",
        "",
        "This is an AI-assisted, evidence-based aid for human review. It is not "
        "an automated hiring decision. Validate claims against the source "
        "documents and follow applicable employment and privacy policies.",
        "",
    ]
    return "\n".join(lines)


def review_case(client, local_case, incoming_folder):
    box_case = child_named(folder_items(client, incoming_folder.id), local_case.name, "folder")
    if box_case is None:
        raise RuntimeError(f"Box folder not found for case {local_case.name!r}")

    files = folder_items(client, box_case.id)
    job_file = choose_file(
        files,
        ("job-description.md", "job-offer.md", "job-posting.md", "job-description.txt"),
        ("job", "offer", "posting", "description", "role"),
    )
    resume_file = choose_file(
        files,
        ("candidate-cv.md", "candidate-resume.md", "cv.md", "resume.md"),
        ("cv", "resume", "candidate"),
    )
    if job_file is None or resume_file is None:
        names = ", ".join(item.name for item in files) or "(none)"
        raise RuntimeError(f"Case {local_case.name!r} needs job-offer.md and candidate-cv.md; found {names}")

    answer = ask_box_ai(client, job_file, resume_file)
    output = REVIEWED / f"{local_case.name}-candidate-review.md"
    output.write_text(render_report(local_case.name, job_file, resume_file, answer), encoding="utf-8")
    return {
        "case": local_case.name,
        "job_file_id": str(job_file.id),
        "resume_file_id": str(resume_file.id),
        "report": str(output),
    }


def main():
    if not INCOMING.exists():
        raise RuntimeError(f"Missing Box input directory: {INCOMING}")
    REVIEWED.mkdir(parents=True, exist_ok=True)
    WORKSPACE.mkdir(parents=True, exist_ok=True)

    client = box_client()
    incoming_folder = child_named(folder_items(client, BOX_ROOT_FOLDER_ID), "Incoming", "folder")
    if incoming_folder is None:
        raise RuntimeError(f"Box folder named Incoming not found under {BOX_ROOT_FOLDER_ID}")

    case_dirs = sorted(path for path in INCOMING.iterdir() if path.is_dir())
    if not case_dirs:
        raise RuntimeError(f"No case folders found under {INCOMING}")

    results = []
    for index, case_dir in enumerate(case_dirs):
        if index:
            time.sleep(2)
        result = review_case(client, case_dir, incoming_folder)
        results.append(result)
        print(f"{result['case']}: wrote {result['report']}", flush=True)

    (WORKSPACE / "checkpoint.json").write_text(
        json.dumps({"cases": results}, indent=2), encoding="utf-8"
    )


if __name__ == "__main__":
    main()

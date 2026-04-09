# RAG Evaluation Results

The RAG pipeline is evaluated using an automated LLM-as-judge approach:
- **Answering model**: Claude Sonnet (via Bedrock cross-region inference profile)
- **Judge model**: Claude Opus (separate, stronger model to avoid self-evaluation bias)
- **Evaluation Lambda**: `rag_evaluation` — uploads the eval document, polls until indexed, runs each question through the RAG pipeline, then scores each answer on faithfulness, correctness, and out-of-scope handling

Each answer is scored 1–5 on three dimensions:
- **Faithfulness**: Is the answer grounded in the retrieved context, or hallucinated?
- **Correctness**: Does it match the expected answer?
- **Handles unknown**: When the answer is not in the document, does the system correctly say so?

---

## Round 1 — UDHR (Universal Declaration of Human Rights)

**Document**: Universal Declaration of Human Rights  
**Dataset**: `datasets/udhr_golden_dataset.json` — 41 questions (factual, conceptual, out-of-scope)

| Metric              | Score    |
|---------------------|----------|
| avg_faithfulness    | 4.98 / 5 |
| avg_correctness     | 4.98 / 5 |
| avg_handles_unknown | 4.98 / 5 |
| total_questions     | 41       |

### Observations

Scores of 4.98/5 across all dimensions indicate the benchmark was **too easy**, not that the RAG system is near-perfect:

- The UDHR is a short, clean, well-structured document with simple prose — ideal for naive chunking
- Out-of-scope questions were too obviously outside the domain (no plausible-but-wrong traps)
- No multi-hop reasoning required, no tables, no cross-referencing between sections
- The near-perfect scores mask real weaknesses in chunking and retrieval that would surface on a harder document

**Conclusion**: dataset not challenging enough to surface real weaknesses. Moved to RFC 7519.

---

## Round 2 — RFC 7519 (JSON Web Token Specification)

**Document**: RFC 7519 — JSON Web Token (JWT), May 2015  
**Dataset**: `datasets/rfc7519_golden_dataset.json` — 57 questions across 6 types:
- `factual` — direct lookup questions
- `conceptual` — require understanding, not just retrieval
- `out_of_scope` — topics not covered by the RFC
- `validation_edge_case` — boundary conditions on claim processing rules
- `cross_claim_reasoning` — require combining information from multiple sections

| Metric              | Score    |
|---------------------|----------|
| avg_faithfulness    | 4.98 / 5 |
| avg_correctness     | 4.49 / 5 |
| avg_handles_unknown | 4.93 / 5 |
| total_questions     | 57       |

### Observations

**What's working well**
- Faithfulness remains near-perfect — the model is not hallucinating; when it can't find the answer it correctly says so
- Out-of-scope handling is strong — the system refuses to answer questions outside the document
- Edge cases and cross-claim reasoning scored very high — the harder question types work well once chunks are retrieved

**Where the RAG is failing — pure retrieval misses**

All low correctness scores (1/5) follow the same pattern: the answer *exists in the document* but the wrong chunks were retrieved. The model answers faithfully from what it received, but the relevant chunk was never returned:

| Question                                                      | Correctness | Root cause                                           |
|---------------------------------------------------------------|-------------|------------------------------------------------------|
| How is a JWT pronounced? ("jot")                              | 1/5         | Section 1 introductory chunk not retrieved           |
| What should happen if a processor doesn't understand a claim? | 1/5         | Section 4 preamble chunk missed                      |
| What must happen with duplicate claim names?                  | 1/5         | Section 4 preamble chunk missed                      |
| How is a StringOrURI value compared?                          | 2/5         | Section 2 definitions chunk missed                   |
| `iss` value with colon must be a URI                          | 1/5         | Section 2 definitions chunk missed                   |
| JOSE Header with unsupported semantics must be rejected       | 2/5         | Implication not stated explicitly in retrieved chunk |

**Root cause**: these failures all come from *introductory and definitional sections* (abstract, sections 1, 2, 4 preamble) — short, dense chunks that get outscored by longer, more verbose chunks during cosine similarity search.

### What to try next

- Reduce chunk size or increase overlap specifically for early sections
- Increase `MAX_SEARCH_RESULTS` beyond current default (5) to retrieve more candidates
- Add a lexical/BM25 search pass alongside vector search for exact-match terms like "jot" or "StringOrURI"
- Re-evaluate with a retrieval Hit Rate metric in isolation (independent of generation quality)
- Human review of outputs — current evaluation is fully automated via LLM judge, which is insufficient on its own
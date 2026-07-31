# AI Systems Standard

AI-dependent capabilities must include:
- an explicit task and risk classification;
- provider/model abstraction where feasible;
- versioned prompts, tools, schemas, datasets, and evaluation sets;
- structured outputs and schema validation;
- bounded tool permissions and human approval for consequential actions;
- protection against prompt injection, data exfiltration, confused-deputy behaviour, and excessive agency;
- offline and production evaluation with defined failure metrics;
- latency, cost, quality, safety, and drift monitoring;
- deterministic fallback or safe refusal where reliability is insufficient;
- provenance for model, data, configuration, and generated decisions.

Do not label an AI feature autonomous, safe, accurate, or production-ready without measured evidence and declared operating bounds.

# Receiving Feedback

---

## Core Mindset

> "Verify before implementing. Ask before assuming. Technical correctness over social comfort."

Code review feedback is a technical discussion, not a social one. Focus on the code, not on feelings.

---

## The Six-Step Process

### Step 1: Read Completely

**Without reacting.** Read the entire comment before forming any response.

### Step 2: Restate Requirements

Rephrase the reviewer's feedback in your own words to confirm understanding.

### Step 3: Check Against Codebase

Verify the feedback against actual code conditions before responding.

### Step 4: Evaluate Technical Soundness

Consider whether the feedback applies to your specific stack and context.

### Step 5: Respond with Substance

Provide technical acknowledgment or reasoned objection.

### Step 6: Implement One at a Time

Address each piece of feedback individually with verification.

---

## Avoiding Agreement Theater

### The Problem

Performative agreement wastes time and provides no information. When you write "Great point!" you're adding noise, not signal.

### Forbidden Phrases

| Phrase | Why It's Wrong |
|--------|----------------|
| "You're absolutely right!" | Sycophantic, adds no information |
| "Great point!" | Empty praise, not a response |
| "Excellent feedback!" | Flattery, not engagement |
| "Thanks for catching this!" | Unnecessary, just fix it |
| "I really appreciate..." | Social fluff, not technical |

### Actions Demonstrate Understanding

```markdown
❌ "You're absolutely right! Great catch on that null check!
    Thanks so much for pointing this out!"

✅ "Fixed. Added null check at line 42."
```

The code change shows you understood. Words are redundant.

### When Acknowledgment IS Appropriate

Brief, technical acknowledgment when learning something new:

```markdown
✅ "I wasn't aware of that edge case. Added handling at line 42."
✅ "Good point about thread safety. Added mutex at line 67."
```

---

## When to Push Back

### Valid Reasons to Disagree

Push back with technical reasoning when feedback:

| Situation | How to Respond |
|-----------|----------------|
| Breaks existing functionality | "This change would break Feature X (see test at tests/feature-x.spec.ts:34)" |
| Lacks full codebase context | "This pattern exists because of Y (see architecture.md#constraints)" |
| Violates YAGNI | "This flexibility isn't needed yet - only one caller exists" |
| Is technically incorrect | "This works because of Z (link to docs)" |
| Conflicts with established architecture | "This conflicts with our JWT approach (see auth/README.md)" |

### Good Pushback Format

```markdown
## Template
This conflicts with [X]. [Evidence]. Was that the intent, or should we [alternative]?

## Example
This conflicts with our JWT authentication architecture (see auth/token.js:45).
Switching to sessions would require restructuring the API middleware.
Was that the intent, or should we keep JWT?
```

---

## Verification Before Claiming Fixed

### The Checklist

Before writing "Fixed" or "Done":

- [ ] Change is implemented
- [ ] Tests pass (full suite, not just changed files)
- [ ] Specific behavior mentioned in feedback is verified
- [ ] Edge cases are tested
- [ ] No unintended side effects introduced

### Acceptable Responses

```markdown
✅ "Fixed. Added null check. Tests pass."
✅ "Fixed at line 42. Verified with test case X."
✅ "Implemented. All 47 tests pass."
```

---

## Quick Reference

| Situation | Response |
|-----------|----------|
| Reviewer is correct | "Fixed. [What you changed]." |
| You need clarification | "To confirm: you're suggesting [restatement]?" |
| Reviewer is incorrect | "This works because [evidence]. [Link to proof]." |
| You disagree on approach | "This conflicts with [X]. Should we [alternative]?" |
| You learned something | "I wasn't aware of [X]. Fixed at line [N]." |
| You can't verify | "Implemented. Unable to verify because [reason]." |

---

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Defensive responses | Creates conflict, wastes time | Assume good faith, respond technically |
| Apologetic responses | Unprofessional, adds noise | Just fix it |
| Delayed responses | Blocks review cycle | Respond within hours, not days |
| Vague responses | Leaves reviewer uncertain | Be specific about changes |
| Ignoring feedback | Disrespectful, creates friction | Address every point |

---

*Content adapted from obra/superpowers by Jesse Vincent (@obra), MIT License.*

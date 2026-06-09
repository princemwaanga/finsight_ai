# CSV parsing, Phi-4 Mini categorisation, and embedding generation.

import pandas as pd
import os
import logging
from io import BytesIO
from sentence_transformers import SentenceTransformer
from ai_engine import build_prompt, generate_safe

logger = logging.getLogger("finsight.finance")
_embedder = None

# All valid categories Phi-4 Mini can assign
CATEGORIES = [
    "Food & Groceries", "Transport", "Entertainment", "Utilities",
    "Shopping", "Healthcare", "Education", "Income", "Rent & Housing", "Other",
]
CATEGORY_STR = ", ".join(CATEGORIES)

def get_embedder() -> SentenceTransformer:
    """Load the 80 MB embedding model once, reuse on every call."""
    global _embedder
    if _embedder is None:
        logger.info("Loading sentence-transformer embedder...")
        os.environ["TRANSFORMERS_OFFLINE"] = "1"
        os.environ["HF_DATASETS_OFFLINE"] = "1"
        _embedder = SentenceTransformer("all-MiniLM-L6-v2")
        logger.info("Embedder ready.")
    return _embedder


# - CSV Parsing ───────────────────────────────────────────────────────────────
def parse_csv(file_bytes: bytes, account_name: str = "My Account") -> pd.DataFrame:
    """
    Parse a bank statement CSV into a normalised DataFrame.

    Handles three common CSV formats:
      Format A: Date, Description, Amount, Balance
      Format B: Date, Description, Debit, Credit, Balance
      Format C: Transaction Date, Transaction Details, Debit Amount, Credit Amount
    """
    df = pd.read_csv(BytesIO(file_bytes), skipinitialspace=True)
    # Normalise column names: lowercase, underscores
    df.columns = [c.strip().lower().replace(" ", "_") for c in df.columns]

    # ── Date ──────────────────────────────────────────────────────────────
    date_col = next((c for c in df.columns if "date" in c), None)
    if not date_col:
        raise ValueError(
            "No date column found. "
            "Expected a column with 'date' in its name"
        )
    df["date"] = pd.to_datetime(df[date_col],
    dayfirst = True, errors="coerce")
    df = df.dropna(subset=["date"])

    # ── Description ───────────────────────────────────────────────────────
    desc_col = next(
        (c for c in df.columns if any (
            k in c for k in 
            ["description", "details", "narration","particulars","reference"]
        )), None
    )
    if not desc_col:
        raise ValueError(
            "No description column found."
            "Expected a column named 'description', 'details', or 'narration'."
        )
    df["description"] = df[desc_col].astype(str).str.strip()

    # ── Amount: single column or split debit/credit ────────────────────
    def clean_num(val):
        if pd.isna(val): return 0.0
        cleaned = str(val).replace(",", "").replace("(", "-").replace(")", "").strip()
        try:
            return float(cleaned or 0)
        except ValueError:
            return 0.0
    
    if "amount" in df.columns:
        df["amount"] = df["amount"].apply(clean_num)
    elif any("debit" in c for c in df.columns):
        d_col = next(c for c in df.columns if "debit" in c)
        c_col = next((c for c in df.columns if "credit" in c), None)
        debits  = df[d_col].apply(clean_num)
        credits = df[c_col].apply(clean_num) if c_col else pd.Series(0.0, index=df.index)
        df["amount"] = credits - debits   # positive=income, negative=expense
    else:
        raise ValueError(
            "Cannot find amount column(s). "
            "Expected 'amount' or 'debit'/'credit' columns."
        )
    
     # ── Balance (optional) ────────────────────────────────────────────────
    b_col      = next((c for c in df.columns if "balance" in c), None)
    df["balance"]      = df[b_col].apply(clean_num) if b_col else 0.0
    df["account_name"] = account_name

    return df[["date","description","amount","balance","account_name"]].copy()

# ── AI Categorisation ─────────────────────────────────────────────────────────

SYSTEM_CAT = f"""You are a bank transaction categoriser.
Given a transaction description and amount, return ONLY one category from this list:
{CATEGORY_STR}

Rules:
- Salary, wages, transfers in, deposits → Income
- Supermarkets, food shops, groceries → Food & Groceries
- Fuel, taxi, bus, Uber, toll, parking → Transport
- Electricity, water, internet, airtime, subscriptions → Utilities
- Rent, mortgage, landlord payments → Rent & Housing
- Hospital, pharmacy, clinic, doctor → Healthcare
- School, university, tuition, fees, books → Education
- Restaurants, bars, cinema, streaming, concerts → Entertainment
- Online shops, clothing, electronics stores → Shopping
- Anything else → Other

Return ONLY the category name. No explanation. No punctuation after it."""

def categorise_transaction(description: str, amount: float) -> str:
    """Ask Phi-4 Mini to a categories a single transaction. Returns a valid category."""
    direction = "income" if amount > 0 else "expense"
    prompt    = build_prompt(
        SYSTEM_CAT,
        f"Transaction: {description} | Amount: {amount: .2f}({direction})"
    )
    raw = generate_safe(prompt, max_tokens=12, temperature=0.0)
    # Validate the returned category against our known list
    for cat in CATEGORIES:
        if cat.lower() in raw.lower():
            return cat
    return "Other"  # safe default

def categorise_batch(df: pd.DataFrame) -> pd.DataFrame:
    """Categorise all transactions. Logs progress every 10 rows."""
    cats, total = [], len(df)
    for i, (_, row) in enumerate(df.iterrows()):
        cats.append(categorise_transaction(row["description"], float(row["amount"])))
        if (i + 1) % 10 == 0:
            logger.info(f"  Categorised {i+1}/{total} transactions")
    df["category"] = cats
    return df

# ── Embedding ─────────────────────────────────────────────────────────────────
def embed_transactions(df: pd.DataFrame) -> pd.DataFrame:
    """
    Generate a 384-dim embedding for each transaction.
    Embeds: description + category + income/expense direction.
    Enables semantic search: 'find transactions related to school'.
    """
    texts = [
        f"{row['description']}{row.get('category', 'Other')} "
        f"{'income' if float(row['amount']) > 0 else 'expense'}"
        for _, row in df.iterrows()
    ]
    vecs = get_embedder().encode(texts, normalize_embeddings=True, batch_size=32)
    df["embedding"] = list(vecs)
    return df
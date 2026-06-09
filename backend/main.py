from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import text, extract
from datetime import date, datetime
import models, database, ai_engine, finance_processor as fp
import logging, json, re

from pydantic import BaseModel
from typing  import Optional
from datetime import date as DateType

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(name)s  %(levelname)s  %(message)s"
)
logger = logging.getLogger("finsight.main")

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="FinSight AI", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

# ── Schema context for text-to-SQL ───────────────────────────────────────────
# This is embedded into every SQL-generation prompt so Phi-4 Mini
# knows exactly which columns and categories exist.

SQL_SCHEMA = """
Table: transactions
  date         DATE      Transaction date
  description  TEXT      Bank statement description
  amount       NUMERIC   Negative = expense, Positive = income
  balance      NUMERIC   Running account balance
  category     TEXT      One of: 'Food & Groceries', 'Transport', 'Entertainment',
                          'Utilities', 'Shopping', 'Healthcare', 'Education',
                          'Income', 'Rent & Housing', 'Other'
  account_name TEXT      Name of the bank account

Today's date: {today}

Rules:
- Use ABS(amount) when displaying expense amounts (makes them positive)
- For "last month": DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
- For "this month": DATE_TRUNC('month', CURRENT_DATE)
- For totals: ROUND(SUM(ABS(amount))::NUMERIC, 2)
- Always add LIMIT 50 unless the question specifies a number
- SELECT queries only
"""

SYSTEM_SQL = """You are a PostgreSQL expert for a personal finance application.
Convert the natural language question into a single SQL SELECT query.

Schema:
{schema}

Return ONLY the raw SQL query — no markdown backticks, no explanation, no semicolon.
If the question cannot be answered with SQL (e.g. advice questions), return: NOT_SQL"""

SYSTEM_EXPLAIN = """You are FinSight, a friendly personal finance assistant.
A database query was executed to answer the question. Explain the result clearly:
- Mention the actual numbers from the data
- Keep it to 2-3 sentences
- Suggest one practical financial tip if relevant
- Be encouraging and conversational"""

SYSTEM_CHAT = """You are FinSight, a helpful personal finance AI assistant.
Answer the question based on the provided spending context.
Be concise, friendly, and give one practical suggestion."""

# Guard against dangerous SQL
FORBIDDEN_SQL = re.compile(
    r"\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE|GRANT|REVOKE)\b",
    re.IGNORECASE
)


class ChatRequest(BaseModel):
    message:         str
    conversation_id: int | None = None


def run_sql_safe(sql: str, db: Session) -> list[dict]:
    """Execute a read-only SQL query. Raises ValueError on any write attempt."""
    if FORBIDDEN_SQL.search(sql):
        raise ValueError("Only SELECT queries are permitted.")
    rows = db.execute(text(sql)).fetchall()
    return [dict(zip(row._fields, row)) for row in rows]


# ── Health check ──────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok", "app": "FinSight AI"}


# ── Upload bank statement CSV ─────────────────────────────────────────────────

@app.post("/statements/upload")
async def upload_statement(
    file:         UploadFile = File(...),
    account_name: str        = Query(default="My Account"),
    db:           Session    = Depends(database.get_db),
):
    """
    Full pipeline on upload:
    1. Parse CSV → normalised DataFrame
    2. Phi-4 Mini categorises each row (temperature=0.0 for determinism)
    3. all-MiniLM-L6-v2 embeds each row for semantic search
    4. Store statement + transactions in PostgreSQL
    """
    raw = await file.read()
    try:
        df = fp.parse_csv(raw, account_name=account_name)
    except ValueError as exc:
        raise HTTPException(422, f"CSV parse error: {exc}")

    logger.info(f"Parsed {len(df)} rows from {file.filename}")
    df = fp.categorise_batch(df)
    df = fp.embed_transactions(df)

    stmt = models.Statement(
        filename=file.filename, account_name=account_name, row_count=len(df)
    )
    db.add(stmt)
    db.flush()   # get stmt.id without committing

    for _, row in df.iterrows():
        db.add(models.Transaction(
            statement_id = stmt.id,
            date         = row["date"].date(),
            description  = row["description"],
            amount       = float(row["amount"]),
            balance      = float(row["balance"]),
            category     = row["category"],
            account_name = account_name,
            embedding    = row["embedding"].tolist(),
        ))

    db.commit()
    breakdown = df.groupby("category")["amount"].count().to_dict()
    logger.info(f"Committed {len(df)} transactions (statement id={stmt.id})")

    return {
        "statement_id":         stmt.id,
        "filename":             file.filename,
        "transactions_imported": len(df),
        "category_breakdown":   breakdown,
    }


# ── List transactions ─────────────────────────────────────────────────────────

@app.get("/transactions")
def list_transactions(
    category: str | None = None,
    month:    str | None = None,    # YYYY-MM format
    limit:    int        = 100,
    offset:   int        = 0,
    db:       Session    = Depends(database.get_db),
):
    q = db.query(models.Transaction).order_by(models.Transaction.date.desc())
    if category:
        q = q.filter(models.Transaction.category == category)
    if month:
        try:
            y, m = month.split("-")
            q = q.filter(
                extract("year",  models.Transaction.date) == int(y),
                extract("month", models.Transaction.date) == int(m),
            )
        except ValueError:
            raise HTTPException(422, "month must be YYYY-MM format")

    total = q.count()
    txs   = q.offset(offset).limit(limit).all()
    return {
        "total": total,
        "transactions": [
            {
                "id":          t.id,
                "date":        t.date.isoformat(),
                "description": t.description,
                "amount":      float(t.amount),
                "category":    t.category,
                "balance":     float(t.balance or 0),
            }
            for t in txs
        ],
    }


# ── Spending summary ──────────────────────────────────────────────────────────

@app.get("/transactions/summary")
def spending_summary(
    month: str | None = None,
    db:    Session    = Depends(database.get_db),
):
    q = db.query(models.Transaction)
    if month:
        try:
            y, m = month.split("-")
            q = q.filter(
                extract("year",  models.Transaction.date) == int(y),
                extract("month", models.Transaction.date) == int(m),
            )
        except ValueError:
            raise HTTPException(422, "month must be YYYY-MM")

    txs = q.all()
    if not txs:
        return {
            "total_income": 0, "total_expenses": 0, "net": 0,
            "spending_by_category": {}, "top_expenses": [],
        }

    income   = sum(float(t.amount) for t in txs if float(t.amount) > 0)
    expenses = sum(float(t.amount) for t in txs if float(t.amount) < 0)

    by_cat: dict[str, float] = {}
    for t in txs:
        if float(t.amount) < 0:
            by_cat[t.category] = by_cat.get(t.category, 0) + abs(float(t.amount))

    top5 = sorted(
        [t for t in txs if float(t.amount) < 0],
        key=lambda t: float(t.amount)
    )[:5]

    return {
        "total_income":    round(income, 2),
        "total_expenses":  round(abs(expenses), 2),
        "net":             round(income + expenses, 2),
        "spending_by_category": {
            k: round(v, 2)
            for k, v in sorted(by_cat.items(), key=lambda x: -x[1])
        },
        "top_expenses": [
            {
                "id":          t.id,           # ← add this line
                "date":        t.date.isoformat(),
                "description": t.description,
                "amount":      float(t.amount),
                "category":    t.category,
            }
            for t in top5
        ],
    }


# ── Available months ──────────────────────────────────────────────────────────

@app.get("/transactions/months")
def available_months(db: Session = Depends(database.get_db)):
    rows = db.execute(text(
        "SELECT DISTINCT TO_CHAR(date, 'YYYY-MM') AS month "
        "FROM transactions ORDER BY month DESC LIMIT 24"
    )).fetchall()
    return [r.month for r in rows]


# ── Natural language chat with text-to-SQL ────────────────────────────────────

@app.post("/chat")
def chat(req: ChatRequest, db: Session = Depends(database.get_db)):
    """
    Two-stage AI pipeline:

    Stage 1 — Text-to-SQL (temperature=0.0):
      Phi-4 Mini reads the schema and converts the question to PostgreSQL.
      We execute it safely (SELECT only).

    Stage 2 — Explanation (temperature=0.2):
      Phi-4 Mini reads the query result and writes a plain-English answer
      with a financial tip.

    Fallback: if Stage 1 returns NOT_SQL (e.g. advice questions),
      we inject 30-day spending context and answer conversationally.
    """
    # Get or create conversation
    if req.conversation_id:
        conv = db.get(models.Conversation, req.conversation_id)
        if not conv:
            raise HTTPException(404, "Conversation not found")
    else:
        conv = models.Conversation(title=req.message[:60])
        db.add(conv)
        db.flush()

    today      = date.today().isoformat()
    sql_system = SYSTEM_SQL.format(schema=SQL_SCHEMA.format(today=today))
    sql_prompt = ai_engine.build_prompt(sql_system, req.message)
    gen_sql    = ai_engine.generate_safe(sql_prompt, max_tokens=2000, temperature=0.0)
    gen_sql    = gen_sql.strip().rstrip(";")

    sql_used   = None
    sql_result = None
    response   = ""

    if gen_sql.upper().startswith("SELECT"):
        # Stage 1 succeeded — run the SQL
        try:
            rows       = run_sql_safe(gen_sql, db)
            sql_used   = gen_sql
            sql_result = rows
            result_str = json.dumps(rows, default=str)[:1500]
            if not rows:
                result_str = "No transactions matched that query."

            explain_prompt = ai_engine.build_prompt(
                SYSTEM_EXPLAIN,
                f"Question: {req.message}\n\nQuery result: {result_str}"
            )
            response = ai_engine.generate_safe(
                explain_prompt, max_tokens=300, temperature=0.2
            )
        except Exception as exc:
            logger.error(f"SQL execution error: {exc}")
            # Fall through to conversational answer
            response = ai_engine.generate_safe(
                ai_engine.build_prompt(SYSTEM_CHAT, req.message),
                max_tokens=300, temperature=0.3
            )
    else:
        # NOT_SQL — conversational answer with recent spending context
        ctx_rows = db.execute(text("""
            SELECT category, ROUND(SUM(ABS(amount))::NUMERIC, 2) AS total
            FROM transactions WHERE amount < 0
              AND date >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY category ORDER BY total DESC LIMIT 8
        """)).fetchall()
        context = (
            "Recent 30-day spending by category: " +
            ", ".join(f"{r.category}: {r.total}" for r in ctx_rows)
        ) if ctx_rows else "No transaction data available yet."

        response = ai_engine.generate_safe(
            ai_engine.build_prompt(
                SYSTEM_CHAT + f"\n\nContext: {context}", req.message
            ),
            max_tokens=400, temperature=0.3
        )

    # Persist messages
    db.add(models.Message(
        conversation_id=conv.id, role="user", content=req.message
    ))
    db.add(models.Message(
        conversation_id=conv.id, role="assistant",
        content=response, sql_used=sql_used
    ))
    db.commit()

    return {
        "conversation_id": conv.id,
        "response":        response,
        "sql_used":        sql_used,
        "sql_result":      sql_result,
    }


# ── Generate monthly AI insights report ───────────────────────────────────────

@app.post("/insights/generate")
def generate_insights(
    month: str | None = None,
    db:    Session    = Depends(database.get_db),
):
    """
    Generate a full monthly financial insights report using Phi-4 Mini.
    Reports are cached in the insights table — regenerate by deleting the row.
    """
    if not month:
        month = datetime.now().strftime("%Y-%m")

    # Return cached report if it exists
    cached = db.query(models.Insight).filter_by(period=month).first()
    if cached:
        return {"period": month, "content": cached.content, "cached": True}

    y, m = month.split("-")
    expense_rows = db.execute(text("""
        SELECT category,
               COUNT(*) AS tx_count,
               ROUND(SUM(ABS(amount))::NUMERIC, 2) AS total_spent,
               ROUND(AVG(ABS(amount))::NUMERIC, 2) AS avg_tx
        FROM transactions
        WHERE amount < 0
          AND EXTRACT(year  FROM date) = :y
          AND EXTRACT(month FROM date) = :m
        GROUP BY category ORDER BY total_spent DESC
    """), {"y": int(y), "m": int(m)}).fetchall()

    if not expense_rows:
        raise HTTPException(404, f"No transaction data found for {month}")

    income_row = db.execute(text("""
        SELECT ROUND(SUM(amount)::NUMERIC, 2) AS total_income
        FROM transactions WHERE amount > 0
          AND EXTRACT(year  FROM date) = :y
          AND EXTRACT(month FROM date) = :m
    """), {"y": int(y), "m": int(m)}).fetchone()

    total_income   = float(income_row.total_income or 0)
    total_expenses = sum(float(r.total_spent) for r in expense_rows)
    savings        = total_income - total_expenses

    breakdown = "\n".join(
        f"  - {r.category}: {r.total_spent} "
        f"({r.tx_count} transactions, avg {r.avg_tx} each)"
        for r in expense_rows
    )

    data_summary = (
        f"Monthly Financial Data — {month}\n"
        f"Income:        {total_income:.2f}\n"
        f"Total Expenses:{total_expenses:.2f}\n"
        f"Net Savings:   {savings:.2f}\n\n"
        f"Spending by Category:\n{breakdown}"
    )

    system = """You are FinSight, a personal finance analyst.
Write a clear, helpful monthly financial insights report using the data below.
Structure it with these four sections (use markdown headers):

1. **Monthly Overview** — one-paragraph summary of income, expenses, and savings
2. **Spending Breakdown** — commentary on the top 3 spending categories
3. **Key Observations** — 2-3 notable patterns, concerns, or positive trends
4. **Action Plan** — 3 specific, practical suggestions for improvement next month

Use markdown formatting. Be encouraging and honest. Keep it under 450 words."""

    report = ai_engine.generate_safe(
        ai_engine.build_prompt(system, data_summary),
        max_tokens=650, temperature=0.3
    )

    db.add(models.Insight(period=month, content=report))
    db.commit()

    return {"period": month, "content": report, "cached": False}


# ---------------------- Manual -----------------

class TransactionCreate(BaseModel):
    description:  str
    amount:       float         # negative = expense, positive = income
    category:     str  = "Other"
    date:         str           # YYYY-MM-DD string
    balance:      float = 0.0
    account_name: str  = "Manual Entry"

class TransactionUpdate(BaseModel):
    description:  Optional[str]   = None
    amount:       Optional[float] = None
    category:     Optional[str]   = None
    date:         Optional[str]   = None
    balance:      Optional[float] = None


@app.post("/transactions/manual")
def add_transaction_manual(
    payload: TransactionCreate,
    db: Session = Depends(database.get_db),
):
    """
    Manual transaction creation from the Flutter UI.
    The AI /chat endpoint cannot reach this route.
    Embedding is omitted — manually entered rows will not appear in
    semantic vector search but will appear in all SQL aggregations.
    """
    tx = models.Transaction(
        description  = payload.description,
        amount       = payload.amount,
        category     = payload.category,
        date         = DateType.fromisoformat(payload.date),
        balance      = payload.balance,
        account_name = payload.account_name,
        statement_id = None,
        embedding    = None,
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return {
        "id":          tx.id,
        "description": tx.description,
        "amount":      float(tx.amount),
        "category":    tx.category,
        "date":        tx.date.isoformat(),
        "balance":     float(tx.balance or 0),
    }


@app.put("/transactions/{tx_id}")
def update_transaction(
    tx_id:   int,
    payload: TransactionUpdate,
    db: Session = Depends(database.get_db),
):
    """
    Edit any field on a transaction.
    AI /chat endpoint cannot reach this route.
    """
    tx = db.get(models.Transaction, tx_id)
    if not tx:
        raise HTTPException(404, "Transaction not found")

    if payload.description is not None:
        tx.description = payload.description
    if payload.amount is not None:
        tx.amount = payload.amount
    if payload.category is not None:
        tx.category = payload.category
    if payload.date is not None:
        tx.date = DateType.fromisoformat(payload.date)
    if payload.balance is not None:
        tx.balance = payload.balance

    db.commit()
    db.refresh(tx)
    return {
        "id":          tx.id,
        "description": tx.description,
        "amount":      float(tx.amount),
        "category":    tx.category,
        "date":        tx.date.isoformat(),
        "balance":     float(tx.balance or 0),
    }


@app.delete("/transactions/{tx_id}")
def delete_transaction(
    tx_id: int,
    db: Session = Depends(database.get_db),
):
    """
    Delete a transaction.
    AI /chat endpoint cannot reach this route.
    """
    tx = db.get(models.Transaction, tx_id)
    if not tx:
        raise HTTPException(404, "Transaction not found")
    db.delete(tx)
    db.commit()
    return {"deleted": tx_id}
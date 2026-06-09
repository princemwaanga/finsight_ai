from sqlalchemy import Column, Integer, String, Text, Numeric, Date
from sqlalchemy import DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from pgvector.sqlalchemy import Vector
from database import Base

class Statement(Base):
    __tablename__ = "statements"
    id            = Column(Integer, primary_key=True, index= True)
    filename      = Column(String, nullable=False)
    account_name  = Column(String)
    row_count     = Column(Integer)
    uploaded_at   = Column(DateTime(timezone=True), server_default=func.now())
    transactions = relationship("Transaction", back_populates="statement", cascade="all, delete-orphan")

class Transaction(Base):
    __tablename__ = "transactions"
    id            = Column(Integer, primary_key=True, index= True)
    statement_id  = Column(Integer, ForeignKey("statements.id"))
    date          = Column(Date, nullable=False)
    description    = Column(Text, nullable=False)
    amount         = Column(Numeric(12, 2), nullable=False)
    balance        = Column(Numeric(12, 2))
    category       = Column(String, default="Other")
    account_name   = Column(String)
    embedding      = Column(Vector(384)) # 384-dim float vector
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    statement      = relationship("Statement", back_populates="transactions")

class Conversation(Base):
    __tablename__ = "conversations"
    id            = Column(Integer, primary_key=True, index= True)
    title         = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    messages   = relationship("Message", back_populates="conversation",cascade="all, delete-orphan")

class Message(Base):
    __tablename__ = "messages"
    id              = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"))
    role            = Column(String(10), nullable=False)
    content         = Column(Text, nullable=False)
    sql_used        = Column(Text)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    conversation    = relationship("Conversation", back_populates="messages")
    __table_args__  = (
        CheckConstraint("role IN ('user','assistant')", name="role_check"),
    )

class Insight(Base):
    __tablename__ = "insights"
    id         = Column(Integer, primary_key=True, index=True)
    period     = Column(String, nullable=False, unique=True)
    content    = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
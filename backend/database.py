from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://DB_YOUR_NAME:DB_PASSWORD@localhost:5432/finsight_db"
)

engine = create_engine(DATABASE_URL, pool_pre_ping= True, pool_size= 5)
SessionLocal = sessionmaker(autocommit= False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    """FastAPI dependency - yields  DB session and always closes it."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
